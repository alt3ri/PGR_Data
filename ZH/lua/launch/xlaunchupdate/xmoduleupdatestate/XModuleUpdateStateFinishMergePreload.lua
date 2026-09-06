----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateFinishMergePreload.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File
local CsDirectory = CS.System.IO.Directory

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateFinishMergePreload : XModuleUpdateStateBase
local XModuleUpdateStateFinishMergePreload = XLaunchConst.CreateMetaTable("XModuleUpdateStateFinishMergePreload", XModuleUpdateStateBase)

function XModuleUpdateStateFinishMergePreload:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateFinishMergePreload:OnEnter()
    -- preload目录清理
    local patchFilePath = self.ModuleUpdateInfo:GetPreloadFilePath()
    if CsDirectory.Exists(patchFilePath) then
        CsDirectory.Delete(patchFilePath, true)
    end
    self:OnFinish()
end

return XModuleUpdateStateFinishMergePreload
