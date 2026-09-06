----------------------------------------------------------------------------------------------------
-- XApkDownloadManager.lua
-- description: Apk下载管理器，只处理apk下载内容，下载完结束进程退出
-- Created by liang qian
-- -------------------------------------------------------------------------------------------------

local CsApplication = CS.XApplication
local CsRemoteConfig = CS.XRemoteConfig
local CsInfo = CS.XInfo
local CsLog = CS.XLog
local CsTool = CS.XTool
local CsStringEx = CS.XStringEx
local IO = CS.System.IO
local CsGameEventManager = CS.XGameEventManager.Instance

---@class XApkDownloadManager
local XApkDownloadManager = {}
local target = XApkDownloadManager

-- 初始化
XApkDownloadManager.Init = function()
    target.APK_TIMEOUT = 5000
    target.ApkFileSize = 0
    target.ApkSavePath = XLaunchConst.GetApkSavePath()
    -- target.IsApkTesting = true -- 调试用
end

-- 下载前预处理，获取apk大小并开始下载
XApkDownloadManager.BeforeDownloadApk = function (apkUrl)
    CsLog.Debug("[Apk] - Start Downloading Apk:" .. apkUrl)
    local request = CS.UnityEngine.Networking.UnityWebRequest.Head(apkUrl)
    request.timeout = target.APK_TIMEOUT
    CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError or request.isHttpError then
            CsLog.Error("[Apk] - Request ApkUrl error:" .. tostring(request.error))
            XLaunchConst.ShowStartErrorDialog("DownloadAPKError", function()
                XApkDownloadManager.BeforeDownloadApk(apkUrl)
            end)
            return
        end

        target.ApkFileSize = request:GetResponseHeader("Content-Length")
        CsLog.Debug("[Apk] - Request ApkFileSize is " .. tostring(target.ApkFileSize))
        target.ApkFileSize = tonumber(target.ApkFileSize)
        XApkDownloadManager.StartDownloadApk(apkUrl)
    end)
end

-- 下载入口，找下载地址（纯入口），寻找可在包内强更url，调用downloadCB下载接口，否则调用jumpCB跳转外链下载
XApkDownloadManager.TryDownloadApk = function (downloadCB, jumpCB)
    -- 是否支持下载的渠道
    local isDownloadChannel = XLaunchConst.CheckDownloadChannel()
    if not isDownloadChannel then
    -- if not target.IsApkTesting and not isDownloadChannel then
        jumpCB()
        return
    end

    local DOWNLOAD_APK_VERSION = "download_apk_ver"
    local ApkListUrl = "client/patch/config.js"
    -- 清理过期的下载临时文件
    local curVersion = CsRemoteConfig.ApplicationVersion
    local tempFile = target.ApkSavePath .. ".download"
    if IO.File.Exists(tempFile) then
        local lastDownloadVersion = CS.UnityEngine.PlayerPrefs.GetString(DOWNLOAD_APK_VERSION, "")
        CsLog.Debug("[APK] - Last down load versin:" .. lastDownloadVersion .. ", current:" .. curVersion)
        if lastDownloadVersion ~= curVersion then
            CS.XFileTool.DeleteFile(tempFile)
        end
    end
    CS.UnityEngine.PlayerPrefs.SetString(DOWNLOAD_APK_VERSION, curVersion)
    CS.UnityEngine.PlayerPrefs.Save()

    local channelId = CS.XHeroSdkAgent.GetChannelId()
    -- local channelId = target.IsApkTesting and XLaunchConst.GetOppoChannelID() or CS.XHeroSdkAgent.GetChannelId()
    local request = CS.XUriPrefixRequest.Get(ApkListUrl, nil, target.APK_TIMEOUT) 
    CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError or request.isHttpError or not request.downloadHandler then
            CsLog.Error("[Apk] - Request apkList error:" .. tostring(request.error))
            jumpCB()
            return
        end

        local content = request.downloadHandler.text
        local url = nil
        for k, v in string.gmatch(content, "\"(%d+)\" : \"(.-)\"") do
            local cid = tonumber(k)
            if cid == channelId then
                url = v
                break
            end
        end

        if url then
            downloadCB(url)
        else
            jumpCB()
        end
    end)
end

-- 开始下载apk, 检测本地同步进度
XApkDownloadManager.StartDownloadApk = function (apkUrl)
    CsLog.Debug("[Apk] - Start to download.")
    local apkFileSize = target.ApkFileSize
    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, apkFileSize)

    local cache = true
    local sha1 = nil
    local keepEverythingGoing = -1
    local downloader = CS.XDownloader(2, apkUrl, target.ApkSavePath, cache, sha1, keepEverythingGoing, target.APK_TIMEOUT)

    local isDownloading = false
    CS.XTool.WaitCoroutinePerFrame(downloader:Send(), function(isComplete)
        if not isComplete then
            if not isDownloading then
                isDownloading = true
                CsLog.Debug("[Apk] - Init Download Apk Info:",  downloader.CurrentSize, apkFileSize)
                CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, apkFileSize)
            end

            local downloadedSize = downloader.CurrentSize
            local progress = downloadedSize / apkFileSize
            CsApplication.SetProgress(progress)
        else
            local localFileSize = 0
            if isDownloading then
                localFileSize = downloader.CurrentSize
            elseif IO.File.Exists(target.ApkSavePath) then
                local fs = IO.File.Open(target.ApkSavePath, IO.FileMode.Open, IO.FileAccess.Read, IO.FileShare.Read)
                localFileSize = tonumber(fs.Length)
                fs:Close()
            end

            local isFinish = (localFileSize == apkFileSize)
            CsLog.Debug("[Apk] - Finish Download:" .. tostring(downloader.State) .. ",  localFileSize:" .. localFileSize.. ",  Size:" .. apkFileSize .. ", isFinish:" .. tostring(isFinish))
            if not isFinish then
                if isDownloading then -- 下载过程失败才询问
                    XLaunchConst.ShowStartErrorDialog("DownloadAPKError", function()
                        XApkDownloadManager.CleanAndDownload(apkUrl)
                    end, CsApplication.Exit)
                else
                    XApkDownloadManager.CleanAndDownload(apkUrl)
                end
                return
            end

            if downloader.State ~= CS.XDownloaderState.Success then
                CsLog.Error("[Apk] - Download Error state:" .. tostring(downloader.State) .. ", Exception:" .. tostring(downloader.Exception and downloader.Exception.Message))
                XLaunchConst.ShowStartErrorDialog("DownloadAPKError", function()
                    XApkDownloadManager.StartDownloadApk(apkUrl)
                end)
                return
            end

            CsApplication.SetProgress(1)
            CS.XTool.OpenFile(target.ApkSavePath, function(result)
                CsLog.Debug("[Apk] - Open File result:" .. tostring(result))
                CsApplication.Exit()
            end)
        end
    end)
end

-- 删除下载文件，重新下载
XApkDownloadManager.CleanAndDownload = function (apkUrl)
    if IO.File.Exists(target.ApkSavePath) then
        CsLog.Debug("[Apk] - Clean downloaded Error File:" .. target.ApkSavePath)
        CS.XFileTool.DeleteFile(target.ApkSavePath)
    end
    XApkDownloadManager.StartDownloadApk(apkUrl)
end

-- 下载失败
XApkDownloadManager.DownloadFail = function()
    CsLog.Debug("[Apk] - Failed to Download Apk.")
    CsTool.WaitCoroutine(CsApplication.GoToUpdateURL(XLaunchConst.GetAppUpgradeUrl()), nil)
end

-- 尝试下载, 游戏内强更
XApkDownloadManager.Download = function()
    -- 尝试下载
    XApkDownloadManager.TryDownloadApk(XApkDownloadManager.BeforeDownloadApk, XApkDownloadManager.DownloadFail)
end

-- apk 下载执行流程
XApkDownloadManager.Execute = function ()
    -- 提示更新，下载更新
    CsTool.WaitCoroutine(
        CsApplication.CoDialog(CsApplication.GetText("Tip"), 
            CsStringEx.Format(CsApplication.GetText("UpdateApplication"), CsInfo.Version),
            nil,
            XApkDownloadManager.Download
        )
    )
end

return XApkDownloadManager
