local XMachineBaseState = require("Common/StateMachine/XMachineBaseState")

---@class XLevelNpcState: XMachineBaseState @LevelNpc状态
---@field TargetPos Vector3 目标点
---@field _placeId number
---@field _uuid number
local XLevelNpcState = XClass(XMachineBaseState, "XNpcState")

---@overload
---@param proxy XDlcCSharpFuncs
function XLevelNpcState:Init(proxy, ...)
    XMachineBaseState.Init(self, proxy, ...)
    self._placeId = self._proxy:GetNpcPlaceId()
    self._uuid = self._proxy:GetSelfNpcId()
end

return XLevelNpcState