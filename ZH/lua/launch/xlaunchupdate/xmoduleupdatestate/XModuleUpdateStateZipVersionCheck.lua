----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateZipVersionCheck.lua
-- description: 模块更新 - 检查Zip版本
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsLog = CS.XLog
local CsApplication = CS.XApplication
local CsFile = CS.System.IO.File
local CsDirectory = CS.System.IO.Directory

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateZipVersionCheck : XModuleUpdateStateBase
local XModuleUpdateStateZipVersionCheck = XLaunchConst.CreateMetaTable("XModuleUpdateStateZipVersionCheck", XModuleUpdateStateBase)

function XModuleUpdateStateZipVersionCheck:Init()
    if self.ModuleUpdateInfo:HasUpdated() then
        self._DownloadCacheFile = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName("ZipVersionDownload_" .. self.ModuleUpdateInfo:GetNewVersion())
        self._UnzipCacheFile = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName("ZipVersionUnzip_" .. self.ModuleUpdateInfo:GetNewVersion())
        self._ZipInfoDownloadFailCallback = function() self:OnEnter() end
        self._ZipInfoDownloadFinishCallback = function() self:_DownloadZipFiles() end
        self._DownloadHDiffZipInfoFilesCallback = function() self:_DownloadHDiffZipInfoFiles() end
        self._DownloadFinishCallback = function()
            local cost = self.UpdateManager:EndProfile("DownloadUnzipFiles")
            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["cnt"] = self._zipCnt,
                ["size"] = self._zipTotalSize,
                ["mode"] = "zip_download",
                ["time_cost"] = cost,
            }
            self.UpdateManager:DoRecord(dict, "80038", "UpdateModuleZip")
            XLaunchConst.WriteAllText(self._DownloadCacheFile, "")
            self:_StartUnzipFiles()
        end
        self._IsUpzipFinish = XLaunchConst.FileExists(self._UnzipCacheFile)
    end
end

function XModuleUpdateStateZipVersionCheck:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateZipVersionCheck:OnEnter()
    local XLaunchDlcManager = require("XLaunchDlcManager")
    if XLaunchDlcManager.NeedShowSelect() then
        self:OnFinish()
        return
    end

    local isZipPatch = self.ModuleUpdateInfo:IsZipPatchVersion()
    if isZipPatch then
        self.ModuleUpdateInfo:SetZipPatchStatue(true)
        self:_DownloadHDiffZipInfoFiles()
        return
    end
    self:OnFinish()
end

-- 下载splitPatch json
function XModuleUpdateStateZipVersionCheck:_DownloadHDiffZipInfoFiles()
    local zipDir = self.ModuleUpdateInfo:GetDownloadZipFilePath()
    if not CsDirectory.Exists(zipDir) then
        CsDirectory.CreateDirectory(zipDir)
    end

    local downloadZipListInfoFileName = string.format("HDiffZipInfo_%s.json", self.ModuleUpdateInfo:GetNewVersion())
    self._zipListInfoDownloadPath = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName(downloadZipListInfoFileName)
    if CsFile.Exists(self._zipListInfoDownloadPath) then
        self:_DownloadZipFiles()
        return
    end

    local zipListInfoPrefixUrl = self.ModuleUpdateInfo:GetZipPathParentUrl("HDiffZipInfo.json")
    local addTaskFunc = function(group)
        group:AddTask(zipListInfoPrefixUrl, self._zipListInfoDownloadPath)
    end
    self.UpdateManager:DownloadFiles(addTaskFunc, 
        self._ZipInfoDownloadFinishCallback, self._DownloadHDiffZipInfoFilesCallback, 
        nil, true)
end

-- 下载Zip
function XModuleUpdateStateZipVersionCheck:_DownloadZipFiles()
    local zipInfo = XLaunchConst.LoadJsonFile(self._zipListInfoDownloadPath)
    if not zipInfo then
        CsFile.Delete(self._zipListInfoDownloadPath)
        self:_DownloadHDiffZipInfoFiles()
        return
    end

    if not next(zipInfo) then
        self:OnFinish()
        return
    end

    local count = 0
    self._upzipIndex = 0
    self._unzipList = {}
    for fileName, _ in pairs(zipInfo) do
        local downloadPath = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName(fileName)
        count = count + 1
        self._unzipList[count] = downloadPath
    end

    if XLaunchConst.FileExists(self._DownloadCacheFile) then
        self:_StartUnzipFiles()
        return
    end
    local totalSize = 0
    for _, info in pairs(zipInfo) do
        totalSize = totalSize + info.Size
    end
    XLaunchConst.BeforeDownloadTips(totalSize, function() self:_StartDownload(zipInfo) end)
end

function XModuleUpdateStateZipVersionCheck:_StartDownload(zipInfo)
    -- 检测本地和解压进度，加压到一半杀进程
    local appendTaskFunction = function(group)
        self._zipCnt = 0
        self._zipTotalSize = 0
        for fileName, info in pairs(zipInfo) do
            local url = self.ModuleUpdateInfo:GetZipPathParentUrl(fileName)
            local downloadPath = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName(fileName)
            self._zipTotalSize = self._zipTotalSize + info.Size
            self._zipCnt = self._zipCnt + 1
            group:AddTask(url, downloadPath, info.Size, info.Sha1, false, true)
        end
        CS.XLog.Debug(string.format("[Download] StartDownload zip files, totalSize:%s", self._zipTotalSize))
        CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._zipTotalSize)
    end
    self.UpdateManager:StartProfile("DownloadUnzipFiles")
    self.UpdateManager:DownloadFiles(appendTaskFunction, self._DownloadFinishCallback, nil, nil, true)
end

function XModuleUpdateStateZipVersionCheck:_StartUnzipFiles()
    self.UpdateManager:StartProfile("UnzipFiles")
    self:_UnzipFilesMultiThread()
end

function XModuleUpdateStateZipVersionCheck:_UnzipFilesMultiThread()
    local zipDir = self.ModuleUpdateInfo:GetDownloadZipFilePath()
    local unzipManager = CS.XHaruUnzip.XUnzipManager()
    unzipManager.OnTotalProgress = function(progress)
        self.UpdateManager:UpdateProgress(progress)
    end
    unzipManager.OnFileUnzipped = function(taskName, filePath)
        self.UpdateManager:WriteDownloadCache(filePath)
    end
    unzipManager.OnStateChanged = function(state)
        if state == 2 or state == 3 then
            local cost = self.UpdateManager:EndProfile("UnzipFiles")
            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["cnt"] = self._zipCnt,
                ["mode"] = "zip_unzip",
                ["time_cost"] = cost,
            }
            self.UpdateManager:DoRecord(dict, "80038", "UpdateModuleZip")
            if CsDirectory.Exists(zipDir) then
                CsDirectory.Delete(zipDir, true)
            end
            self:OnFinish()
        end
    end
    unzipManager.OnZipFinished = function(zipName)
        -- 嵌套任务名为"外层名!子zip名", 不在zipPathMap里, 天然跳过删除
        local zipPath = zipDir .. "/" .. zipName
        CsLog.Debug(string.format("[Unzip] Completed file:%s", tostring(zipPath or zipName)))
        if CsFile.Exists(zipPath) then
            CsFile.Delete(zipPath)
        end
    end
    
    local unzipPath = self.ModuleUpdateInfo:GetMergePatchFilePath()
    local password = nil
    self._zipCnt = 0
    for _, zipPath in pairs(self._unzipList) do
        self._zipCnt = self._zipCnt + 1
        unzipManager:AddTask(zipPath, unzipPath, password)
    end
    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._zipCnt, false, CsApplication.GetText("Unzip") .. "(%d/%d)") -- 解压资源
    self.UpdateManager:UpdateProgress(0)
    unzipManager:Start()
end

-- -- 解压文件
-- function XModuleUpdateStateZipVersionCheck:_UnzipFiles()
--     self._upzipIndex = self._upzipIndex + 1
--     local downloadPath = self._unzipList[self._upzipIndex]
--     if not downloadPath or self._IsUpzipFinish then
--         XLaunchConst.WriteAllText(self._UnzipCacheFile, "")
--         self._unzipList = nil
--         self.UpdateManager:EndProfile("UnzipFiles")
--         self:OnFinish()
--         return
--     end

--     local unzipPath = self.ModuleUpdateInfo:GetMergePatchFilePath()
--     local overwrite = true
--     local password = nil
--     local totalCount = CS.ZipUtility.GetZipEntityCount(downloadPath, password)
--     local progressCB = function(counter, name)
--         local progress = counter / totalCount
--         self.UpdateManager:UpdateProgress(progress)
--         -- CsLog.Debug(string.format("[Unzip] Progress file:%s, counter:%s, name:%s, progress:%s", tostring(downloadPath), counter, name, progress))
--         self.UpdateManager:WriteDownloadCache(name)
--     end

--     local finishCB = function(counter)
--         CsLog.Debug("解压完成", counter)
--         if counter >= 1 then
--             CsLog.Debug(string.format("[Unzip] Completed file:%s", tostring(downloadPath)))
--             -- 递归处理下一个文件，列表在全部完成后由 OnFinish 路径清理
--             self:_UnzipFiles()
--         end
--     end
--     CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, false, CsApplication.GetText("Unzip") .. "(%d/%d)") -- 解压资源
--     self.UpdateManager:UpdateProgress(0)
--     CS.ZipUtility.UnzipFile(downloadPath, unzipPath, progressCB, finishCB, overwrite, password)
-- end

return XModuleUpdateStateZipVersionCheck
