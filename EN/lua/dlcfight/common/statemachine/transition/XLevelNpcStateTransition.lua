local XStateMachineTransition = require("Common/StateMachine/XStateMachineTransition")

---@class XLevelNpcStateTransition: XStateMachineTransition 寻路到其他状态
---@field _fromState XFindPathState
---@field _targetPos Vector3 目标点
---@field _placeId number
---@field _uuid number
local XLevelNpcStateTransition = XClass(XStateMachineTransition, "XLevelNpcStateTransition")

---@overload
---@param proxy XDlcCSharpFuncs
function XLevelNpcStateTransition:InitBase(proxy, machine, fromState, toState)
    XStateMachineTransition.InitBase(self, proxy, machine, fromState, toState)
    self._placeId = self._proxy:GetNpcPlaceId()
    self._uuid = self._proxy:GetSelfNpcId()
end

return XLevelNpcStateTransition