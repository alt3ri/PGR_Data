----------------------------------------------------------------------------------------------------
-- XUpdateDownloader.lua
-- description: 模块更新下载器，封装下载、缓存读写和清理逻辑
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsApplication = CS.XApplication
local StringFormat = string.format
local CsLog = CS.XLog
local pairs = pairs
local next = next

---@class XUpdateDownloader
---@field New fun(...): XUpdateDownloader 创建对象
---@field _DownloadCache table<string, boolean>|nil 已下载文件缓存
---@field _Writer file*|nil 缓存文件写入句柄
---@field DownloadManager CS.XHaruDownloader.XDownloadManager|nil
---@field DownloadGroup CS.XHaruDownloader.XDownloadTaskGroup|nil
local XUpdateDownloader = XLaunchConst.CreateMetaTable("XUpdateDownloader")

function XUpdateDownloader:Ctor()
    self._ShowProgress = true
    self._DefaultProgressCb = function(p)
        if self._ShowProgress then
            if self._ProgressCb then
                self._ProgressCb(p)
                return
            end
            CsApplication.SetProgress(p)
        end
    end
end

function XUpdateDownloader:SetProgressCallback(cb)
    self._ProgressCb = cb
end

function XUpdateDownloader:SetShowProgress(isShow)
    self._ShowProgress = isShow
end

function XUpdateDownloader:SetSingleFileDownloadFinishCb(cb)
    self._DefaultSingleFileDownloadFinishCb = cb
end

-- region 下载接口

-- 下载AB文件
---@param downloadFiles table 下载文件表
---@param finishCB function 完成回调
---@param moduleUpdateInfo XModuleUpdateInfo 模块更新信息
---@param resFileType string 模块类型
function XUpdateDownloader:DownloadABFiles(downloadFiles, finishCB, moduleUpdateInfo, isTargetPath)
    if not downloadFiles or not next(downloadFiles) then
        -- CsLog.Debug("DownloadABFiles: downloadFiles is empty")
        if finishCB then finishCB() end
        return
    end

    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local XFileInfoSizeIndex = XLaunchConst.XFileInfoSizeIndex
    local XFileInfoVersionIndex = XLaunchConst.XFileInfoVersionIndex
    local resFileType = moduleUpdateInfo.ResFileType
    local savePath
    if isTargetPath then
        savePath = moduleUpdateInfo:GetDocumentFilePathWithResType()
    else
        savePath = moduleUpdateInfo:GetDownloadAbFilePath()
    end

    local appendTaskFunction = function(group)
        local totalsize = 0
        for fileName, newInfo in pairs(downloadFiles) do
            local sha1 = newInfo[XFileInfoSha1Index]
            local size = newInfo[XFileInfoSizeIndex]
            local version = newInfo[XFileInfoVersionIndex]
            local DocumentUrl = moduleUpdateInfo:GetUrlByVersion(version)
            local url = StringFormat("%s/%s/%s/%s", DocumentUrl, version, resFileType, fileName)
            local path = StringFormat("%s/%s", savePath, fileName)
            group:AddTask(url, path, size, sha1)
            totalsize = totalsize + size
        end

        CsLog.Debug(string.format("DownloadABFiles: totalsize = %s, savePath = %s", 
            totalsize, savePath))
        if self._ShowProgress then
            CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalsize)
        end
    end

    self:DownloadFiles(appendTaskFunction,
        finishCB, nil, 
        self._DefaultProgressCb, true, 
        self._DefaultSingleFileDownloadFinishCb)
end

-- 下载文件
---@param addTaskCb function|nil 添加任务回调
---@param finishCb function|nil 完成回调
---@param failCb function|nil 失败回调
---@param progressCb function|nil 进度回调
---@param autoStart boolean 是否自动开始
---@param fileFinishCb function|nil 单文件完成回调
---@return CS.XHaruDownloader.XDownloadManager, CS.XHaruDownloader.XDownloadTaskGroup
function XUpdateDownloader:DownloadFiles(addTaskCb, finishCb, failCb, progressCb, autoStart, fileFinishCb)
    if not self.DownloadManager then
        self.DownloadManager = CS.XHaruDownloader.XDownloadManager()
        self.DownloadManager:Init()
    end
    if self.DownloadGroup then
        if self.DownloadManager.Clear then
            -- 会移除group数据
            self.DownloadManager:Clear()
        end
    end
    local groupId = 999
    if not self.DownloadGroup then
        self.DownloadGroup = CS.XHaruDownloader.XDownloadTaskGroup(groupId)
    end
    if addTaskCb then addTaskCb(self.DownloadGroup) end

    local time = CS.UnityEngine.Time.realtimeSinceStartup
    self.DownloadGroup.NotifyStateChanged = function(id, state)
        if state == XLaunchConst.TaskGroupStateComplete then
            if finishCb then
                CS.XLog.Debug(StringFormat("DownloadFiles: finish cost time = %.2f", CS.UnityEngine.Time.realtimeSinceStartup - time))
                finishCb()
            end
        elseif state == XLaunchConst.TaskGroupStateCompleteError then
            if failCb then
                if self.DownloadManager.Clear then
                    self.DownloadManager:Clear()
                end
                failCb(self.DownloadManager)
            else
                XLaunchConst.ShowStartErrorDialog("FileManagerInitFileTableDownloadError", nil, function()
                    self.DownloadManager:ResetAllFailedTask()
                end, CsApplication.GetText("Retry")) -- 重试
            end
        end
    end
    local proCb = progressCb or self._DefaultProgressCb
    self.DownloadGroup.NotifyProgressChanged = function(percentage, id)
        -- CsLog.Debug(StringFormat("NotifyProgressChanged id:%s, progress:%.6f", tostring(id), percentage))
        proCb(percentage, id)
    end
    proCb(0, groupId)
    self.DownloadGroup.NotifyUrlDownloadFinish = fileFinishCb

    -- 注册
    self.DownloadManager:RegisterTaskGroup(self.DownloadGroup)
    if autoStart then
        self.DownloadManager:StartAll()
    end
    return self.DownloadManager, self.DownloadGroup
end

-- endregion

-- region 清理

-- 清理下载相关资源（缓存、回调、C#对象）
function XUpdateDownloader:Clear()
    -- 清理下载回调
    if self.DownloadGroup then
        self.DownloadGroup.NotifyStateChanged = nil
        self.DownloadGroup.NotifyProgressChanged = nil
        self.DownloadGroup.NotifyUrlDownloadFinish = nil
        self.DownloadGroup = nil
    end

    -- 清理下载管理器（先停止再释放，避免C#侧线程/HttpClient泄漏）
    if self.DownloadManager then
        self.DownloadManager:Stop()
        self.DownloadManager = nil
    end
end

-- endregion

return XUpdateDownloader
