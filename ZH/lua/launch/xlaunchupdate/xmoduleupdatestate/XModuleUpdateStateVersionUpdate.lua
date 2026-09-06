----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateVersionUpdate.lua
-- description: 模块更新 - 更新版本信息
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File
local CsDirectory = CS.System.IO.Directory

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateVersionUpdate : XModuleUpdateStateBase
local XModuleUpdateStateVersionUpdate = XLaunchConst.CreateMetaTable("XModuleUpdateStateVersionUpdate", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateVersionUpdate:OnEnter()
    -- 更新版本信息
    if self.ModuleUpdateInfo:HasUpdated() then
        local DocumentIndexFilePath = self.ModuleUpdateInfo.DocumentIndex
        if CsFile.Exists(DocumentIndexFilePath) then
            CsFile.Delete(DocumentIndexFilePath)
        end

        local DownloadIndexFilePath = self.ModuleUpdateInfo:GetDownloadIndexPath()
        CsFile.Move(DownloadIndexFilePath, DocumentIndexFilePath)
        self.ModuleUpdateInfo:UpdateVersion()
        self.ModuleUpdateInfo:DeleteTempVersionCache()

        -- 解锁cache
        self.UpdateManager:ClearCache()
        XLaunchConst.SetKeyValue(XLaunchConst.IsUpdateKey, true)
    end

    -- 清理
    self.ModuleUpdateInfo:DeleteAllCache()
    self:OnFinish()
end

return XModuleUpdateStateVersionUpdate
