local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

---@class XUiPanelTheatre6Drag : XUiNode 封装拖动Ui逻辑的组件
---@field _Control XTheatre6Control
---@field _LongClick XUiButtonLongClick
---@field _PanelAreas table<number,UnityEngine.Bounds>
local XUiPanelTheatre6Drag = XClass(XUiNode, "XUiPanelTheatre6Drag")

local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local Array = CS.System.Array
local DragAction = XEnumConst.Theatre6.DragAction
local Direction = XEnumConst.Theatre6.Direction
local Status = {
    None = 0,
    Dragging = 1 << 0,
}

function XUiPanelTheatre6Drag:OnStart()
    self._Handlers = {}
    self._PanelAreas = {}
    self._Status = Status.None
    self._CurDirection = nil
    self._AreaStatusDict = {}
    self._PressStartTime = nil
end

function XUiPanelTheatre6Drag:InitComponent()
    self._Speed = self._Control:GetIntClientConfigValue("ItemFlySpeed")
    self._LongClick = XUiButtonLongClick.New(self.Transform, 1, self, self.OnClickBlock, self.OnLongClickBlock, self.OnUpClickBlock)
    self._LongClick:AddFocusExitListener(handler(self, self.OnFocusExit))
end

function XUiPanelTheatre6Drag:OnDestroy()
    self._TargetTran:DOKill()
    self._Handlers = nil
    self._PanelAreas = nil
    self._LongClick:Destroy()
end

--target的显隐和移动受组件控制 外部无需关注
---接受拖动事件的对象和被移动的对象不是同一个
---@param target XUiNode
function XUiPanelTheatre6Drag:SetTarget(target)
    self._Target = target
    self._TargetTran = target.Transform
    self:InitComponent()
    --self._Target:Close() 
end

---接受拖动事件的对象和被移动的对象是同一个
function XUiPanelTheatre6Drag:SetTargetSelf()
    self._TargetTran = self.Transform
    self:InitComponent()
end

---设置左边区域
---@param panelArea UnityEngine.RectTransform
function XUiPanelTheatre6Drag:SetLeftArea(panelArea)
    local id = self:_SetArea(panelArea)
    self._AreaStatusDict[id] = Direction.Left
end

---设置右边区域
---@param panelArea UnityEngine.RectTransform
function XUiPanelTheatre6Drag:SetRightArea(panelArea)
    local id = self:_SetArea(panelArea)
    self._AreaStatusDict[id] = Direction.Right
end

---设置自定义区域
---@param panelArea UnityEngine.RectTransform
---@param type number
function XUiPanelTheatre6Drag:SeCustomArea(panelArea, type)
    local id = self:_SetArea(panelArea)
    self._AreaStatusDict[id] = type
end

---@private
function XUiPanelTheatre6Drag:_SetArea(panelArea)
    local id = panelArea:GetInstanceID()
    self._PanelAreas[id] = panelArea
    return id
end

---通过拖动距离触发确认，而非使用点击区域
function XUiPanelTheatre6Drag:SetConfirmDistance(distance)
    self._ConfirmDistance = distance
end

---设置屏幕节点（非必须）
---@param panelScene UnityEngine.RectTransform
function XUiPanelTheatre6Drag:SetScene(panelScene)
    self._PanelScene = panelScene
    self._RootCorners = Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)
    self._SelfCorners = Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)
end

---注册拖动行为回调
function XUiPanelTheatre6Drag:RegistActionHandler(acion, handler)
    self._Handlers[acion] = handler
end

function XUiPanelTheatre6Drag:ApplyAction(action, ...)
    local ret = false
    if self._Handlers[action] then
        self._Handlers[action](...)
        ret = true
    end
    if action == DragAction.End then
        self:ClearStatus()
    end
    return ret
end

---短按点击回调（未触发拖拽）
function XUiPanelTheatre6Drag:OnClickBlock()
    self:ApplyAction(DragAction.Click)
end

function XUiPanelTheatre6Drag:OnLongClickBlock()
    local uiCamera = CS.XUiManager.Instance.UiCamera
    local curPos = XUiHelper.GetScreenClickPosition(self._TargetTran.parent, uiCamera)

    if (self._Status & Status.Dragging) == 0 then
        --记录长按回调首次触发的真实时间
        if not self._PressStartTime then
            self._PressStartTime = CS.UnityEngine.Time.time
        end
        self._Status = self._Status | Status.Dragging
        self:ApplyAction(DragAction.Start)
        self._TargetTran:DOKill()
        if self._Target then
            self._Target:Open()
        end
        self._InitPos = self._TargetTran.localPosition
        self._InitDragPosX = curPos.x
    end
    
    self._TargetTran.localPosition = curPos
    self:ApplyAction(DragAction.Dragging, curPos.x, curPos.y)

    if XTool.IsTableEmpty(self._PanelAreas) then
        if math.abs(curPos.x - self._InitDragPosX) >= self._ConfirmDistance then
            local dir = curPos.x < self._InitDragPosX and Direction.Left or Direction.Right
            if self._CurDirection ~= dir then
                self._CurDirection = dir
                self:ApplyAction(DragAction.EnterTargetArea, self._CurDirection)
            end
            return
        end
    else
        local screenPos = uiCamera:WorldToScreenPoint(self._TargetTran.position)
        local screenPoint = Vector2(screenPos.x, screenPos.y)
        for id, panelArea in pairs(self._PanelAreas) do
            if CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(panelArea, screenPoint, uiCamera) then
                local dir = self._AreaStatusDict[id]
                if self._CurDirection ~= dir then
                    self._CurDirection = dir
                    self:ApplyAction(DragAction.EnterTargetArea, self._CurDirection)
                end
                return
            end
        end
    end

    if self._CurDirection then
        self._CurDirection = nil
        self:ApplyAction(DragAction.LeaveTargetArea)
    end
end

function XUiPanelTheatre6Drag:OnUpClickBlock()
    if (self._Status & Status.Dragging) ~= 0 then
        --取消拖动时播放自定义表现
        if not self:ApplyAction(DragAction.PlayEnd, self._CurDirection) then
            --外部没有设置 回到原位
            self:MoveToOriginalPos()
        end
    else
        self:ClearStatus()
    end
end

---焦点丢失 相对于放弃 Ui会移动回原点
function XUiPanelTheatre6Drag:OnFocusExit()
    self:MoveToOriginalPos()
end

function XUiPanelTheatre6Drag:ClearStatus()
    self._Status = Status.None
    self._CurDirection = nil
    self._PressStartTime = nil
end

---设置拖动对象到初始位置
function XUiPanelTheatre6Drag:InitDragToOriginalPos()
    if self._InitPos then
        self._TargetTran:DOKill()
        self._TargetTran.localPosition = self._InitPos
    end
end

---移动回到原位
function XUiPanelTheatre6Drag:MoveToOriginalPos()
    local curAreaId = self._CurDirection
    self._TargetTran:DOKill()
    if not self._InitPos then
        self:ApplyAction(DragAction.End, curAreaId)
        return
    end
    self._TargetTran:DOLocalMove(self._InitPos, self._Speed):OnComplete(function()
        --self._Target:Close()
        self:ApplyAction(DragAction.End, curAreaId)
    end)
end

---往左飞出屏幕
function XUiPanelTheatre6Drag:MoveToLeft()
    local posX = self:TryGetSceneOutPosX(false)
    if posX then
        self._TargetTran:DOKill()
        self._TargetTran:DOLocalMoveX(posX, self._Speed):OnComplete(function()
            --self._Target:Close()
            self:ApplyAction(DragAction.End, self._CurDirection)
        end)
    end
end

---往右飞出屏幕
function XUiPanelTheatre6Drag:MoveToRight()
    local posX = self:TryGetSceneOutPosX(true)
    if posX then
        self._TargetTran:DOKill()
        self._TargetTran:DOLocalMoveX(posX, self._Speed):OnComplete(function()
            --self._Target:Close()
            self:ApplyAction(DragAction.End, self._CurDirection)
        end)
    end
end

---隐藏
function XUiPanelTheatre6Drag:HideSelf()
    if self._Target then
        self._Target:Close()
    end
    self:ApplyAction(DragAction.End, self._CurDirection)
end

function XUiPanelTheatre6Drag:TryGetSceneOutPosX(toRight)
    if XTool.UObjIsNil(self._PanelScene) then
        XLog.Error("请先设置屏幕节点")
        return nil
    end

    self._PanelScene:GetWorldCorners(self._RootCorners)

    local left = self._RootCorners[0].x
    local right = self._RootCorners[3].x

    self._TargetTran:GetWorldCorners(self._SelfCorners)

    local width = self._SelfCorners[3].x - self._SelfCorners[0].x
    local targetWorldX = toRight and (right + width) or (left - width)

    local worldPos = Vector3(targetWorldX, self._TargetTran.position.y, self._TargetTran.position.z)
    return self._TargetTran.parent:InverseTransformPoint(worldPos).x
end

return XUiPanelTheatre6Drag
