-- 拖拽上下文（一个拖拽域一个，挂在目标侧或两侧公共面板）：
-- 登记落点、克隆体跟手、落点检测、长按进度条、派发 Drop。
-- 落点默认 Rect（每帧遍历已登记区域）；也支持 Enter（外部 grid 事件回灌）。
-- 约束：克隆体挂在 panelRoot 下，panelRoot 的 pivot 建议 (0.5,0.5)，否则克隆体会偏移。
---@class XUiCommonDragContext
local XUiCommonDragContext = XClass(nil, "XUiCommonDragContext")

local XUiCommonDragInput = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragInput")
local Vector2 = CS.UnityEngine.Vector2
local RectTransformUtility = CS.UnityEngine.RectTransformUtility

---@class XUiCommonDragContextConfig
---@field HitTest number 默认 Rect
---@field ProgressUi UnityEngine.GameObject 长按进度条预制体实例（不传则无进度条），可空
---@field ProgressOrder number 进度条 Canvas 排序层级，可空
---@field ProgressShowTime number 长按进度阶段时长（秒），可空

---@param ownerUi XUiNode|XLuaUi 宿主节点（进度条等子节点的 parent，须是 XUiNode/XLuaUi）
---@param panelRoot UnityEngine.RectTransform 克隆体挂载与定位参考（pivot 建议 0.5）
---@param config XUiCommonDragContextConfig 配置项
function XUiCommonDragContext:Ctor(ownerUi, panelRoot, config)
    self._OwnerUi = ownerUi
    self._PanelRoot = panelRoot

    config = config or {}
    self._HitTest = config.HitTest or XEnumConst.CommonDrag.HitTest.Rect
    self._ProgressUi = config.ProgressUi
    self._ProgressOrder = config.ProgressOrder
    self._ProgressShowTime = config.ProgressShowTime

    self._IsDragging = false
    self._Clone = nil
    self._CloneTransform = nil
    self._Payload = nil
    self._PointerId = nil  -- 当前拖拽触点 id（鼠标恒 nil，移动端由触发拖拽的 fingerId 匹配）
    self._HoverZoneId = nil
    self._DropZones = {} -- { {rect=, id=}, ... } 有序，先注册先命中
    self._Tick = nil
    self._CloneDestroy = nil -- 本次拖拽的克隆回收函数 (cloneObj)

    self._screenVec2 = Vector2(0, 0)
    self._dragVec2 = Vector2(0, 0)
    self._hideVec2 = Vector2(-99999, -99999)
end

--region 配置 / 回调
-- 命中落点变化 cb(payload, zoneId)，payload 为拖拽业务数据(GetPayload 返回值)，zoneId 命中区域(可为 nil)
function XUiCommonDragContext:SetOnHoverChange(cb)
    self._OnHoverChange = cb
end

-- 抬手放下 cb(payload, zoneId)，zoneId 为 nil 表示落空
function XUiCommonDragContext:SetOnDrop(cb)
    self._OnDrop = cb
end

function XUiCommonDragContext:SetHitTest(mode)
    self._HitTest = mode or XEnumConst.CommonDrag.HitTest.Rect
end

function XUiCommonDragContext:IsDragging()
    return self._IsDragging
end

function XUiCommonDragContext:GetHoverZoneId()
    return self._HoverZoneId
end

-- 当前拖拽的业务数据（拖拽中有效；非拖拽态为 nil）
function XUiCommonDragContext:GetPayload()
    return self._Payload
end
--endregion

--region 落点区域（Rect 模式）
-- 仅 Rect 模式生效：拖拽中每帧用指针位置遍历这些区域判命中。
---@param rectTransform UnityEngine.RectTransform 区域的 RectTransform
---@param zoneId any 区域标识，命中后经 OnHoverChange/OnDrop 回传
function XUiCommonDragContext:AddDropZone(rectTransform, zoneId)
    table.insert(self._DropZones, { rect = rectTransform, id = zoneId })
end

-- 清空已登记的落点区域
function XUiCommonDragContext:ClearDropZones()
    self._DropZones = {}
end
--endregion

--region 落点回灌（Enter 模式）
-- 指针进入某落点时由外部调用，告知 Context 命中了 zoneId。仅 Enter 模式 + 拖拽中生效。
-- 调用方：落点格子的 PointerEnter 事件里调本方法（源即落点用 draggable:SetAsDropZone)
-- 纯落点格子直接在其 listener.OnEnter 里调）。zoneId 是“被进入的那个落点”的标识。
---@param zoneId any 被进入的落点标识
function XUiCommonDragContext:NotifyEnter(zoneId)
    if self._IsDragging and self._HitTest == XEnumConst.CommonDrag.HitTest.Enter then
        self:_SetHoverZone(zoneId)
    end
end

-- 指针离开某落点时由外部调用。
---@param zoneId any 被离开的落点标识
function XUiCommonDragContext:NotifyExit(zoneId)
    if self._IsDragging and self._HitTest == XEnumConst.CommonDrag.HitTest.Enter then
        if self._HoverZoneId == zoneId then
            self:_SetHoverZone(nil)
        end
    end
end
--endregion

--region 生命周期（由 XUiCommonDraggable 调用）
---@param payload any 业务数据，结束回传给 OnDrop
---@param cloneTransform UnityEngine.RectTransform 跟手克隆体（须已挂在 panelRoot 下）
---@param cloneObj any 克隆业务对象（回收时回传给 cloneRecycle）
---@param cloneRecycle function|nil 克隆回收函数 (cloneObj)
---@param pointerId number|nil 触发拖拽的触点 id（移动端 fingerId 匹配）
function XUiCommonDragContext:Begin(payload, cloneTransform, cloneObj, cloneRecycle, pointerId)
    if self._IsDragging then
        return
    end
    if XTool.UObjIsNil(cloneTransform) then
        XLog.Error("XUiCommonDragContext:Begin error: cloneTransform is nil")
        return
    end
    self._IsDragging = true
    self._Payload = payload
    self._CloneTransform = cloneTransform
    self._Clone = cloneObj
    self._CloneDestroy = cloneRecycle
    self._PointerId = pointerId
    self._HoverZoneId = nil
    self:_HidePressProgress()
    self:_StartTick()
end

function XUiCommonDragContext:End()
    if not self._IsDragging then
        return
    end
    local hoverZoneId = self._HoverZoneId
    local payload = self._Payload
    self:_StopTick()
    self._IsDragging = false
    self._HoverZoneId = nil
    if self._CloneDestroy then
        self._CloneDestroy(self._Clone or self._CloneTransform)
    end
    self._Clone = nil
    self._CloneTransform = nil
    self._CloneDestroy = nil
    self._PointerId = nil
    self._Payload = nil
    -- 先通知内部（如 Draggable 复位手势），再派发业务 OnDrop
    if self._AfterEnd then
        self._AfterEnd()
    end
    if self._OnDrop then
        self._OnDrop(payload, hoverZoneId)
    end
end

-- 内部结束回调（XUiCommonDraggable 用于在拖拽结束后复位手势状态）
function XUiCommonDragContext:SetAfterEnd(cb)
    self._AfterEnd = cb
end

-- 仅当当前 AfterEnd 正是传入的 cb 时才清除。
function XUiCommonDragContext:ClearAfterEnd(cb)
    if self._AfterEnd == cb then
        self._AfterEnd = nil
    end
end

-- 若当前正由 cb 对应的 Draggable 拖拽，则结束之。
function XUiCommonDragContext:EndIfDraggingBy(cb)
    if self._IsDragging and self._AfterEnd == cb then
        self:End()
    end
end
--endregion

--region 每帧追踪
function XUiCommonDragContext:_StartTick()
    self:_StopTick()
    self._TickFirstFrame = true -- 首帧只定位克隆、不做抬手判定
    self:_OnTick() -- 立即定位一次，避免首帧错位
    self._Tick = XScheduleManager.ScheduleForeverEx(function()
        self:_OnTick()
    end, 0)
end

function XUiCommonDragContext:_StopTick()
    if self._Tick then
        XScheduleManager.UnSchedule(self._Tick)
        self._Tick = nil
    end
end

function XUiCommonDragContext:_OnTick()
    if XTool.UObjIsNil(self._PanelRoot) then
        self:End()
        return
    end
    -- 抬手兜底
    if self._TickFirstFrame then
        self._TickFirstFrame = false
    elseif not XUiCommonDragInput.HasPressInput(self._PointerId) then
        self:End()
        return
    end
    local x, y = XUiCommonDragInput.GetScreenXY(self._PointerId)
    self:_RefreshClonePos(x, y)
    if self._HitTest == XEnumConst.CommonDrag.HitTest.Rect then
        self:_HitTestByRect(x, y)
    end
end

function XUiCommonDragContext:_RefreshClonePos(x, y)
    if XTool.UObjIsNil(self._CloneTransform) then
        return
    end
    if not x then
        self._CloneTransform.anchoredPosition = self._hideVec2
        return
    end
    self._screenVec2.x = x
    self._screenVec2.y = y
    local ok, point = RectTransformUtility.ScreenPointToLocalPointInRectangle(self._PanelRoot, self._screenVec2, CS.XUiManager.Instance.UiCamera)
    if ok then
        self._dragVec2.x = point.x
        self._dragVec2.y = point.y
        self._CloneTransform.anchoredPosition = self._dragVec2
    else
        self._CloneTransform.anchoredPosition = self._hideVec2
    end
end

function XUiCommonDragContext:_HitTestByRect(x, y)
    if not x then
        return
    end
    self._screenVec2.x = x
    self._screenVec2.y = y
    local uiCamera = CS.XUiManager.Instance.UiCamera
    local foundZoneId
    for i = 1, #self._DropZones do
        local zone = self._DropZones[i]
        if not XTool.UObjIsNil(zone.rect) and RectTransformUtility.RectangleContainsScreenPoint(zone.rect, self._screenVec2, uiCamera) then
            foundZoneId = zone.id
            break
        end
    end
    self:_SetHoverZone(foundZoneId)
end

function XUiCommonDragContext:_SetHoverZone(zoneId)
    if self._HoverZoneId == zoneId then
        return
    end
    self._HoverZoneId = zoneId
    if self._OnHoverChange then
        self._OnHoverChange(self._Payload, zoneId)
    end
end
--endregion

--region 长按进度条（由 XUiCommonDraggable 在进度阶段调用）
function XUiCommonDragContext:ShowPressProgress(targetTransform, anchorMode)
    if not self._ProgressUi then
        return
    end
    if not self._Progress then
        if XTool.IsTableEmpty(self._OwnerUi) then
            return
        end
        local XUiCommonDragLongPressProgress = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragLongPressProgress")
        ---@type XUiCommonDragLongPressProgress
        self._Progress = XUiCommonDragLongPressProgress.New(self._ProgressUi, self._OwnerUi, self._ProgressOrder)
    end
    if anchorMode then
        self._Progress:SetAnchorMode(anchorMode)
    end
    self._Progress:Open()
    self._Progress:Refresh(targetTransform)
end

-- 进度阶段每帧更新填充 [0,1]（手势统一时钟驱动）
function XUiCommonDragContext:UpdatePressProgress(f)
    if self._Progress then
        self._Progress:SetProgress(f)
    end
end

function XUiCommonDragContext:HidePressProgress()
    self:_HidePressProgress()
end

function XUiCommonDragContext:_HidePressProgress()
    if self._Progress then
        self._Progress:Close()
    end
end

-- 长按时长（秒）：XUiCommonDraggable 据此传给手势 ProgressDuration，故进度条与手势同一时钟
function XUiCommonDragContext:GetProgressShowTime()
    return self._ProgressShowTime
end
--endregion

function XUiCommonDragContext:Destroy()
    self:_StopTick()
    self._IsDragging = false
    if self._CloneDestroy then
        local clone = self._Clone or self._CloneTransform
        if not XTool.UObjIsNil(clone) then
            self._CloneDestroy(clone)
        end
    end
    self._Clone = nil
    self._CloneTransform = nil
    self._CloneDestroy = nil
    self._DropZones = nil
    self._PanelRoot = nil
    self._OwnerUi = nil
    self._Payload = nil
    self._OnHoverChange = nil
    self._OnDrop = nil
    self._AfterEnd = nil
    if self._Progress then
        self._Progress:Close()
        self._Progress = nil
    end
end

return XUiCommonDragContext
