----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateLoadTempIndex.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

local CsFile = CS.System.IO.File

---@class XModuleUpdateStateLoadTempIndex : XModuleUpdateStateBase
local XModuleUpdateStateLoadTempIndex = XLaunchConst.CreateMetaTable("XModuleUpdateStateLoadTempIndex", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateLoadTempIndex:OnEnter()
    self.ModuleUpdateInfo:ReadTempVersionCache()
    if self.ModuleUpdateInfo:IsTempVersion() then
        local tempVersion = self.ModuleUpdateInfo:GetTempVersion()
        local indexPath = self.ModuleUpdateInfo:GetDownloadIndexVersionPath(tempVersion)
        if not CsFile.Exists(indexPath) then
            self:OnAbort()
            return
        end
        local normalIndexTable = self.UpdateManager:LoadIndexTable(indexPath)
        self.UpdateManager.LocalIndexTable = normalIndexTable
        self:OnFinish()
    else
        self:OnAbort()
    end
end


return XModuleUpdateStateLoadTempIndex
