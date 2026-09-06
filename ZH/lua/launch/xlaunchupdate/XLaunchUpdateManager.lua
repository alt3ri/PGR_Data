----------------------------------------------------------------------------------------------------
-- XLaunchUpdateManager.lua
-- description: 更新流程
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

require("XLaunchUpdate/XLaunchUpdatePlatform")

local CsApplication = CS.XApplication
local CsRemoteConfig = CS.XRemoteConfig
local CsInfo = CS.XInfo
local CsLog = CS.XLog
local CsTool = CS.XTool
local CsStringEx = CS.XStringEx
local IO = CS.System.IO
local CsFile = IO.File
local CsDirectory = IO.Directory

local MAX_VERSION_FILE_RETRY_COUNT = 3

---@class XLaunchUpdateManager
---@field NeedLaunchTest boolean 是否需要启动测试
---@field IsReloaded boolean 是否是重新加载
---@field IsEditorOrStandalone boolean 是否是编辑器或Standalone
---@field ProcessFuncList function[] 流程函数列表
---@field ProcessFuncIndex number 当前流程索引
local XLaunchUpdateManager = XLaunchConst.CreateMetaTable("XLaunchUpdateManager")

-- 初始化
function XLaunchUpdateManager:Ctor()
    self.IsUpdateVersion2 = true
    self.NeedLaunchTest = CS.XResourceManager.NeedLaunchTest
    local info = XLaunchUpdatePlatform.GetPlatformInfo()
    self.IsEditorOrStandalone = info.IsEditorOrStandalone
    -- 更新流程
    local appVersion = CsInfo.Version
    if not XLaunchConst.ForceUpdate then
        self._IsSkipUpdate = appVersion == CsRemoteConfig.DocumentVersion and appVersion == CsRemoteConfig.LaunchModuleVersion
    else
        self._IsSkipUpdate = false
    end
    CS.XLog.Debug(string.format("appVersion:%s, DocumentVersion:%s, LaunchModuleVersion:%s IsSkipUpdate:%s", 
        appVersion, CsRemoteConfig.DocumentVersion, CsRemoteConfig.LaunchModuleVersion, self._IsSkipUpdate))

    self._DocFilePath = info.DocumentFilePath
    self._VersionPath = string.format("%s/ver", self._DocFilePath)
    self._Client2CdnPath = string.format("%s/client2cdn", self._DocFilePath)
    if CS.XApplication.Debug then
        local time = os.time()
        self._VersionUrl = string.format("%s/LastBuildVersion.json?%s", info.DocumentUrl, time)
        self._Client2CdnUrl = string.format("%s/Client2Cdn.json?%s", info.DocumentUrl, time)
    else
        self._VersionUrl = string.format("%s/LastBuildVersion.json", info.DocumentUrl)
        self._Client2CdnUrl = string.format("%s/Client2Cdn.json", info.DocumentUrl)
    end

    self._NextFunc = function(...) self:NextTask(...) end

    self._WarmUpShaderCallback = function(eventName, params)
        local isSkip = false
        if params.Length > 0 then
            isSkip = params[0]
        end
        self:DoShaderWarmUp(isSkip)
    end
    CS.XGameEventManager.Instance:RegisterEvent(XLaunchConst.EVENT_SHADER_WARM_UP, self._WarmUpShaderCallback)
end

-- region 模块流程

-- 检查更新更新入口 Main
function XLaunchUpdateManager:CheckUpdate(isReloaded)
    self.IsReloaded = isReloaded or false
    -- 检测App更新
    if XLaunchConst.CheckAppUpdate() then
        -- Pc模式
        if CS.XUiPc.XUiPcManager.IsPcMode() then
            -- 云游戏
            if CS.XInfo.IsCloudGame then 
                -- 退出
                CS.XWLinkAgent.Exit(CsApplication.GetText("CloudGameUpdateApplication"))
            else
                -- 提示更新，退出应用
                CsTool.WaitCoroutine(
                    CsApplication.CoDialog(
                        CsApplication.GetText("Tip"),
                        CsStringEx.Format(CsApplication.GetText("PCUpdateApplication"),
                        CsInfo.Version),
                    nil, 
                    CsApplication.Exit)
                )
            end
        else
            -- 提示更新，下载更新
            local apkDownloadManager = require("XLaunchUpdate/XApkDownloadManager")
            apkDownloadManager.Init()
            apkDownloadManager.Execute()
        end
    else
        -- 无需更新App，并删除本地下载的Apk（更新后重启的清理）
        if XLaunchConst.CheckDownloadChannel() then
            local apkSavePath = XLaunchConst.GetApkSavePath()
            if CsFile.Exists(apkSavePath) then
                CsLog.Debug("[Apk] - Clean Apk path:" .. apkSavePath)
                CS.XFileTool.DeleteFile(apkSavePath)
            end
        end

        -- 更新流程
        self:StartUpdateLoop()
    end
end

-- 开始更新流程
function XLaunchUpdateManager:StartUpdateLoop()
    -- 编辑器模式只需要直接进入，不需要走ab数据
    if CsApplication.Mode == CS.XMode.Editor and not self.NeedLaunchTest then
        self.ProcessFuncList = {
            self.UpdateMatrixModule,                -- 更新游戏模块
            self.InitGame,                          -- 初始化游戏
            self.EndTask,                           -- 结束任务
        }
    else
        -- 更新流程列表
        self.ProcessFuncList = {
            self.StartTask,                         -- 启动任务
            self.MajorVersionCheck,                 -- 大版本检查任务
            self.UnzipLocalFile,                    -- Debug包解压本地压缩包
            self.RemoteVersionFile,                 -- 下载版本文件
            self.TestDebugModule,                   -- 测试Debug模块
            self.UpdateLaunchModule,                -- 更新启动模块
            self.PreloadMaxtrixModule,              -- 预加载游戏模块
            self.PreUpdateMatrixModule,             -- 更新前的临时版本清理
            self.UpdateMatrixModule,                -- 更新游戏模块
            self.InjectFixEngineInit,               -- 注入修复引擎初始化
            self.ShaderWarmUpTask,                  -- 预热Shader
            self.InitGame,                          -- 初始化游戏
            self.EndTask,                           -- 结束任务
        }
    end
    
    self.ProcessFuncIndex = 0
    self:NextTask()
end

function XLaunchUpdateManager:GetCurrentTime()
    return CS.UnityEngine.Time.realtimeSinceStartup
end

-- 下一个任务事件
function XLaunchUpdateManager:NextTask()
    self.ProcessFuncIndex = self.ProcessFuncIndex + 1
    local launchUpdateManagerTaskFunc = self.ProcessFuncList[self.ProcessFuncIndex]
    if launchUpdateManagerTaskFunc then
        -- 延迟执行
        CS.XScheduleManager.ScheduleNextFrame(function()
            launchUpdateManagerTaskFunc(self)
        end, "XLaunchUpdateManager")
    end
end

-- 开始任务 初始化数据
function XLaunchUpdateManager:StartTask()
    self._ProfileTimeStart = self:GetCurrentTime()
    self:NextTask()
end

-- 结束任务 清理数据
function XLaunchUpdateManager:EndTask()
    collectgarbage("collect")
end

-- endregion

-- region 具体任务实现

-- 大版本检查任务（删除旧版本doc）
function XLaunchUpdateManager:MajorVersionCheck()
    if XLaunchConst.IsUpdateClose then
        self:NextTask()
        return
    end

    local majorVersionKey = "MajorVersion"
    local majorVersion = CS.UnityEngine.PlayerPrefs.GetString(majorVersionKey, "")
    -- local majorVersionPath = string.format("%s/remove_cache", self._DocFilePath)
    -- if not CsFile.Exists(majorVersionPath) then
    --     XLaunchConst.WriteAllText(majorVersionPath, "1")
    if majorVersion == "" then
        local launchDoc = string.format("%s/launch", self._DocFilePath)
        if CsDirectory.Exists(launchDoc) then
            CsDirectory.Delete(launchDoc, true)
        end
        local matrixDoc = string.format("%s/matrix", self._DocFilePath)
        if CsDirectory.Exists(matrixDoc) then
            CsDirectory.Delete(matrixDoc, true)
        end
    end
    CS.UnityEngine.PlayerPrefs.SetString(majorVersionKey, CsInfo.Version)
    CS.UnityEngine.PlayerPrefs.Save()
    self:NextTask()
end

-- 获取更新模块信息
function XLaunchUpdateManager:UseUpdateModule(resFileType)
    local XModuleUpdateManager = require("XLaunchUpdate/XModuleUpdateManager")
    local updateModuleManager = XModuleUpdateManager.New()
    updateModuleManager:Init(resFileType, self._NextFunc, self.IsReloaded)
    updateModuleManager:Execute(self.IsReloaded)
end

-- 检查本地压缩包
function XLaunchUpdateManager:CheckLocalZipFile(finishUnzipCb)
    if not CsRemoteConfig.Debug then
        finishUnzipCb()
        return
    end
    local documentPath = CS.UnityEngine.Application.persistentDataPath .. "/document"
    if not CsDirectory.Exists(documentPath) then
        finishUnzipCb()
        return
    end

    local files = CsDirectory.GetFiles(documentPath, "*.zip", CS.System.IO.SearchOption.TopDirectoryOnly)
    CsLog.Debug(string.format("[Unzip] DocumentPath:%s, files.length:%s", tostring(documentPath), tostring(files.Length)))
    local length = files.Length
    local function UnzipFile(index)
        if index >= length then
            if index > 0 then
                CsApplication.SetProgress(1)
                CsLog.Debug("[Unzip] Finished.")
            end
            finishUnzipCb()
            return
        end
        local file = files[index]
        local nextIndex = index + 1
        if string.find(file, "source") then
            local overwrite = true
            local password = nil
            local totalCount = CS.ZipUtility.GetZipEntityCount(file, password)
            CsLog.Debug(string.format("[Unzip] Start File: %s", tostring(file)))

            if (totalCount > 0) then
                local cancelCB = function()
                    UnzipFile(nextIndex)
                end
                local confirmCB = function()
                    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, false, CsApplication.GetText("Unzip") .. "(%d/%d)") -- 解压资源
                    CsApplication.SetProgress(0)

                    local progressCB = function(counter, name)
                        local progress = counter / totalCount
                        CsApplication.SetProgress(progress)

                        CsLog.Debug(string.format("[Unzip]  progress:%s/%s, name:%s, zipFile: %s, outputPath:%s", 
                            tostring(counter), tostring(totalCount), tostring(name), tostring(file), tostring(documentPath)))
                    end

                    local finishCB = function(counter)
                        if counter >= totalCount then
                            CsLog.Debug(string.format("[Unzip] Completed file:%s", tostring(file)))
                            CS.XFileTool.DeleteFile(file)
                            UnzipFile(nextIndex)
                        end
                    end
                    CS.ZipUtility.UnzipFile(file, documentPath, progressCB, finishCB, overwrite, password)
                end
                local text = string.format("检查到本地压缩文件%s, 是否进行解压?", CS.XFileTool.GetFileNameWithoutExtension(file))
                CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), text, cancelCB, confirmCB))
            else
                CsLog.Debug(string.format("[Unzip] count <= 0, zipFile: %s", tostring(file)))
                UnzipFile(nextIndex)
            end
        else
            CsLog.Debug(string.format("[Unzip] name not Contains 'source', zipFile: %s", tostring(file)))
            UnzipFile(nextIndex)
        end
    end
    UnzipFile(0)
end

-- 压缩模块检测
function XLaunchUpdateManager:UnzipLocalFile()
    local XLaunchLocalZipUnzip = require("XLaunchUpdate/XLaunchLocalZipUnzip")
    XLaunchLocalZipUnzip.Run(self._NextFunc)
end

-- 初始化版本文件
function XLaunchUpdateManager:InitVersionFile()
    local jsonData = XLaunchConst.LoadJsonFile(self._VersionPath)
    local jsonDataClient2Cdn = XLaunchConst.LoadJsonFile(self._Client2CdnPath)
    local needUpdateAgain = false
    if not jsonData then
        CS.XLog.Error("[XLaunchUpdateManager] InitVersionFile jsonData is nil")
        needUpdateAgain = true
    end
    if not jsonDataClient2Cdn then
        CS.XLog.Error("[XLaunchUpdateManager] InitVersionFile jsonDataClient2Cdn is nil")
        needUpdateAgain = true
    end
    if needUpdateAgain then
        self:RemoteVersionFile(true)
        return
    end

    XLaunchConst.LeastLaunchVersion = jsonData.LeastLaunchVersion
    XLaunchConst.LeastVersionFile = jsonData.LeastVersionFile
    XLaunchConst.PatchedList = jsonData.PatchedList
    XLaunchConst.VersionOrder = jsonData.VersionOrder
    XLaunchConst.VersionPath = jsonData.VersionPath
    XLaunchConst.Client2Cdn = jsonDataClient2Cdn

    self:NextTask()
end

function XLaunchUpdateManager:RemoteVersionFile(isForce)
    if not isForce then
        if XLaunchConst.IsUpdateClose or self._IsSkipUpdate or XLaunchConst.DebugMode then
            self:NextTask()
            return
        end
        if self.IsReloaded then
            self:InitVersionFile()
            return
        end
    end

    if not self.IsEditorOrStandalone or CsApplication.Mode == CS.XMode.Release or self.NeedLaunchTest then
        if not self._DownloadTimes then
            self._DownloadTimes = 1
            self._RetryDownloadRemoteVersionFunc = function()
                self._DownloadTimes = 0
                self:RemoteVersionFile(true)
            end
        else
            self._DownloadTimes = self._DownloadTimes + 1
        end
        if self._DownloadTimes > MAX_VERSION_FILE_RETRY_COUNT then
            XLaunchConst.ShowStartErrorDialog("FileManagerInitFileTableDownloadError", 
                self._RetryDownloadRemoteVersionFunc,
                self._RetryDownloadRemoteVersionFunc,
                CsApplication.GetText("Retry"))
            return
        end
        XLaunchConst.StartDownloadFile(function(downloadGroup)
            downloadGroup:AddTask(self._VersionUrl, self._VersionPath)
            downloadGroup:AddTask(self._Client2CdnUrl, self._Client2CdnPath)
        end,
        function()
            self:InitVersionFile()
        end)
    else
        self:NextTask()
    end
end

function XLaunchUpdateManager:TestDebugModule()
    if not XLaunchConst.DebugMode then
        self:NextTask()
        return
    end
    local debugFilePath = string.format("%s/LastBuildVersion.json", self._DocFilePath)
    if XLaunchConst.FileExists(debugFilePath) then
        local jsonData = XLaunchConst.LoadJsonFile(debugFilePath)
        if jsonData then
            for key, value in pairs(jsonData) do
                XLaunchConst[key] = value
            end
        end
    end
    debugFilePath = string.format("%s/Client2Cdn.json", self._DocFilePath)
    if XLaunchConst.FileExists(debugFilePath) then
        local jsonDataClient2Cdn = XLaunchConst.LoadJsonFile(debugFilePath)
        if jsonDataClient2Cdn then
            XLaunchConst.Client2Cdn = jsonDataClient2Cdn
        end
    end
    self:NextTask()
end

-- 更新LaunchModule
function XLaunchUpdateManager:UpdateLaunchModule()
    local isEditorOrStandalone = self.IsEditorOrStandalone
    if not isEditorOrStandalone or CsApplication.Mode == CS.XMode.Release or self.NeedLaunchTest then
        self:UseUpdateModule(RES_FILE_TYPE.LAUNCH_MODULE)
    else
        self:NextTask()
    end
end

-- 预下载
function XLaunchUpdateManager:PreloadMaxtrixModule()
    if CsRemoteConfig.PreloadEnable == 1 then
        local XModuleUpdateManager = require("XLaunchUpdate/XModuleUpdateManager")
        local downloadManager = XModuleUpdateManager.New()
        downloadManager:Init(RES_FILE_TYPE.MATRIX_FILE, self._NextFunc)
        downloadManager:ExecuteMergePredownload()
    else
        self:NextTask()
    end
end

-- 清除更新的临时版本内容
function XLaunchUpdateManager:PreUpdateMatrixModule()
    -- CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_LOADING)
    local isEditorOrStandalone = self.IsEditorOrStandalone
    if not isEditorOrStandalone or CsApplication.Mode == CS.XMode.Release or self.NeedLaunchTest then
        local XModuleUpdateManager = require("XLaunchUpdate/XModuleUpdateManager")
        local downloadManager = XModuleUpdateManager.New()
        downloadManager:Init(RES_FILE_TYPE.MATRIX_FILE, self._NextFunc)
        downloadManager:ExecuteTempFile()
    else
        self:NextTask()
    end
end

-- 启动注入修复引擎初始化
function XLaunchUpdateManager:InjectFixEngineInit()
    local injectfixInitFunc = CS.XGame.InjectFixEngineInit
    if injectfixInitFunc then injectfixInitFunc() end
    self:NextTask()
end

-- 更新MatrixModule
function XLaunchUpdateManager:UpdateMatrixModule()
    local isEditorOrStandalone = self.IsEditorOrStandalone
    if not isEditorOrStandalone or CsApplication.Mode == CS.XMode.Release or self.NeedLaunchTest then
        CsLog.Debug("Release 模式运行")
        self:UseUpdateModule(RES_FILE_TYPE.MATRIX_FILE)
    elseif isEditorOrStandalone and CsApplication.Mode == CS.XMode.Debug then
        CsLog.Debug("Debug 模式运行")
        self:NextTask()
    elseif isEditorOrStandalone and CsApplication.Mode == CS.XMode.Editor then
        CsLog.Debug("Editor 模式运行")
        CS.XResourceManager.InitEditor()
        self:NextTask()
    end
end

-- 实现Shader热更
function XLaunchUpdateManager:ShaderWarmUpTask()
    CS.XLog.Warning(string.format("[XLaunchUpdateManager] - Task: ShaderWarmUpTask 开始预热, 更新总时长 Time: %s", self:GetCurrentTime() - self._ProfileTimeStart))
    self._UpdateTaskFinished = true
    if not self._ShaderWarmUping then
        self:DoShaderWarmUp()
    else
        if self._ShaderWarmUpTaskFinished then
            self:CheckShaderWarmUpTaskFinished()
        end
    end
end

-- Shader热更完成
function XLaunchUpdateManager:CheckShaderWarmUpTaskFinished()
    self._ShaderWarmUpTaskFinished = true
    if self._UpdateTaskFinished then
        self:NextTask()
    end
end

-- 温热Shader
function XLaunchUpdateManager:DoShaderWarmUp(isSkip)
    CS.XLog.Debug(string.format("[XLaunchUpdateManager]DoShaderWarmUp isSkip %s", isSkip))
    self._ShaderWarmUping = true
    if isSkip then
        self:CheckShaderWarmUpTaskFinished()
        return
    end
    local value = CS.UnityEngine.PlayerPrefs.GetInt(XLaunchConst.ShaderWarmUpKey, 1)
    if value == 0 or not CS.XRemoteConfig.IsShaderWarmUp or CS.XRemoteConfig.IsHideFunc == 1 then
        self:CheckShaderWarmUpTaskFinished()
        return
    end
    local xsvcInst = CS.XSVCWarmUp.Instance
    if not xsvcInst then
        self:CheckShaderWarmUpTaskFinished()
        return
    end
    local value = CS.UnityEngine.PlayerPrefs.GetInt(XLaunchConst.ShaderWarmUpFinishKey, 0)
    if value == 0 then
        xsvcInst:WarmUpShader()
    else
        xsvcInst:WarmUpShader(100)
    end
    local vtotalCount = xsvcInst.TotalVariantCount
    if vtotalCount <= 0 then
        self:CheckShaderWarmUpTaskFinished()
        return
    end

    CS.XLog.Debug("[XLaunchUpdateManager]DoShaderWarmUp start")
    local updateProgressStateFunc = function(progress)
        if not self._UpdateTaskFinished then return end
        if not self._UpdateProgressShaderState then
            self._UpdateProgressShaderState = true
            CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, vtotalCount, false, CsApplication.GetText("ShaderWarmUp") .. "(%d/%d)")
        end
        CsApplication.SetProgress(progress)
    end

    local warmUpTime = self:GetCurrentTime()
    updateProgressStateFunc(0)
    local timerId
    timerId = CS.XScheduleManager.ScheduleForever(function()
        local progress = xsvcInst.WarmUpProgress
        updateProgressStateFunc(progress)
        if progress >= 1 then
            local cost = self:GetCurrentTime() - warmUpTime
            CS.XLog.Debug("Shader WarmUp cost time " .. cost)
            CS.UnityEngine.PlayerPrefs.SetInt(XLaunchConst.ShaderWarmUpKey, 0)
            CS.UnityEngine.PlayerPrefs.SetInt(XLaunchConst.ShaderWarmUpFinishKey, 1)
            CS.UnityEngine.PlayerPrefs.Save()
            CS.XScheduleManager.UnSchedule(timerId)

            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["mode"] = "shader_warm_up_end",
                ["time_cost"] = cost,
            }
            CS.XRecord.Record(dict, "80040", "UpdateModuleShaderWarmUp")
            self:CheckShaderWarmUpTaskFinished()
        end
    end, 100)
end

-- 进入游戏
function XLaunchUpdateManager:InitGame()
    local isUpdate = XLaunchConst.GetKeyValue(XLaunchConst.IsUpdateKey) or false
    CS.XResourceManager.IndexPath = nil
    local cost = self:GetCurrentTime() - self._ProfileTimeStart
    local dict = {
        ["version"] = CS.XRemoteConfig.DocumentVersion,
        ["mode"] = isUpdate and "enter_cost" or "update_cost",
        ["time_cost"] = cost,
    }
    CS.XRecord.Record(dict, "80041", "UpdateModuleFlow")

    CS.XGameEventManager.Instance:RemoveEvent(XLaunchConst.EVENT_SHADER_WARM_UP, self._WarmUpShaderCallback)
    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_LOADING)
    CS.XGame.InitGame()
    self:NextTask()
end

-- endregion

return XLaunchUpdateManager.New()
