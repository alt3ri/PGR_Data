local RectTransformUtility = CS.UnityEngine.RectTransformUtility
local Mathf = CS.UnityEngine.Mathf
local Vector2 = CS.UnityEngine.Vector2
local XUiCommonJoystick = XClass(XUiNode, "XUiCommonJoystick")

function XUiCommonJoystick:OnStart(gameObject, joystickScope, backdragTouch, touchButton, isAddJoystickInputEvent)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    self.IsAddJoystickInputEvent = isAddJoystickInputEvent

    self.JoystickScope = joystickScope or self.Transform:Find("JoystickScope")
    self.BackdragTouch = backdragTouch or self.JoystickScope:Find("BackdragTouch")
    self.TouchButton = touchButton or self.BackdragTouch:Find("TouchButton")

    -- 遥杆范围
    self.JoystickTouchRange = 120
    -- 原始坐标
    self.OriginalPos = self.BackdragTouch.anchoredPosition
    -- 遥杆边缘
    self.JoystickEdge = self.Transform.sizeDelta * 0.5
    -- 是否触发中
    self.IsTrigger = false
    self.TriggerThresholdSqr = 0
    self.IsStart = false
    -- 移动方向更新方法
    self.UpdateMoveDirectionFunc = nil

    self._PointerDownFunc = function(eventData) self:_OnPointerDown(eventData) end
    self._PointerUpFunc = function(eventData) self:_OnPointerUp(eventData) end
    self._DragFunc = function(eventData) self:_OnDrag(eventData) end
end

function XUiCommonJoystick:SetUpdateMoveDirectionFunc(updateMoveDirectionFunc)
    self.UpdateMoveDirectionFunc = updateMoveDirectionFunc
end

function XUiCommonJoystick:OnEnable()
    -- 注册事件
    self:AddUiEvents()
end

function XUiCommonJoystick:OnDisable()
    self:RemoveUiEvents()
end

--######################## 私有方法 ########################

--region 私有方法

function XUiCommonJoystick:AddUiEvents()
    -- 注册遥杆事件
    if not self._uiWeight then
        self._uiWeight = self.JoystickScope.gameObject:AddComponent(typeof(CS.XUiWidget))
    end
    if not self._uiRegister then
        self._uiWeight:AddPointerDownListener(self._PointerDownFunc)
        self._uiWeight:AddPointerUpListener(self._PointerUpFunc)
        self._uiWeight:AddDragListener(self._DragFunc)
        self._uiRegister = true
    end

    local lastDir
    local inputEventFunc = function(evtId, arg)
        if XDataCenter.GuideManager.CheckIsInGuide() then return end
        if CS.XUiManagerExtension.Masked or self.IsStart then return end
        local vector3 = arg.Vector
        local direction = Vector2(vector3.x, vector3.y)
        if lastDir == direction then return end
        if direction == Vector2.zero then
            self.TouchButton.anchoredPosition = direction
        else
            self.TouchButton.anchoredPosition = direction / direction.magnitude * self.JoystickTouchRange
        end
        self:_UpdateMoveDirectionFunc(direction)
        lastDir = direction
    end
    if not self.EvtIndex then
        -- 注册摇杆事件
        self.EvtIndex = CS.XCommonGenericEventManager.RegisterLuaEvent(XEventId.EVENT_ALTER_LEFT_STICK_EVENT, inputEventFunc)
    end
    if self.IsAddJoystickInputEvent and not self.EvtIndex2 then
        self.EvtIndex2 = CS.XCommonGenericEventManager.RegisterLuaEvent(XEventId.EVENT_LEFT_STICK_EVENT, inputEventFunc)
    end
end

function XUiCommonJoystick:RemoveUiEvents()
    if self.EvtIndex then
        CS.XCommonGenericEventManager.RemoveLuaEvent(XEventId.EVENT_ALTER_LEFT_STICK_EVENT, self.EvtIndex)
        self.EvtIndex = false
    end
    if self.EvtIndex2 then
        CS.XCommonGenericEventManager.RemoveLuaEvent(XEventId.EVENT_LEFT_STICK_EVENT, self.EvtIndex2)
        self.EvtIndex2 = false
    end

    if self._uiWeight then
        self._uiWeight:RemoveAllListeners()
        self._uiRegister = false
    end
end

function XUiCommonJoystick:_TriggerCheck(position)
    if self.IsTrigger then return true end
    if position.sqrMagnitude / self.BackdragTouch.sizeDelta.sqrMagnitude * 4 
        > self.TriggerThresholdSqr then
        self.IsTrigger = true
        return true
    end
    return false
end

function XUiCommonJoystick:_UpdateTouchPos(vec2, camera)
    local hasValue, position = RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BackdragTouch, vec2, camera)
    if not hasValue then return false end
    if not self:_TriggerCheck(position) then return false end

    local direction = position.normalized
    self.TouchButton.anchoredPosition = direction * Mathf.Clamp(position.magnitude, 0, self.JoystickTouchRange)
    self:_UpdateMoveDirectionFunc(direction)
    return true
end

function XUiCommonJoystick:_OnPointerDown(eventData)
    if self:_UpdateTouchPos(eventData.position, eventData.pressEventCamera) then
        self.IsStart = true
    end
end

function XUiCommonJoystick:_OnPointerUp(eventData)
    self.BackdragTouch.anchoredPosition = self.OriginalPos
    self.TouchButton.anchoredPosition = Vector2.zero
    self.IsTrigger = false
    self.IsStart = false
    self:_UpdateMoveDirectionFunc(Vector2.zero)
end

function XUiCommonJoystick:_OnDrag(eventData)
    if not self.IsStart then return end
    self:_UpdateTouchPos(eventData.position, eventData.pressEventCamera)
end

function XUiCommonJoystick:_UpdateMoveDirectionFunc(vec2)
    if not self.UpdateMoveDirectionFunc then return end
    self.UpdateMoveDirectionFunc(vec2)
end

--endregion

return XUiCommonJoystick
