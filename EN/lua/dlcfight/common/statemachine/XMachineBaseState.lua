---@class XMachineBaseState @状态机组件
---@field _proxy XDlcCSharpFuncs
---@field StateEnum number
---@field StateMachine XStateMachineController
local XMachineBaseState = XClass(nil, "XMachineBaseState")

---@param proxy XDlcCSharpFuncs
function XMachineBaseState:Init(proxy, stateMachine, ...)
    self._proxy = proxy
    self.StateEnum = 0
    self.StateMachine = stateMachine
    self:InitStateConfig()
    self:InitEnum()
end

function XMachineBaseState:InitEnum()
end

function XMachineBaseState:InitStateConfig()
    if self.StateConfig == nil then
        return
    end
    self.StateEnum = self.StateConfig.StateEnum
end

---@param eventType number
---@param eventArgs userdata
function XMachineBaseState:HandleEvent(eventType, eventArgs)
    
end

function XMachineBaseState:Terminate()
    self._proxy = nil
end

--region StateChange
function XMachineBaseState:OnStateEnter(lastStateEnum)

end

function XMachineBaseState:OnStateLeave(nextStateEnum)

end

function XMachineBaseState:OnStateUpdate(dt)

end
--endregion

return XMachineBaseState