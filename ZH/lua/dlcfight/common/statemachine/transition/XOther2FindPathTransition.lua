local XLevelNpcStateTransition = require("Common/StateMachine/Transition/XLevelNpcStateTransition")

---@class XOther2FindPathTransition: XLevelNpcStateTransition 其他状态到寻路状态
---@field _stayTime number 持续时长
---@field _path Vector3[] 寻路参数：寻路路径
---@field _checkDistance number 寻路参数：到达距离判断
---@field _toState XFindPathState
---@field _stopTimerTriggerId number 触发停止计时的Trigger
---@field _placeId number
---@field _uuid number
---@field _isTimer bool
local XOther2FindPathTransition = XClass(XLevelNpcStateTransition, "XOther2FindPathTransition")

---@overload
function XOther2FindPathTransition:InitOther(stayTime, path, stopTimerTriggerId, checkDistance)
    self._stayTime = stayTime
    self._curTime = self._stayTime
    self._path = path
    self._checkDistance = checkDistance
    self._stopTimerTriggerId = stopTimerTriggerId
    self._isTimer = true
    if self._stopTimerTriggerId then
        self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    end
end

---@overload
---@return boolean
function XOther2FindPathTransition:Condition(dt)
    if not self._proxy:GetNpcActive(self._uuid) or not self._isTimer then
        return false
    end
    if self._placeId == 0 or self._proxy:CheckNpcIsInInteract(self._placeId) then
        return false
    end
    self._curTime = self._curTime - dt
    if self._curTime <= 0 then
        return true
    end
    return false
end

---@overload
function XOther2FindPathTransition:OnTransitionBefore()
    self._curTime = self._stayTime
end

---@overload
function XOther2FindPathTransition:OnTransitionAfter()
    if self._toState then
        self._toState:SetPath(self._path, self._checkDistance)
        self._toState:StartMove()
    end
end

---@param eventType number
---@param eventArgs userdata
function XOther2FindPathTransition:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        self:OnActorTrigger(eventType, eventArgs)
    end
end

function XOther2FindPathTransition:OnActorTrigger(eventType, eventArgs)
    if eventArgs.TriggerId ~= self._stopTimerTriggerId
            or self._uuid ~= eventArgs.TriggerHolderUUID
            or not self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID)
    then
        return
    end
    if eventArgs.TriggerState == ETriggerState.Enter then
        self._isTimer = false
        XLog.Debug("[脚本: "..self._proxy.Id.."]状态转移方程 停止计时 从状态:"..self._fromState.StateEnum.." 到状态:"..self._toState.StateEnum)
    elseif eventArgs.TriggerState == ETriggerState.Exit then
        self._isTimer = true
        XLog.Debug("[脚本: "..self._proxy.Id.."]状态转移方程 开始计时 从状态:"..self._fromState.StateEnum.." 到状态:"..self._toState.StateEnum)
    end
end

return XOther2FindPathTransition