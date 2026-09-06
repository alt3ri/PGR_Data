----------------------------------------------------------------------------------------------------
-- XModuleUpdateStatePatchFilesApply.lua
-- description: 模块更新 - 应用Patch文件
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsLog = CS.XLog
local CsDirectory = CS.System.IO.Directory
local CsApplication = CS.XApplication

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStatePatchFilesApply : XModuleUpdateStateBase
local XModuleUpdateStatePatchFilesApply = XLaunchConst.CreateMetaTable("XModuleUpdateStatePatchFilesApply", XModuleUpdateStateBase)

function XModuleUpdateStatePatchFilesApply:IsEnter()
    -- 源目录索引，对应OnEnter中AddSrcDir的顺序
    local SRC_DIR_DOCUMENT = 0    -- 包外资源目录(document)
    local SRC_DIR_APPLICATION = 1 -- 包内资源目录(application)
    self._isMobile = CS.UnityEngine.Application.isMobilePlatform
    local allPatchMap = self.UpdateManager:GetPatchMap()
    self._totalPatchFileCount = 0
    self._patchMap = {}

    for fileName, patchInfo in pairs(allPatchMap) do
        if not self.UpdateManager:IsPatchFile(fileName) then
            -- patch的源是旧版本文件，必须用本地索引的旧sha1判断是否为包内资源
            local isOldInner = self.UpdateManager:IsInnerResourceByVersion(fileName, patchInfo.OldVersion)
            if self._isMobile and isOldInner then
                -- 旧文件信息缺失，或mobile平台包内文件(安卓包内为apk内部路径，native无法读取)：不patch，转整包下载
                self.UpdateManager:AddDownloadABMap(fileName)
            else
                self._patchMap[fileName] = isOldInner and SRC_DIR_APPLICATION or SRC_DIR_DOCUMENT
                self._totalPatchFileCount = self._totalPatchFileCount + 1
            end
        end
    end
    return self._totalPatchFileCount > 0
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStatePatchFilesApply:OnEnter()
    CsLog.Debug(string.format("OnEnter ApplyPatch %d files", self._totalPatchFileCount))
    local DownloadAbPath = self.ModuleUpdateInfo:GetDownloadAbFilePath()
    if not CsDirectory.Exists(DownloadAbPath) then
        CsDirectory.CreateDirectory(DownloadAbPath)
    end

    local DocumentFilePath = self.ModuleUpdateInfo:GetDocumentFilePath()
    -- 预下载合并路径不一样
    local DownloadPatchPath = self.ModuleUpdateInfo:GetMergePatchFilePath()
    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._totalPatchFileCount, false, CsApplication.GetText("ApplyPatch") .. "(%d/%d)") -- 解压资源
    self.UpdateManager:UpdateProgress(0)

    local hdiffManager = CS.HDiffPatch.HDiffManager.Instance
    local srcPath = string.format("%s/%s", DocumentFilePath, self.UpdateManager.ResFileType)
    hdiffManager:SetDirectories(srcPath, DownloadPatchPath, DownloadAbPath)

    local group = hdiffManager:CreateGroup()
    group:AddSrcDir(srcPath)
    group:AddSrcDir(self.ModuleUpdateInfo:GetApplicationFilePathWithType())

    local XFileInfoSizeIndex = XLaunchConst.XFileInfoSizeIndex
    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    self._cnt = 0
    self._size = 0
    for fileName, srcDirIndex in pairs(self._patchMap) do
        local info = self.UpdateManager:GetFileInfoByPath(fileName)
        local size = info[XFileInfoSizeIndex]
        local sha1 = info[XFileInfoSha1Index]
        -- 源目录已在IsEnter中根据旧文件位置确定，sha1/size为新版本信息用于产物校验
        group:AddTaskByFileName(fileName, sha1, size, srcDirIndex)
        self._cnt = self._cnt + 1
        self._size = self._size + size
    end
    group.OnVerifyProgressChanged = function(processedCnt, totalCount, groupId)
        self.UpdateManager:UpdateProgress(processedCnt / totalCount)
    end
    group.OnPatchProgressChanged = function(processedCnt, totalCount, groupId)
        self.UpdateManager:UpdateProgress(processedCnt / totalCount)
    end
    if not self.ModuleUpdateInfo:IsPredownloadDownloadStatus() then
        group.OnTaskCompleted = function(fileName)
            -- CsLog.Debug(string.format("ApplyPatch %s Finish", fileName))
            self.UpdateManager:WritePatchCache(fileName)
        end
    end
    if not self.ModuleUpdateInfo:IsPredownloadStatus() then
        group.OnTaskFailedCallback = function(fileName)
            -- CsLog.Debug(string.format("ApplyPatch %s Failed", fileName))
            self.UpdateManager:AddDownloadABMap(fileName)
        end
    end
    group.OnStateChanged = function(id, state)
        -- CsLog.Debug(string.format("ApplyPatch OnStateChanged %d", state))
        if state == 2 then
            CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._totalPatchFileCount, false, CsApplication.GetText("Verifying")) -- 解压资源
        end
        if state == 3 or state == 4 then
            local cost = self.UpdateManager:EndProfile("ApplyPatch")
            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["cnt"] = self._cnt,
                ["size"] = self._size,
                ["mode"] = "patch_apply",
                ["time_cost"] = cost,
                ["svn_version"] = self.ModuleUpdateInfo:GetNewVersion(),
                ["is_preload"] = self.ModuleUpdateInfo:IsPredownloadStatus(),
            }
            self.UpdateManager:DoRecord(dict, "80039", "UpdateModulePatch")
            CS.HDiffPatch.HDiffManager.Release()
            self:OnFinish()
        end
    end
    local dict = {
        ["version"] = CS.XRemoteConfig.DocumentVersion,
        ["cnt"] = self._cnt,
        ["size"] = self._size,
        ["mode"] = "patch_apply_start",
        ["time_cost"] = 0,
        ["svn_version"] = self.ModuleUpdateInfo:GetNewVersion(),
        ["is_preload"] = self.ModuleUpdateInfo:IsPredownloadStatus(),
    }
    self.UpdateManager:DoRecord(dict, "80039", "UpdateModulePatch")
    self.UpdateManager:StartProfile("ApplyPatch")
    hdiffManager:StartGroup(group)

    -- -- self._PatchFailFiles = {}
    -- local diffHelper = CS.HDiffPatch.HDiffPatchWrapper
    -- local applyCount = 0
    -- for fileName, patchInfo in pairs(patchMap) do
    --     applyCount = applyCount + 1
    --     local filename = patchInfo.FileName
    --     local originPath = string.format("%s/%s/%s", DocumentFilePath, self.UpdateManager.ResFileType, filename)
    --     local path = string.format("%s/%s.patch", DownloadPatchPath, filename)
    --     local newPath = string.format("%s/%s", DownloadAbPath, filename)
    --     local errorCode = diffHelper.ApplyPatch(originPath, path, newPath)
    --     self.UpdateManager:UpdateProgress(applyCount / self._totalPatchFileCount)
    --     -- CsLog.Debug(string.format("ApplyPatch %s %s %s %d", originPath, path, newPath, errorCode))
    --     if errorCode ~= 0 then
    --         -- self._PatchFailFiles[indexTableIndex] = true
    --         CsLog.Debug(string.format("ApplyPatch %s %s %s %d", originPath, path, newPath, errorCode))
    --         self.UpdateManager:AddDownloadABMap(fileName)
    --     else
    --         self.UpdateManager:WritePatchCache(newPath)
    --     end
    -- end
    -- -- playerprefs记录
    -- self:OnFinish()
end

return XModuleUpdateStatePatchFilesApply
