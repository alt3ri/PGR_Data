-- 拖拽手势组件（单格手势层）：判定何时开始拖拽，处理长按/滑动/多指与 ScrollRect 共存。
---@class XUiCommonDragGesture
local XUiCommonDragGesture = XClass(nil, "XUiCommonDragGesture")

local XUiCommonDragInput = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragInput")
local CSInput = CS.UnityEngine.Input

local function GetNow()
    return CS.UnityEngine.Time.realtimeSinceStartup
end

local Status = {
    Idle = 0,
    Pressing = 1, -- 已按下、预热计时中
    Progress = 2, -- 长按进度阶段（仅 Press 模式）
    Dragging = 3, -- 已进入拖拽（交会话层）
    WaitClick = 4, -- 不可拖拽，仅等待抬手判定点击
}

local DEFAULT_CONFIG = {
    TriggerMode = XEnumConst.CommonDrag.TriggerMode.Press,
    PressDuration = 0.2, -- 预热延迟（秒）：过滤误触/滑动
    ProgressDuration = 1.5, -- 进度阶段时长（秒）：满即起拖
    MoveTolerance = 20, -- 进度阶段移动容差（屏幕像素）
    SlideThreshold = 15, -- 滑动/起拖位移阈值（屏幕像素）
    DisableMultiTouch = true, -- 是否禁止多指（仅移动端，PC 端不限制）
}

---@class XUiCommonDragGestureConfig
---@field TriggerMode number 默认 Press
---@field PressDuration number 预热延迟（秒），默认 0.2
---@field ProgressDuration number 进度阶段时长（秒），默认 1.5
---@field MoveTolerance number 进度阶段移动容差（像素），默认 20
---@field SlideThreshold number 滑动/起拖位移阈值（像素），默认 15
---@field DisableMultiTouch boolean 是否禁止多指，默认 true

---@param transform UnityEngine.Transform 拖拽手势作用的目标 Transform（通常为格子 Transform）
---@param config XUiCommonDragGestureConfig 配置项，均可选
function XUiCommonDragGesture:Ctor(transform, config)
    self._Transform = transform

    config = config or {}
    self._TriggerMode = config.TriggerMode or DEFAULT_CONFIG.TriggerMode
    self._PressDuration = config.PressDuration or DEFAULT_CONFIG.PressDuration
    self._ProgressDuration = config.ProgressDuration or DEFAULT_CONFIG.ProgressDuration
    self._MoveTolerance = (config.MoveTolerance and config.MoveTolerance > 0) and config.MoveTolerance or DEFAULT_CONFIG.MoveTolerance
    self._SlideThreshold = (config.SlideThreshold and config.SlideThreshold > 0) and config.SlideThreshold or DEFAULT_CONFIG.SlideThreshold
    if config.DisableMultiTouch == nil then
        self._DisableMultiTouch = DEFAULT_CONFIG.DisableMultiTouch
    else
        self._DisableMultiTouch = config.DisableMultiTouch
    end

    self._IsDirect = self._TriggerMode == XEnumConst.CommonDrag.TriggerMode.Direct

    self._Status = Status.Idle
    self._PointerId = nil
    self._PressStartTime = 0
    self._ProgressStartTime = 0
    self._StartX = 0
    self._StartY = 0
    self._Tick = nil

    self:_InitListener()
end

function XUiCommonDragGesture:_InitListener()
    if XTool.UObjIsNil(self._Transform) then
        XLog.Error("XUiCommonDragGesture:_InitListener error: transform is nil!")
        return
    end
    local go = self._Transform.gameObject
    self._Listener = go:GetComponent(typeof(CS.XUguiDragEventListener))
    if XTool.UObjIsNil(self._Listener) then
        self._Listener = go:AddComponent(typeof(CS.XUguiDragEventListener))
    end
    self._Listener.OnDown = function(eventData) self:_OnPointerDown(eventData) end
    self._Listener.OnUp = function(eventData) self:_OnPointerUp(eventData) end
    self._Listener.OnEnter = function(eventData) self:_OnPointerEnter(eventData) end
    self._Listener.OnExit = function(eventData) self:_OnPointerExit(eventData) end
end

--region 回调注册
function XUiCommonDragGesture:SetOnClick(cb)
    self._OnClick = cb
end

function XUiCommonDragGesture:SetOnDragBegin(cb)
    self._OnDragBegin = cb
end

-- 进入长按进度阶段 cb(progressDuration)
function XUiCommonDragGesture:SetOnPressProgress(cb)
    self._OnPressProgress = cb
end

-- 进度阶段每帧进度回调 cb(progress)，progress 为 [0,1]
function XUiCommonDragGesture:SetOnPressTick(cb)
    self._OnPressTick = cb
end

function XUiCommonDragGesture:SetOnPressCancel(cb)
    self._OnPressCancel = cb
end

-- 本次按下是否可拖拽 fn()->bool；返回 false 则只能点击
function XUiCommonDragGesture:SetCanTrigger(fn)
    self._CanTrigger = fn
end

-- 透传指针“进入本格”事件 cb(eventData)，不参与手势自身状态判定。
-- 用于 Enter 模式落点回灌：本格作为落点时，在 cb 内调 context:NotifyEnter(本格zoneId)。
-- 注意 Enter 模式要求克隆体禁射线(blocksRaycasts=false)，否则克隆体挡住射线收不到本事件。
function XUiCommonDragGesture:SetOnPointerEnter(cb)
    self._OnPointerEnterCb = cb
end

-- 透传指针“离开本格”事件 cb(eventData)，不参与手势自身状态判定。
-- 用于 Enter 模式落点回灌：本格作为落点时，在 cb 内调 context:NotifyExit(本格zoneId)。
function XUiCommonDragGesture:SetOnPointerExit(cb)
    self._OnPointerExitCb = cb
end

function XUiCommonDragGesture:SetOnPointerUp(cb)
    self._OnPointerUpExtra = cb
end

-- 当前按下的触点 id（供会话层做多指 fingerId 匹配）
function XUiCommonDragGesture:GetPointerId()
    return self._PointerId
end
--endregion

--region 屏幕坐标 / 输入
function XUiCommonDragGesture:_GetMoveSqr()
    local x, y = XUiCommonDragInput.GetScreenXY(self._PointerId)
    if not x then
        return 0
    end
    local dx = x - self._StartX
    local dy = y - self._StartY
    return dx * dx + dy * dy
end
--endregion

--region 指针事件
function XUiCommonDragGesture:_OnPointerDown(eventData)
    if self._Status ~= Status.Idle then
        return
    end
    -- 禁止多指：已有触点按下时忽略新触点（PC 鼠标 touchCount 恒 0，不受影响）
    if self._DisableMultiTouch and CSInput.touchCount > 1 then
        return
    end
    self._PointerId = eventData and eventData.pointerId or nil
    -- 记录起点
    local x, y = XUiCommonDragInput.GetScreenXY(self._PointerId)
    self._StartX = x or 0
    self._StartY = y or 0

    -- 不可拖拽
    if self._CanTrigger and not self._CanTrigger() then
        self._Status = Status.WaitClick
        return
    end

    -- 按下不锁滚动，仅进度/拖拽阶段才锁滚动
    self._PressStartTime = GetNow()
    self._Status = Status.Pressing
    self:_StartTick()
end

function XUiCommonDragGesture:_OnPointerUp(eventData)
    if eventData and self._PointerId and eventData.pointerId ~= self._PointerId then
        return
    end
    if self._Status == Status.Dragging then
        -- 拖拽已触发：控制权在会话层，这里只复位并恢复滚动
        self:_Cleanup()
    elseif self._Status == Status.Pressing or self._Status == Status.WaitClick then
        -- 预热/不可拖拽阶段抬手且位移很小 → 点击
        local slideSqr = self._SlideThreshold * self._SlideThreshold
        if self:_GetMoveSqr() <= slideSqr then
            self:_ApplyClick()
        end
        self:_Cleanup()
    elseif self._Status == Status.Progress then
        self:_ApplyPressCancel()
        self:_Cleanup()
    else
        self:_Cleanup()
    end

    if self._OnPointerUpExtra then
        self._OnPointerUpExtra(eventData)
    end
end

function XUiCommonDragGesture:_OnPointerEnter(eventData)
    if self._OnPointerEnterCb then
        self._OnPointerEnterCb(eventData)
    end
end

-- 移出格子 rect：预热/进度阶段均放弃长按
function XUiCommonDragGesture:_OnPointerExit(eventData)
    if eventData and self._PointerId and eventData.pointerId ~= self._PointerId then
        return
    end
    if self._Status == Status.Pressing then
        self:_CancelToSlide()
    elseif self._Status == Status.Progress then
        self:_ApplyPressCancel()
        self:_CancelToSlide()
    end

    if self._OnPointerExitCb then
        self._OnPointerExitCb(eventData)
    end
end
--endregion

--region 每帧驱动
function XUiCommonDragGesture:_StartTick()
    self:_StopTick()
    self._Tick = XScheduleManager.ScheduleForeverEx(function()
        self:_OnTick()
    end, 0)
end

function XUiCommonDragGesture:_StopTick()
    if self._Tick then
        XScheduleManager.UnSchedule(self._Tick)
        self._Tick = nil
    end
end

function XUiCommonDragGesture:_OnTick()
    if XTool.UObjIsNil(self._Transform) then
        self:_Cleanup()
        return
    end

    -- 无按压输入兜底（失焦/异常抬手未收到 OnUp）
    if not XUiCommonDragInput.HasPressInput(self._PointerId) then
        if self._Status == Status.Progress then
            self:_ApplyPressCancel()
        end
        self:_Cleanup()
        return
    end

    local now = GetNow()
    local moveSqr = self:_GetMoveSqr()

    if self._Status == Status.Pressing then
        local slideSqr = self._SlideThreshold * self._SlideThreshold
        if self._IsDirect then
            -- 直接拖拽模式：起手位移超过阈值即进入拖拽
            if moveSqr > slideSqr then
                self:_EnterDragging()
            end
            return
        end
        -- 预热阶段位移过大 → 判定想滑列表，放行滚动
        if moveSqr > slideSqr then
            self:_ApplyPressCancel()
            self:_CancelToSlide()
            return
        end
        -- 预热结束 → 进入进度阶段（锁列表但保留拖拽态，进度中途取消可无缝续滚）
        if now - self._PressStartTime >= self._PressDuration then
            self._Status = Status.Progress
            self._ProgressStartTime = now
            self:_LockScroll(true)
            if self._OnPressProgress then
                self._OnPressProgress(self._ProgressDuration)
            end
        end
        return
    end

    if self._Status == Status.Progress then
        local tolSqr = self._MoveTolerance * self._MoveTolerance
        if moveSqr > tolSqr then
            self:_ApplyPressCancel()
            self:_CancelToSlide()
            return
        end
        -- 每帧回传进度，由进度条按同一时钟渲染
        local elapsed = now - self._ProgressStartTime
        if self._OnPressTick then
            local progress = self._ProgressDuration > 0 and (elapsed / self._ProgressDuration) or 1
            self._OnPressTick(progress > 1 and 1 or progress)
        end
        -- 进度满 → 触发拖拽
        if elapsed >= self._ProgressDuration then
            self:_EnterDragging()
        end
        return
    end
end
--endregion

--region 状态流转
function XUiCommonDragGesture:_EnterDragging()
    self._Status = Status.Dragging
    self:_StopTick()
    self:_LockScroll(false) -- 锁定列表
    if self._OnDragBegin then
        self._OnDragBegin()
    end
end

-- 取消并放行滚动
function XUiCommonDragGesture:_CancelToSlide()
    self._Status = Status.Idle
    self:_StopTick()
    self:_UnlockScroll()
end

function XUiCommonDragGesture:_ApplyClick()
    if self._OnClick then
        self._OnClick()
    end
end

function XUiCommonDragGesture:_ApplyPressCancel()
    if self._OnPressCancel then
        self._OnPressCancel()
    end
end

-- 复位状态，恢复滚动
function XUiCommonDragGesture:_Cleanup()
    self._Status = Status.Idle
    self._PointerId = nil
    self:_StopTick()
    self:_UnlockScroll()
    -- 异常路径(节点销毁/失焦/Reset)抬手 OnEndDrag 可能丢失，主动补发收尾 ScrollRect 拖拽态；
    if not XTool.UObjIsNil(self._Listener) then
        self._Listener:FlushEndDragToScroll()
    end
end
--endregion

-- 锁定列表滚动。
-- suppressEnd=true：进度阶段，转发 begin 让 ScrollRect 进入可续滚态、挡住 drag(列表静止)，打断后无缝续滚；
-- suppressEnd=false：真正拖拽，全挡并补发 EndDrag 结束 ScrollRect
function XUiCommonDragGesture:_LockScroll(suppressEnd)
    if XTool.UObjIsNil(self._Listener) then
        return
    end
    if suppressEnd then
        -- 进度阶段：只挡 drag、放行 begin
        self._Listener.BlockScrollDrag = true
        self._Listener.IsDraggingSelf = false
    else
        -- 真正拖拽：全挡 + 补发 EndDrag 收尾
        self._Listener.BlockScrollDrag = false
        self._Listener.IsDraggingSelf = true
        self._Listener:FlushEndDragToScroll()
    end
end

-- 放行列表滚动（恢复转发给父级 ScrollRect）
function XUiCommonDragGesture:_UnlockScroll()
    if not XTool.UObjIsNil(self._Listener) then
        self._Listener.BlockScrollDrag = false
        self._Listener.IsDraggingSelf = false
    end
end

-- 强制复位（grid 复用刷新前调用）
function XUiCommonDragGesture:Reset()
    self:_Cleanup()
end

function XUiCommonDragGesture:Destroy()
    self:_StopTick()
    self:_UnlockScroll()
    -- 销毁前若 ScrollRect 仍处于已转发 begin 的拖拽态，主动补发 end 收尾
    if not XTool.UObjIsNil(self._Listener) then
        self._Listener:FlushEndDragToScroll()
    end
    self._Listener = nil
    self._Transform = nil
    self._OnClick = nil
    self._OnDragBegin = nil
    self._OnPressProgress = nil
    self._OnPressTick = nil
    self._OnPressCancel = nil
    self._CanTrigger = nil
    self._OnPointerEnterCb = nil
    self._OnPointerExitCb = nil
    self._OnPointerUpExtra = nil
end

return XUiCommonDragGesture
