----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateDownloadAb.lua
-- description: 模块更新 - 下载Ab文件
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateDownloadAb : XModuleUpdateStateBase
local XModuleUpdateStateDownloadAb = XLaunchConst.CreateMetaTable("XModuleUpdateStateDownloadAb", XModuleUpdateStateBase)

function XModuleUpdateStateDownloadAb:Init()
    self._FinishCallback = function()
        self.UpdateManager:ClearDownloadABMap()
        
        if self.ModuleUpdateInfo:IsMatrixUpdate() then
            -- 统计
            local cost_time = os.time() - (self.START_TIME or 0)
            local speed = self._updateSize / cost_time
            -- 1:基础资源 2:完整资源
            local XLaunchDlcManager = require("XLaunchDlcManager")
            local downloadMode = XLaunchDlcManager.IsFullDownload() and 2 or 1
            local dict = {
                ["type"] = self.ModuleUpdateInfo.ResFileType,
                ["version"] = self.ModuleUpdateInfo:GetNewVersion(),
                ["size"] = self._updateSize,
                ["mode"] = downloadMode,
                ["cost"] = cost_time,
                ["speed"] = speed,
            }
            dict["app_channel_id"] = CS.XHeroSdkAgent.GetAppChannelId()
            dict["cdn"] = CS.XUriPrefix.PrimaryCdn[0]
            self.UpdateManager:DoRecord(dict, "80012", "DownloadNewFilesEnd")
            CS.XHeroSdkAgent.ApplogEvent("Resource_Download_End","")
        end
        self:OnFinish()
    end
end

function XModuleUpdateStateDownloadAb:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateDownloadAb:OnEnter()
    -- local isFix = self.UpdateManager:IsRepairFix()

    if self.ModuleUpdateInfo:IsMatrixUpdate() then
        self._updateSize = self.UpdateManager:GetTotalDownloadSize()
        -- 1:基础资源 2:完整资源
        local XLaunchDlcManager = require("XLaunchDlcManager")
        local downloadMode = XLaunchDlcManager.IsFullDownload() and 2 or 1
        local dict = {
            ["type"] = self.ModuleUpdateInfo.ResFileType,
            ["version"] = self.ModuleUpdateInfo:GetNewVersion(),
            ["size"] = self._updateSize,
            ["mode"] = downloadMode,
        }
        dict["app_channel_id"] = CS.XHeroSdkAgent.GetAppChannelId()
        dict["cdn"] = CS.XUriPrefix.PrimaryCdn[0]
        self.UpdateManager:DoRecord(dict, "80011", "StartDownloadNewFiles")

        self.START_TIME = os.time()
    end
    self.UpdateManager:DownloadABFiles(
        self.UpdateManager:GetDownloadABMap(), 
        self._FinishCallback)
end

return XModuleUpdateStateDownloadAb
