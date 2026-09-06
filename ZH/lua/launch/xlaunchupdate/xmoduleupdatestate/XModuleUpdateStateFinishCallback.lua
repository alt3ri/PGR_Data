----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateFinishCallback.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateFinishCallback : XModuleUpdateStateBase
local XModuleUpdateStateFinishCallback = XLaunchConst.CreateMetaTable("XModuleUpdateStateFinishCallback", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateFinishCallback:OnEnter()
    local cb = self.UpdateManager:GetFinishCallback()
    if cb then cb(false, self.UpdateManager) end
end

return XModuleUpdateStateFinishCallback
