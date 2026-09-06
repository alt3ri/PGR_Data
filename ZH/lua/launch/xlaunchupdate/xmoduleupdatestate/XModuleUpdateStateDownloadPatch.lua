----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateDownloadPatch.lua
-- description: 模块更新 - 下载Patch文件
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsDirectory = CS.System.IO.Directory

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateDownloadPatch : XModuleUpdateStateBase
local XModuleUpdateStateDownloadPatch = XLaunchConst.CreateMetaTable("XModuleUpdateStateDownloadPatch", XModuleUpdateStateBase)

function XModuleUpdateStateDownloadPatch:Init()
    self._InfoFailCallback = function() self:OnEnter() end
    self._PatchFailCallback = function() self:_DownloadPatchFiles() end
    self._FinishCallback = function()
        local cost = self.UpdateManager:EndProfile("DownloadPatchFiles")
        local dict = {
            ["version"] = CS.XRemoteConfig.DocumentVersion,
            ["cnt"] = self._cnt,
            ["size"] = self._size,
            ["mode"] = "patch_download",
            ["time_cost"] = cost,
            ["svn_version"] = self.ModuleUpdateInfo:GetNewVersion(),
            ["is_preload"] = self.ModuleUpdateInfo:IsPredownloadStatus(),
        }
        self.UpdateManager:DoRecord(dict, "80039", "UpdateModulePatch")
        self:OnFinish()
    end
end

function XModuleUpdateStateDownloadPatch:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated() and not self.ModuleUpdateInfo:HasZipPatch()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateDownloadPatch:OnEnter()
    self:_DownloadPatchFiles()
end

-- 下载新的Patch文件
function XModuleUpdateStateDownloadPatch:_DownloadPatchFiles()
    local hasDownloaded = self.UpdateManager:IsNeedDownloadPatch()
    if not hasDownloaded then
        self:OnFinish()
        return
    end

    local DownloadPatch = self.ModuleUpdateInfo:GetDownloadPatchFilePath()
    if not CsDirectory.Exists(DownloadPatch) then
        CsDirectory.CreateDirectory(DownloadPatch)
    end

    local appendTaskFunction = function(group)
        self._cnt = 0
        self._size = 0
        local downloadPatchMap = self.UpdateManager:GetDownloadPatchMap()
        for _, patchInfo in pairs(downloadPatchMap) do
            local newVersion = patchInfo.NewVersion
            local oldVersion = patchInfo.OldVersion
            local sha1 = patchInfo.Sha1
            local size = patchInfo.Size
            local fileName = patchInfo.FileName
            local DocumentUrl = self.ModuleUpdateInfo:GetUrlByVersion(newVersion)
            local url = string.format("%s/%s/splitPatch/%s/Patch/%s.patch", DocumentUrl, newVersion, oldVersion, fileName)
            local path = string.format("%s/%s.patch", DownloadPatch, fileName)
            group:AddTask(url, path, size, sha1)
            self._size = self._size + size
            self._cnt = self._cnt + 1
        end
        CS.XLog.Debug(string.format("DownloadPatchFiles: totolSize = %s, DownloadPatch = %s",
            self._size, DownloadPatch))
        -- 下载patch提示
        CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._size)
        self.UpdateManager:UpdateProgress(0)
    end

    local dict = {
        ["version"] = CS.XRemoteConfig.DocumentVersion,
        ["cnt"] = self._cnt,
        ["size"] = self._size,
        ["mode"] = "patch_download_start",
        ["time_cost"] = 0,
        ["svn_version"] = self.ModuleUpdateInfo:GetNewVersion(),
        ["is_preload"] = self.ModuleUpdateInfo:IsPredownloadStatus(),
    }
    self.UpdateManager:DoRecord(dict, "80039", "UpdateModulePatch")
    self.UpdateManager:StartProfile("DownloadPatchFiles")
    self.UpdateManager:DownloadFiles(appendTaskFunction, 
        self._FinishCallback, nil, 
        function(percentage)
            self.UpdateManager:UpdateProgress(math.min(1, percentage))
        end, true, function(url)
            self.UpdateManager:WriteDownloadCache(url)
        end)
end

return XModuleUpdateStateDownloadPatch
