----------------------------------------------------------------------------------------------------
-- XModuleUpdateManager.lua
-- description: 模块更新流程（状态机调度）
--   职责拆分：数据操作 → XUpdateDataContext, 下载逻辑 → XUpdateDownloader
--   本类保留：状态机调度 + 代理方法（State侧调用接口不变）
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsLog = CS.XLog
local CsDirectory = CS.System.IO.Directory
local CsApplication = CS.XApplication
local StringFormat = string.format
local XFileInfoVersionIndex = XLaunchConst.XFileInfoVersionIndex
local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
local XFileInfoFlagIndex = XLaunchConst.XFileInfoFlagIndex

---@class XModuleUpdateManager
---@field New fun(...): XModuleUpdateManager 创建对象
---@field ResFileType string 模块类型
---@field TIMEOUT number 超时
---@field READ_TIMEOUT number 读取超时
---@field RETRY number 重试次数
---@field ModuleUpdateInfo XModuleUpdateInfo 模块更新信息
---@field DataContext XUpdateDataContext 数据容器（索引表、下载列表、大小统计等）
---@field Downloader XUpdateDownloader 下载器（下载、缓存读写、清理）
---@field PreIndexTable table<string, CS.XFileInfo> 预下载索引文件列表
---@field PackageIndexTable table<string, CS.XFileInfo> 包索引文件列表
---@field LocalIndexTable table<string, CS.XFileInfo> 本地索引文件列表
---@field NewVersionIndexTable table<string, CS.XFileInfo> 远端索引文件列表
---@field NewVersionDlcIndexTable table<string, CS.XFileInfo> 远端Dlc索引文件列表
---@field ResAssetTable table<string, boolean> 资源是否存在
---@field PatchJsonTable table<int, table> {IsInit = boolean, Patch = {}} 版本id, 对应下载的文件列表
---@field ShaderABList table<string, CS.XFileInfo> Index着色器包列表
---@field BaseABList table<string, CS.XFileInfo> Index基础包列表
---@field ShaderTable table<string, CS.XFileInfo> 着色器包列表
---@field UpdateCheckTable table<string, CS.XFileInfo> 基础包列表
local XModuleUpdateManager = XLaunchConst.CreateMetaTable("XModuleUpdateManager")

local XUpdateStateEnum = {
    LoadTempIndex = "LoadTempIndex",
    LoadTempFileCache = "LoadTempFileCache",
    ListCahceFiles = "ListCahceFiles",
    DeleteInvalidFiles = "DeleteInvalidFiles",
    ClearTempState = "ClearTempState",
    VersionCheck = "VersionCheck",
    VersionPredownloadCheck = "VersionPredownloadCheck",
    ZipVersionCheck = "ZipVersionCheck",
    InitPackageIndex = "InitPackageIndex",
    InitLocalIndex = "InitLocalIndex",
    InitRemoteIndex = "InitRemoteIndex",
    InitPreIndexStart = "InitPreIndexStart",
    InitPreIndexEnd = "InitPreIndexEnd",
    ListNormal = "ListNormal",
    ListPredownloadNormal = "ListPredownloadNormal",
    InitDlcInfo = "InitDlcInfo",
    DownloadPatchInfo = "DownloadPatchInfo",
    ShowSelectDownload = "ShowSelectDownload",
    InitDlcAsset = "InitDlcAsset",
    ListDlc = "ListDlc",
    DownloadStartTips = "DownloadStartTips",
    DownloadPatch = "DownloadPatch",
    PatchFilesApply = "PatchFilesApply",
    FilesMerge = "FilesMerge",
    FilesPreloadMove = "FilesPreloadMove",
    FilesCheck = "FilesCheck",
    FilesCheckInvaildDownload = "FilesCheckInvaildDownload",
    MarkFiles = "MarkFiles",
    DownloadAb = "DownloadAb",
    VersionUpdate = "VersionUpdate",
    FinishMergePreload = "FinishMergePreload",
    InitResData = "InitResData",
    InitFileInfo = "InitFileInfo",
    ShaderWarmUp = "ShaderWarmUp",
    FinishCallback = "FinishCallback",
    TestPause = "Base",
}

local XModuleUpdateProcess = {
    ModuleUpdate = "ModuleUpdate",
    PreApply = "PreApply",
    PreDownload = "PreDownload",
    Repair = "Repair",
    TempFile = "TempFile",
}

-- 初始化
function XModuleUpdateManager:Ctor()
    self._OnAppcationQuit = function() self:OnAppcationQuit() end
    self.IsDebugBuild = CsApplication.Debug

    -- 状态机
    self.StateMachine = {}
    -- patch记录
    self.PatchJsonTable = {}
    self.ResAssetTable = {}
    self.CurrentState = nil

    -- 默认下载参数
    self.TIMEOUT = 5 * 1000
    self.READ_TIMEOUT = 10 * 1000
    self.RETRY = 10

    -- 数据容器
    local XUpdateDataContextClass = require("XLaunchUpdate/XUpdateDataContext")
    self.DataContext = XUpdateDataContextClass.New()

    -- 下载器
    local XUpdateDownloaderClass = require("XLaunchUpdate/XUpdateDownloader")
    self.Downloader = XUpdateDownloaderClass.New()
    self.Downloader:SetSingleFileDownloadFinishCb(function(url)
        self.DataContext:WriteDownloadCache(url)
    end)

    -- 预创建状态切换回调，避免 NextState 每次创建 closure
    self._NextStateFunc = function()
        local state = self:GetStateMachine(self._PendingStateName)
        self.CurrentState = state
        state:OnEnterWithCheck()
    end
end

-- region 状态机调度

---@param stateName string
---@return table state
function XModuleUpdateManager:GetStateMachine(stateName)
    local state = self.StateMachine[stateName]
    if not state then
        local stateClass = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateState" .. stateName)
        state = stateClass.New(self)
        self.StateMachine[stateName] = state
    end
    return state
end

-- 初始化类型
---@param resFileType string RES_FILE_TYPE 模块类型
function XModuleUpdateManager:_InitByResFileType(resFileType)
    if self.ResFileType == resFileType then return end
    self.ResFileType = resFileType

    local moduleUpdateInfo = self.ModuleUpdateInfo
    if not moduleUpdateInfo then
        local XModuleUpdateInfoClass = require("XLaunchUpdate/XModuleUpdateInfo")
        moduleUpdateInfo = XModuleUpdateInfoClass.New()
        self.ModuleUpdateInfo = moduleUpdateInfo
    end
    moduleUpdateInfo:Init(resFileType)
end

-- 执行更新模块
---@param resFileType string RES_FILE_TYPE 模块类型
---@param completeCb? function 模块更新完成回调
function XModuleUpdateManager:Init(resFileType, completeCb, isReloaded)
    self.IsReloaded = isReloaded
    self:_InitByResFileType(resFileType)
    self:SetCompleteCallback(completeCb)
end

function XModuleUpdateManager:SetCompleteCallback(cb)
    self._onCompleteCallback = cb
end

function XModuleUpdateManager:SetProgressCallback(cb)
    self.ProgressCallback = cb
    self.Downloader:SetProgressCallback(cb)
end

function XModuleUpdateManager:_InitTask()
    self:AddQuitEvent()
    self:ReadCache()
    self.TaskIndex = 0
end

function XModuleUpdateManager:Execute(isPreload)
    self._ProcessName = XModuleUpdateProcess.ModuleUpdate
    local documentFilePath = StringFormat("%s/%s", self.ModuleUpdateInfo.DocumentFilePath, self.ModuleUpdateInfo.ResFileType)
    if not CsDirectory.Exists(documentFilePath) then
        CsDirectory.CreateDirectory(documentFilePath)
    end

    self.Downloader:SetShowProgress(RES_FILE_TYPE.LAUNCH_MODULE ~= self.ResFileType)
    -- 标准模块更新任务列表
    if RES_FILE_TYPE.LAUNCH_MODULE == self.ResFileType then
        if isPreload then
            self.TaskList = {
                XUpdateStateEnum.InitPackageIndex,          -- 初始化包索引
                XUpdateStateEnum.InitLocalIndex,            -- 初始化本地索引
                XUpdateStateEnum.InitResData,               -- 初始化资源数据
            }
        else
            -- Launch 模块更新任务列表
            self.TaskList = {
                XUpdateStateEnum.VersionCheck,              -- 版本检查
                XUpdateStateEnum.InitPackageIndex,          -- 初始化包索引
                XUpdateStateEnum.InitLocalIndex,            -- 初始化本地索引
                XUpdateStateEnum.InitRemoteIndex,           -- 初始化远程索引
                XUpdateStateEnum.InitFileInfo,              -- 初始化文件信息
                XUpdateStateEnum.ListNormal,                -- 收集下载列表
                XUpdateStateEnum.DownloadAb,                -- 下载AB文件
                XUpdateStateEnum.FilesMerge,                -- 合并文件
                XUpdateStateEnum.VersionUpdate,             -- 更新版本
                XUpdateStateEnum.InitResData,               -- 初始化资源数据
                -- XUpdateStateEnum.TestPause,                 -- 测试暂停
            }
        end
    else
        -- 检测基础文件判断
        local needCheckBaseList = false
        local appVersion = CS.XInfo.Version
        local localDocVersion = CS.UnityEngine.PlayerPrefs.GetString(XLaunchConst.DocAppVersionKey, "")
        if localDocVersion ~= appVersion then
            needCheckBaseList = true
            CS.UnityEngine.PlayerPrefs.SetString(XLaunchConst.DocAppVersionKey, appVersion)
        end

        -- 下载基础index路径
        CS.XResourceManager.IndexPath = self.ModuleUpdateInfo:GetDownloadIndexPath()

        -- 标准模块更新任务列表
        self.TaskList = {
            XUpdateStateEnum.VersionCheck,              -- 版本检查
            XUpdateStateEnum.ZipVersionCheck,           -- 压缩包版本检查
            XUpdateStateEnum.InitPackageIndex,          -- 初始化包索引
            XUpdateStateEnum.InitLocalIndex,            -- 初始化本地索引
            XUpdateStateEnum.InitRemoteIndex,           -- 初始化远程索引
            XUpdateStateEnum.InitFileInfo,              -- 初始化文件信息
            XUpdateStateEnum.InitDlcInfo,               -- 初始化分包资源信息
            XUpdateStateEnum.ListNormal,                -- 收集下载列表
            XUpdateStateEnum.DownloadPatchInfo,         -- 下载补丁信息
            XUpdateStateEnum.ShowSelectDownload,        -- 显示下载选择
            XUpdateStateEnum.InitDlcAsset,              -- 初始化DLC资源
            XUpdateStateEnum.ListDlc,                   -- 列表DLC
            XUpdateStateEnum.DownloadStartTips,         -- 下载开始提示
            -- shader预热资源下载
            -- XUpdateStateEnum.ShaderWarmUp,              -- shader预热
            XUpdateStateEnum.DownloadPatch,             -- 下载补丁
            XUpdateStateEnum.PatchFilesApply,           -- 应用补丁文件
            XUpdateStateEnum.DownloadAb,                -- 下载AB文件
            XUpdateStateEnum.FilesMerge,                -- 合并文件
        }
        -- 校验基础列表
        if needCheckBaseList then
            table.insert(self.TaskList, XUpdateStateEnum.FilesCheck)
            table.insert(self.TaskList, XUpdateStateEnum.FilesCheckInvaildDownload)
            table.insert(self.TaskList, XUpdateStateEnum.DownloadAb)
            table.insert(self.TaskList, XUpdateStateEnum.FilesMerge)
        end
        table.insert(self.TaskList, XUpdateStateEnum.VersionUpdate)
        table.insert(self.TaskList, XUpdateStateEnum.InitResData)
    end
    self:_InitTask()
    self:NextState()
end

-- 清理临时版本文件
function XModuleUpdateManager:ExecuteTempFile()
    self._ProcessName = XModuleUpdateProcess.TempFile
    self.TaskList = {
        XUpdateStateEnum.LoadTempFileCache,                 -- 加载临时文件缓存
        XUpdateStateEnum.InitPackageIndex,                  -- 初始化包索引
        XUpdateStateEnum.InitRemoteIndex,                   -- 初始化远程索引
        XUpdateStateEnum.ListCahceFiles,                    -- 临时文件列表
        XUpdateStateEnum.FilesCheck,                        -- 文件检查
        XUpdateStateEnum.MarkFiles,                         -- 标记文件
        XUpdateStateEnum.DeleteInvalidFiles,                -- 删除临时文件
        XUpdateStateEnum.ClearTempState,                    -- 清除临时状态
    }
    self:_InitTask()
    self:NextState()
end

-- 预下载合并任务列表
function XModuleUpdateManager:ExecuteMergePredownload()
    self._ProcessName = XModuleUpdateProcess.PreApply
    self.ModuleUpdateInfo:SetUpdateStatue(true)
    self.ModuleUpdateInfo:SetPredownloadStatus(XLaunchConst.PredownloadType.Merge)
    self.TaskList = {
        XUpdateStateEnum.VersionPredownloadCheck,       -- 版本预下载检查
        XUpdateStateEnum.InitPackageIndex,              -- 初始化包索引
        XUpdateStateEnum.InitPreIndexEnd,               -- 初始化预索引
        XUpdateStateEnum.InitLocalIndex,                -- 初始化本地索引
        XUpdateStateEnum.InitRemoteIndex,               -- 初始化远程索引
        XUpdateStateEnum.InitFileInfo,                  -- 初始化文件信息
        XUpdateStateEnum.ListPredownloadNormal,         -- 收集下载列表
        XUpdateStateEnum.DownloadPatchInfo,             -- 下载补丁信息
        XUpdateStateEnum.PatchFilesApply,               -- 应用补丁文件
        XUpdateStateEnum.FilesPreloadMove,              -- 移动预下载文件到下载目录
        XUpdateStateEnum.FinishMergePreload,            -- 完成合并预下载文件,
        -- XUpdateStateEnum.TestPause,                       -- 测试暂停
    }
    self:_InitTask()
    self:NextState()
end

-- 预下载任务列表
function XModuleUpdateManager:ExecutePredownload()
    self._ProcessName = XModuleUpdateProcess.PreDownload
    self.ModuleUpdateInfo:SetUpdateStatue(true)
    self.ModuleUpdateInfo:SetPredownloadStatus(XLaunchConst.PredownloadType.Download)
    self.TaskList = {
        XUpdateStateEnum.InitPackageIndex,              -- 初始化包索引
        XUpdateStateEnum.InitPreIndexStart,             -- 初始化预索引
        XUpdateStateEnum.InitPreIndexEnd,               -- 初始化预索引
        XUpdateStateEnum.InitFileInfo,                  -- 初始化文件信息
        XUpdateStateEnum.ListNormal,                    -- 收集下载列表
        XUpdateStateEnum.DownloadPatchInfo,             -- 下载补丁信息
        XUpdateStateEnum.InitDlcAsset,                  -- 初始化DLC资源
        XUpdateStateEnum.ListDlc,                       -- 列表DLC
        XUpdateStateEnum.FinishCallback,                -- 完成回调
    }
    self:_InitTask()
    self:NextState()
end

-- 修复任务列表
function XModuleUpdateManager:ExecuteRepair()
    self._ProcessName = XModuleUpdateProcess.Repair
    self.ModuleUpdateInfo:SetUpdateStatue(true)
    self.TaskList = {
        XUpdateStateEnum.InitPackageIndex,              -- 初始化包索引
        XUpdateStateEnum.InitRemoteIndex,               -- 初始化远程索引
        XUpdateStateEnum.InitFileInfo,                  -- 初始化文件信息
        XUpdateStateEnum.InitDlcAsset,                  -- 初始化DLC资源
        XUpdateStateEnum.FilesCheck,                    -- 文件检查
        XUpdateStateEnum.FilesCheckInvaildDownload,     -- 文件检查无效下载
        XUpdateStateEnum.DownloadAb,                    -- 下载AB文件
        XUpdateStateEnum.FilesMerge,                    -- 合并文件
        XUpdateStateEnum.InitResData,                   -- 初始化资源数据
    }
    self:_InitTask()
    self:NextState()
end

function XModuleUpdateManager:IsUpdateMode()
    return self._ProcessName == XModuleUpdateProcess.ModuleUpdate
end

function XModuleUpdateManager:IsRepairFix()
    return self._ProcessName == XModuleUpdateProcess.Repair
end

function XModuleUpdateManager:StartProfile(name)
    if not self._Profile then self._Profile = {} end
    self._Profile[name] = CS.UnityEngine.Time.realtimeSinceStartup
end

function XModuleUpdateManager:EndProfile(name, skipLog)
    if not self._Profile then return 0 end
    local time = CS.UnityEngine.Time.realtimeSinceStartup - self._Profile[name]
    local stateName = self.TaskList[self.TaskIndex]
    if not skipLog then
        CsLog.Debug(StringFormat("[%s %s Updating] %s %s CostTime: %.2f",
            self._ProcessName, self.ResFileType,
            name, stateName, time))
    end
    return time
end

function XModuleUpdateManager:NextState()
    if self.CurrentState then
        self.CurrentState:OnExit()
    end
    self.TaskIndex = self.TaskIndex + 1
    local stateName = self.TaskList[self.TaskIndex]
    if not stateName then
        self:FinishTask()
        return
    end

    if XLaunchConst.IsDebugLog then
        CsLog.Debug(StringFormat("[%s %s Updating] State: %s %s",
        self._ProcessName, self.ResFileType,
        stateName, self.TaskIndex))
    end

    self._PendingStateName = stateName
    CS.XScheduleManager.ScheduleNextFrame(self._NextStateFunc, stateName)
end

-- 任务完成 清理
function XModuleUpdateManager:FinishTask(isAbort)
    -- 延迟执行
    CS.XScheduleManager.ScheduleNextFrame(function()
        -- 回调
        if self._onCompleteCallback then
            self._onCompleteCallback(isAbort)
        end

        -- 清理数据
        self:Clear(self.ModuleUpdateInfo:IsPredownloadStatus())
    end, "FinishTask")
end

function XModuleUpdateManager:GetFinishCallback()
    return self._onCompleteCallback
end

function XModuleUpdateManager:UpdateProgress(progress)
    if self.ProgressCallback then
        self.ProgressCallback(progress)
        return
    end
    CsApplication.SetProgress(progress)
end

function XModuleUpdateManager:SetTargetIndexMap(targetIndexMap)
    self.NewVersionIndexTable = targetIndexMap
    self:SetFileInfo(targetIndexMap)
end

function XModuleUpdateManager:GetTargetIndexMap()
    return self.NewVersionIndexTable
end

function XModuleUpdateManager:SetMarkFileMap(markFileMap)
    self.MarkFileMap = markFileMap
end

function XModuleUpdateManager:GetMarkFileMap()
    return self.MarkFileMap
end

function XModuleUpdateManager:DoRecord(...)
    CS.XRecord.Record(...)
end

-- endregion

-- region 下载信息
function XModuleUpdateManager:ClearDownloadABMap()
    self.DataContext:ClearDownloadABMap()
end

function XModuleUpdateManager:AddPatchInfo(fileName, curVersion, newVersion)
    local patchJsonTable = self.PatchJsonTable[curVersion]
    if not patchJsonTable then
        patchJsonTable = {
            IsInit = false,
            Patchs = {},
            NewVersion = newVersion,
        }
        self.PatchJsonTable[curVersion] = patchJsonTable
    end
    patchJsonTable.Patchs[fileName] = true
end

-- 预下载Patch路径获取
---@private
function XModuleUpdateManager:_GetPatchDownloadUrl(fileName, patchInfo)
    local DocumentUrl = self.ModuleUpdateInfo:GetUrlByVersion(patchInfo.NewVersion, true)
    local url = StringFormat("%s/%s/splitPatch/%s/Patch/%s.patch",
        DocumentUrl, patchInfo.NewVersion, patchInfo.OldVersion, fileName)
    return url, patchInfo.Size, patchInfo.Sha1, fileName
end

-- 预下载AB路径获取
---@private
function XModuleUpdateManager:_GetAbDownloadUrl(fileName, info)
    local XFileInfoSizeIndex = XLaunchConst.XFileInfoSizeIndex
    local sha1 = info[XFileInfoSha1Index]
    local size = info[XFileInfoSizeIndex]
    local version = info[XFileInfoVersionIndex]
    local DocumentUrl = self.ModuleUpdateInfo:GetUrlByVersion(version, true)
    local url = StringFormat("%s/%s/%s/%s", DocumentUrl, version, self.ResFileType, fileName)
    return url, size, sha1, fileName
end

-- 预下载资源路径获取
function XModuleUpdateManager:GetDownloadUrlInfo(fileName)
    local patchInfo = self:GetDownloadPatchMap()[fileName]
    if patchInfo then
        return self:_GetPatchDownloadUrl(fileName, patchInfo)
    end

    local info = self:GetDownloadABMap()[fileName]
    if info then
        return self:_GetAbDownloadUrl(fileName, info)
    end
end

function XModuleUpdateManager:GetPreloadIndexUrl()
    return self.ModuleUpdateInfo:GetPreloadIndexUrl()
end

function XModuleUpdateManager:GetPreloadIndexPath()
    return self.ModuleUpdateInfo:GetPreloadIndexStartPath(), self.ModuleUpdateInfo:GetPreloadIndexEndPath()
end

function XModuleUpdateManager:IsShaderRelative(fileName)
    if not self.ShaderTable then return false end
    return self.ShaderTable[fileName]
end

-- endregion

-- region 代理方法：DataContext
-- 数据操作委托给 DataContext，State 侧调用 self.UpdateManager:XXX() 不变

function XModuleUpdateManager:LoadIndexTable(indexPath, isDlcBuild)
    return self.DataContext:LoadIndexTable(indexPath, isDlcBuild)
end

-- 初始化文件信息
function XModuleUpdateManager:SetFileInfo(indexMap)
    self.DataContext:SetFileInfo(indexMap)
end

-- 获取文件信息
function XModuleUpdateManager:GetFileInfoByPath(fileName)
    return self.DataContext:GetFileInfoByPath(fileName)
end

-- 获取文件信息列表
function XModuleUpdateManager:GetFileInfos()
    return self.DataContext:GetFileInfos()
end

-- 设置基础表
function XModuleUpdateManager:SetUpdateCheckTable(checkTable)
    self.DataContext:SetUpdateCheckTable(checkTable)
end

-- 获取基础表
function XModuleUpdateManager:GetUpdateCheckTable()
    return self.DataContext:GetUpdateCheckTable()
end

-- 基础表是否相对
function XModuleUpdateManager:IsBaseRelative(fileName)
    return self.DataContext:IsBaseRelative(fileName)
end

-- 获取下载包映射
function XModuleUpdateManager:GetDownloadABMap()
    return self.DataContext:GetDownloadABMap()
end

-- 添加下载包映射
function XModuleUpdateManager:AddDownloadABMap(fileName, skipCheck)
    self.DataContext:AddDownloadABMap(fileName, skipCheck)
end

-- 移除下载包映射
function XModuleUpdateManager:RemoveDownloadABMap(fileName)
    self.DataContext:RemoveDownloadABMap(fileName)
end

function XModuleUpdateManager:GetDownloadPatchMap()
    return self.DataContext:GetDownloadPatchMap()
end

-- 获取需应用的补丁
function XModuleUpdateManager:GetPatchMap()
    return self.DataContext:GetPatchMap()
end

-- 添加下载补丁映射
function XModuleUpdateManager:AddDownloadPatchMap(fileName, info)
    self.DataContext:AddDownloadPatchMap(fileName, info)
end

-- 移除下载补丁映射
function XModuleUpdateManager:RemoveDownloadPatchMap(fileName)
    self.DataContext:RemoveDownloadPatchMap(fileName)
end

-- 获取基包下载大小
function XModuleUpdateManager:GetBaseDownloadSize()
    return self.DataContext:GetBaseDownloadSize()
end

-- 获取总下载大小
function XModuleUpdateManager:GetTotalDownloadSize()
    return self.DataContext:GetTotalDownloadSize()
end

-- 获取下载缓存文件数量
function XModuleUpdateManager:GetDownloadCacheCount()
    return self.DataContext:GetDownloadCacheCount()
end

-- 获取Patch文件数量
function XModuleUpdateManager:GetPatchFileCount()
    return self.DataContext:GetPatchFileCount()
end

-- 写入下载缓存
function XModuleUpdateManager:WriteDownloadCache(finishName)
    self.DataContext:WriteDownloadCache(finishName)
end

-- 写入补丁缓存
function XModuleUpdateManager:WritePatchCache(finishName)
    self.DataContext:WritePatchCache(finishName)
end

-- 判断文件是否正在下载
---@param fileName string
---@return boolean
function XModuleUpdateManager:IsDownloadFile(fileName)
    return self.DataContext:IsDownloadFile(fileName)
end

-- 判断文件是否为补丁文件
---@param fileName string
---@return boolean
function XModuleUpdateManager:IsPatchFile(fileName)
    return self.DataContext:IsPatchFile(fileName)
end

-- 清除下载缓存
function XModuleUpdateManager:ClearCache()
    self.DataContext:ClearCache()
end

-- 根据sha1判断是不是包内资源
function XModuleUpdateManager:IsInnerResource(fileName, sha1)
    if not self.PackageIndexTable then
        CsLog.Error("[XModuleUpdateManager] IsInnerResource PackageIndexTable is nil, need InitPackageIndex first.")
        return false
    end
    local packageInfo = self.PackageIndexTable[fileName]
    if not packageInfo then return false end

    -- 本地正式资源模式: 全量资源都在本地包内目录, 包外标记(flag==1)文件也按包内处理,
    -- 避免被归为 Document 类型去下载目录找文件 / 被收集进下载列表
    if XLaunchConst.IsLocalReleaseResource then
        return true
    end

    local flag = packageInfo[XFileInfoFlagIndex]
    if flag == 1 then
        return false
    end
    local packageSha1 = packageInfo[XFileInfoSha1Index]
    return sha1 == packageSha1
end

-- 根据版本判断是不是包内资源
function XModuleUpdateManager:IsInnerResourceByVersion(fileName, version)
    if not self.PackageIndexTable then
        CsLog.Error("[XModuleUpdateManager] IsInnerResource PackageIndexTable is nil, need InitPackageIndex first.")
        return false
    end
    local packageInfo = self.PackageIndexTable[fileName]
    if not packageInfo then return false end

    -- 本地正式资源模式: 与 IsInnerResource 保持同一口径
    if XLaunchConst.IsLocalReleaseResource then
        return true
    end

    local flag = packageInfo[XFileInfoFlagIndex]
    if flag == 1 then
        return false
    end
    return version == packageInfo[XFileInfoVersionIndex]
end

-- endregion

-- region 特殊代理方法（含自定义逻辑，无法批量生成）

function XModuleUpdateManager:IsNeedDownloadPatch()
    return next(self.DataContext:GetDownloadPatchMap()) ~= nil
end

function XModuleUpdateManager:ReadCache()
    self.DataContext:SetCacheFilePath(self.ModuleUpdateInfo)
    self.DataContext:ReadDownloadCache()
    self.DataContext:ReadPatchCache()
end

function XModuleUpdateManager:DownloadABFiles(downloadFiles, finishCB, skipOriginCheck, originCheckSha1)
    self.Downloader:DownloadABFiles(downloadFiles, finishCB, self.ModuleUpdateInfo, skipOriginCheck, originCheckSha1)
end

function XModuleUpdateManager:DownloadFiles(addTaskCb, finishCb, failCb, progressCb, autoStart, fileFinishCb)
    return self.Downloader:DownloadFiles(addTaskCb, finishCb, failCb, progressCb, autoStart, fileFinishCb)
end

-- endregion

-- region 清理

function XModuleUpdateManager:OnAppcationQuit()
end

function XModuleUpdateManager:AddQuitEvent()
    if self._AddEvent then return end
    self._AddEvent = true
    CS.XGameEventManager.Instance:RegisterEvent(XLaunchConst.EVENT_APPLICATION_QUIT, self._OnAppcationQuit)
    if XEventManager then
        XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_QUIT, self._OnAppcationQuit, self)
    end
end

function XModuleUpdateManager:RemoveQuitEvent()
    if not self._AddEvent then return end
    self._AddEvent = false
    CS.XGameEventManager.Instance:RemoveEvent(XLaunchConst.EVENT_APPLICATION_QUIT, self._OnAppcationQuit)
    if XEventManager then
        XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_QUIT, self._OnAppcationQuit, self)
    end
end

function XModuleUpdateManager:Clear(isPredownload)
    -- 清理数据
    self.DataContext:Clear()
    self.Downloader:Clear()

    self.CurrentState = nil
    self.TaskList = nil
    self.TaskIndex = nil
    self._onCompleteCallback = nil
    self._FinishRetryCount = nil
    self.LocalIndexTable = nil
    self.NewVersionIndexTable = nil
    self.NewVersionDlcIndexTable = nil
    self.PackageIndexTable = nil
    self.PreIndexTable = nil
    self.PatchJsonTable = {}
    self.ResAssetTable = {}
    self:RemoveQuitEvent()
end

-- endregion

return XModuleUpdateManager
