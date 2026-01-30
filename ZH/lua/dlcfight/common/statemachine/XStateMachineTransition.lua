---@class XStateMachineTransition @状态机-状态转移方程
---@field _proxy XDlcCSharpFuncs
---@field _machine XStateMachineController
---@field _fromState XMachineBaseState
---@field _toState XMachineBaseState
local XStateMachineTransition = XClass(nil, "XStateMachineTransition")

---@param proxy XDlcCSharpFuncs
---@param machine XStateMachineController
---@param fromState XMachineBaseState
---@param toState XMachineBaseState
function XStateMachineTransition:InitBase(proxy, machine, fromState, toState)
    self._machine = machine
    self._proxy = proxy
    self._fromState = fromState
    self._toState = toState
end

function XStateMachineTransition:InitOther(...)
end

---@param eventType number
---@param eventArgs userdata
function XStateMachineTransition:HandleEvent(eventType, eventArgs)
    
end

function XStateMachineTransition:Terminate()
    self._proxy = nil
    self._fromState = nil
    self._toState = nil
end

--region API
---@param dt number
---@return boolean
function XStateMachineTransition:Condition(dt)
    return false
end

function XStateMachineTransition:OnTransitionBefore()

end

function XStateMachineTransition:OnTransitionAfter()

end
--endregion

return XStateMachineTransition