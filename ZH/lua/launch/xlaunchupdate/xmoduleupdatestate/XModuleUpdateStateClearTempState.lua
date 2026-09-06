----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateClearTempState.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

local CsFile = CS.System.IO.File

---@class XModuleUpdateStateClearTempState : XModuleUpdateStateBase
local XModuleUpdateStateClearTempState = XLaunchConst.CreateMetaTable("XModuleUpdateStateClearTempState", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateClearTempState:OnEnter()
    self.ModuleUpdateInfo:DeleteTempVersionCache()
    self:OnFinish()
end

return XModuleUpdateStateClearTempState
