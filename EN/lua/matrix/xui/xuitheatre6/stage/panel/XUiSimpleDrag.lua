---@class XUiSimpleDrag 简易拖拽组件
---@field _Transform UnityEngine.Transform
---@field _Caller table
local XUiSimpleDrag = XClass(nil, "XUiSimpleDrag")

local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local Vector2 = CS.UnityEngine.Vector2

local Status = {
    None = 0,
    Dragging = 1,
}

local DEFAULT_TRIGGER_DELAY = 0.2

---@param transform UnityEngine.Transform
---@param caller table 回调对象的调用者
function XUiSimpleDrag:Ctor(transform, caller)
    self._Transform = transform
    self._Caller = caller
    self._Status = Status.None
    self._TargetAreas = {}
    self._Callbacks = {}
    self._TriggerDelay = DEFAULT_TRIGGER_DELAY
    self._PressStartTime = nil
    self._ClonedGo = nil
    self._CloneParent = nil
    self._TargetTransform = nil
    self._CurrentAreaId = nil
    self._ScrollRect = nil
end

---初始化设置
---@param targetTransform UnityEngine.Transform 被克隆的目标Transform
---@param cloneParent UnityEngine.Transform 克隆体的父节点（通常是Canvas层）
---@param scrollRect UnityEngine.UI.ScrollRect|nil 外部传入的需在按下时禁用的滚动组件，未传入则不处理滚动
function XUiSimpleDrag:Setup(targetTransform, cloneParent, scrollRect)
    self._TargetTransform = targetTransform
    self._CloneParent = cloneParent
    self._ScrollRect = scrollRect
    self:_InitLongClick()
end

function XUiSimpleDrag:_InitLongClick()
    self._LongClick = XUiButtonLongClick.New(
        self._Transform,
        5, -- interval
        self,
        self._OnClick,
        self._OnLongClick,
        self._OnUp,
        false, -- isCanExit
        nil,   -- proxy
        false, -- onlyOneCallback
        true   -- noAutoUp (不自触发OnUp，由我们手动控制)
    )
    self:_InitScrollRectHandler()
    self._LongClick:AddFocusExitListener(handler(self, self._OnFocusExit))
end

--- 外部传入 ScrollRect 时,按下即禁用滚动,避免抢占长按/拖拽
function XUiSimpleDrag:_InitScrollRectHandler()
    if not self._ScrollRect or XTool.UObjIsNil(self._ScrollRect) then
        return
    end
    local pointer = self._Transform.gameObject:GetComponent("XUiPointer")
    if not pointer then
        return
    end
    pointer:AddPointerDownListener(function()
        if self._ScrollRect and not XTool.UObjIsNil(self._ScrollRect) then
            self._ScrollRect.enabled = false
        end
    end)
    pointer:AddPointerUpListener(function()
        self:_RestoreScrollRect()
    end)
end

function XUiSimpleDrag:_RestoreScrollRect()
    if self._ScrollRect and not XTool.UObjIsNil(self._ScrollRect) then
        self._ScrollRect.enabled = true
    end
end

---设置长按触发延迟（秒）
---@param seconds number
function XUiSimpleDrag:SetTriggerDelay(seconds)
    self._TriggerDelay = seconds or DEFAULT_TRIGGER_DELAY
end

---添加目标区域
---@param rectTransform UnityEngine.RectTransform
---@param areaId any 区域标识
function XUiSimpleDrag:AddTargetArea(rectTransform, areaId)
    self._TargetAreas[areaId] = rectTransform
end

---清除所有目标区域
function XUiSimpleDrag:ClearTargetAreas()
    self._TargetAreas = {}
end

---注册事件回调
---@param actionType number DragAction类型
---@param callback function
function XUiSimpleDrag:RegisterCallback(actionType, callback)
    self._Callbacks[actionType] = callback
end

function XUiSimpleDrag:_ApplyAction(actionType, ...)
    if self._Callbacks[actionType] then
        self._Callbacks[actionType](...)
    end

end

---短按点击回调
function XUiSimpleDrag:_OnClick()
    self:_RestoreScrollRect()
    if self._Status == Status.Dragging then
        return
    end
    self:_ApplyAction(XEnumConst.Theatre6.DragAction.Click)
end

---长按回调（每帧触发）
function XUiSimpleDrag:_OnLongClick()
    if self._Status == Status.None then
        -- 记录首次触发时间
        if not self._PressStartTime then
            self._PressStartTime = CS.UnityEngine.Time.time
        end
        -- 未达到延迟阈值，不进入拖拽
        if CS.UnityEngine.Time.time - self._PressStartTime < self._TriggerDelay then
            return
        end

        -- 进入拖拽状态
        self._Status = Status.Dragging

        -- 创建克隆体
        if self._TargetTransform and self._CloneParent and not self._ClonedGo then
            local go = XUiHelper.Instantiate(self._TargetTransform.gameObject)
            -- 自动挂到所在 Canvas 下并置顶,避免被同级元素遮挡
            local searchFrom = self._CloneParent or self._TargetTransform
            local canvas = searchFrom:GetComponentInParent(typeof(CS.UnityEngine.Canvas))
            local parent = (canvas and not XTool.UObjIsNil(canvas)) and canvas.transform or self._CloneParent
            go.transform:SetParent(parent, false) -- false 保持世界坐标和缩放
            go.transform.position = self._TargetTransform.position
            go.transform:SetAsLastSibling()
            self._ClonedGo = go
        end

        self:_ApplyAction(XEnumConst.Theatre6.DragAction.Start)
    end

    -- 拖拽中：更新克隆体位置
    if self._Status == Status.Dragging and self._ClonedGo then
        local uiCamera = CS.XUiManager.Instance.UiCamera
        local parent = self._ClonedGo.transform.parent
        self._ClonedGo.transform.localPosition = XUiHelper.GetScreenClickPosition(parent, uiCamera)

        -- 检测目标区域
        self:_CheckTargetAreas(uiCamera)
    end
end

---松手回调
function XUiSimpleDrag:_OnUp()
    if self._Status == Status.Dragging then
        -- 触发结束回调，传递当前所在区域ID
        self:_ApplyAction(XEnumConst.Theatre6.DragAction.End, self._CurrentAreaId)
    end

    -- 清理克隆体
    self:_CleanupClone()
    self:_ResetStatus()
    self:_RestoreScrollRect()
end

---焦点丢失:视为放弃,清空目标区域并让底层 OnUp 走完整松手流程(同时复位 IsPressing/Timer)
function XUiSimpleDrag:_OnFocusExit()
    self._CurrentAreaId = nil
    if self._LongClick then
        self._LongClick:OnUp()
    end
end

function XUiSimpleDrag:_CheckTargetAreas(uiCamera)
    if not self._ClonedGo then
        return
    end

    local screenPos = uiCamera:WorldToScreenPoint(self._ClonedGo.transform.position)
    local screenPoint = Vector2(screenPos.x, screenPos.y)

    local foundAreaId = nil
    for areaId, rectTransform in pairs(self._TargetAreas) do
        if CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(rectTransform, screenPoint, uiCamera) then
            foundAreaId = areaId
            break
        end
    end

    -- 状态变化
    if foundAreaId then
        if self._CurrentAreaId ~= foundAreaId then
            -- 离开旧区域
            if self._CurrentAreaId then
                self:_ApplyAction(XEnumConst.Theatre6.DragAction.LeaveTargetArea, self._CurrentAreaId)
            end
            -- 进入新区域
            self._CurrentAreaId = foundAreaId
            self:_ApplyAction(XEnumConst.Theatre6.DragAction.EnterTargetArea, foundAreaId)
        end
    else
        -- 离开所有区域
        if self._CurrentAreaId then
            self:_ApplyAction(XEnumConst.Theatre6.DragAction.LeaveTargetArea, self._CurrentAreaId)
            self._CurrentAreaId = nil
        end
    end
end

function XUiSimpleDrag:_CleanupClone()
    if self._ClonedGo then
        XUiHelper.Destroy(self._ClonedGo)
        self._ClonedGo = nil
        self.Ui = nil
    end
end

function XUiSimpleDrag:_ResetStatus()
    self._Status = Status.None
    self._PressStartTime = nil
    self._CurrentAreaId = nil
end

---销毁组件
function XUiSimpleDrag:Destroy()
    self:_RestoreScrollRect()
    self:_CleanupClone()
    if self._LongClick then
        self._LongClick:Destroy()
        self._LongClick = nil
    end
    self._Callbacks = nil
    self._TargetAreas = nil
    self._ScrollRect = nil
end

function XUiSimpleDrag:GetCloneUi()
    if not self.Ui then
        self.Ui = {}
        XTool.InitUiObjectByUi(self.Ui, self._ClonedGo)
    end
    return self.Ui
end

return XUiSimpleDrag
