---@class XSubPackageAgency : XAgency
---@field private _Model XSubPackageModel
---@field private _SubpackageWaitDnLdQueue number[] 分包下载Id列表
---@field private _LaunchDlcManager XLaunchDlcManager 下载管理器
---@field private _DownloadCenter XMTDownloadCenter 多线程下载器
local XSubPackageAgency = XClass(XAgency, "XSubPackageAgency")

local MIN_SIZE = 1024
local BATCH_DELETE_COUNT = 10

local CheckStageId = 10030304

local LaunchTestPath = CS.UnityEngine.Application.dataPath .. "/../../../Product/Temp/LocalCdn"
local LaunchTestDirApp = CS.UnityEngine.Application.dataPath .. "/../../../Product/Temp/LocalDirApp"
local LaunchTestDirDoc = CS.UnityEngine.Application.dataPath .. "/../../../Product/Temp/LocalDirDoc"

local SingleThreadCount = 1 --单线程线程数
local MultiThreadCount = 5 --多线程线程数

local pairs = pairs
local ipairs = ipairs
local stringFormat = string.format

local DebugForceOpenSubpackage = false
local IsDebugBuild = CS.XApplication.Debug
local CsLog = CS.XLog

--分包下载源
local CsXApplication = CS.XApplication

function XSubPackageAgency:OnInit()
    self.DefaultSkipVideoPreloadDownloadTip = false
    self._SubpackageWaitDnLdQueue = {}
    self._ResWaitDnLdQueue = {}
    self._FileToResIds = {}

    self._IsUninstalling = false
    self._UninstallVersion = 0
    self._IsDownloading = false
    self._DownloadPackageId = 0
    self._DownloadingResId = 0
    self._IsDownloadGroup = false --是否为一组同时下载
    self._PreparePauseSubpackageId = 0 --准备暂停的Id
    self._IsPause = false

    self._ThreadCount = SingleThreadCount --线程数

    self._OnPreEnterFightCb = handler(self, self.OnPreEnterFight)
    self._OnExitFightCb = handler(self, self.OnExitFight)
    self._OnNetworkReachabilityChangedCb = handler(self, self.OnNetworkReachabilityChanged)
    self._OnLoginSuccessCb = handler(self, self.OnLoginSuccess)
    self._OnLoginOutCb = handler(self, self.OnLoginOut)
    self._OnSingleTaskFinishCb = handler(self, self.OnSingleTaskFinish)

    self._LaunchDlcManager = require("XLaunchDlcManager")

    self._SubIndexInfo = self._LaunchDlcManager.GetIndexInfo()

    self._TipDialog = false

    self._ErrorSubpackageId = nil
    --是否需要测试
    self._IsNeedLaunchTest = CS.XResourceManager.NeedLaunchTest

    self._DocumentUrl = self._LaunchDlcManager.GetPathModule().GetDocumentUrl()

    self._DocumentVersion = self._LaunchDlcManager.GetVersionModule().GetNewDocVersion()

    self._DocumentFilePath = self._LaunchDlcManager.GetPathModule().GetDocumentFilePath()

    self._DownloadCenter = nil

    self:ResolveResIndex()
end

function XSubPackageAgency:GetSubIndexInfo()
    return self._SubIndexInfo
end

function XSubPackageAgency:GetFileToResIds()
    return self._FileToResIds
end

function XSubPackageAgency:InitRpc()
end

function XSubPackageAgency:InitEvent()
    --进入战斗
    XEventManager.AddEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self._OnPreEnterFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._OnPreEnterFightCb)

    --退出战斗
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)

    --单个文件下载完毕
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_MT_DOWNLOAD_SINGLE_TASK_FINISH, self._OnSingleTaskFinishCb)

    --网络状态改变
    CS.XNetworkReachability.AddListener(self._OnNetworkReachabilityChangedCb)

    --主界面可以操作
    XEventManager.AddEventListener(XEventId.EVENT_FIRST_ENTER_UI_MAIN, self._OnLoginSuccessCb)

    --注销登录
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_UI_OPEN, self._OnLoginOutCb)
end

function XSubPackageAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self._OnPreEnterFightCb)

    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._OnPreEnterFightCb)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)

    --单个文件下载完毕
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_MT_DOWNLOAD_SINGLE_TASK_FINISH, self._OnSingleTaskFinishCb)

    CS.XNetworkReachability.RemoveListener(self._OnNetworkReachabilityChangedCb)

    XEventManager.RemoveEventListener(XEventId.EVENT_FIRST_ENTER_UI_MAIN, self._OnLoginSuccessCb)

    --注销登录
    XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_UI_OPEN, self._OnLoginOutCb)
end

function XSubPackageAgency:SetDebugForceOpenSubpackage(value)
    if not IsDebugBuild then
        return
    end

    DebugForceOpenSubpackage = value
end

function XSubPackageAgency:IsOpen()
    if DebugForceOpenSubpackage then
        return true
    end
    return self._LaunchDlcManager.CheckSubpackageOpen()
end

--- 检查当前是否有下载任务正在进行
function XSubPackageAgency:IsDownloading()
    return self._IsDownloading or XTool.IsNumberValid(self._DownloadingResId)
end

function XSubPackageAgency:OpenUiMain(groupId)
    if not self:IsOpen() then
        return
    end

    XLuaUiManager.Open("UiDownLoadMain", groupId)
end

function XSubPackageAgency:RecordTryDownload(uiName)
    if not self:IsOpen() then
        return
    end
    local trance = debug.traceback()
    CS.XResourceManager.AddDebugTrance(uiName, trance)
end

--- 转换单位
---@param size number 文件大小，对应字节byte
---@return number, string 文件大小，对应单位
--------------------------
function XSubPackageAgency:TransformSize(size)
    local unit = "B"
    local num = size
    if num >= MIN_SIZE then
        unit = "KB"
        num = num / MIN_SIZE
    end

    if num >= MIN_SIZE then
        unit = "MB"
        num = num / MIN_SIZE
    end

    return math.ceil(num), unit
end

function XSubPackageAgency:GetSubpackageTotalSize(subpackageId)
    local size = 0
    local t = self._Model:GetSubpackageTemplate(subpackageId)
    local resIds = t.ResIds

    -- 字典表优化
    local dict = self._tempDict
    if not dict then
        dict = {}
        self._tempDict = dict
    else
        -- 清空字典表，准备复用
        for k in pairs(dict) do
            dict[k] = nil
        end
    end

    if not XTool.IsTableEmpty(resIds) then
        for _, resId in pairs(resIds) do
            local indexInfo = self._SubIndexInfo[resId]
            if indexInfo then
                for _, info in pairs(indexInfo) do
                    local fileName = info[1]
                    --如果有同名文件只记录一次
                    if not dict[fileName] then
                        dict[fileName] = true
                        size = size + info[3]
                    end
                end
            else
                if IsDebugBuild then
                    local str = stringFormat("分包 SubpackageId = %s 不存在IndexInfo, ResId = %s", subpackageId, resId)
                    XLog.Warning(str)
                end
            end
        end
    end

    return size
end

function XSubPackageAgency:GetResTotalSize(resId)
    local size = 0

    -- 字典表优化
    local dict = self._tempDict
    if not dict then
        dict = {}
        self._tempDict = dict
    else
        -- 清空字典表，准备复用
        for k in pairs(dict) do
            dict[k] = nil
        end
    end

    local indexInfo = self._SubIndexInfo[resId]
    if indexInfo then
        for _, info in pairs(indexInfo) do
            local fileName = info[1]
            --如果有同名文件只记录一次
            if not dict[fileName] then
                dict[fileName] = true
                size = size + info[3]
            end
        end
    end
    return size
end

--- Res粒度开始下载
--------------------------
function XSubPackageAgency:AddResToDownload(resId)
    -- XLog.Warning("SP/DN AddResToDownload", resId, self._ResWaitDnLdQueue)
    if self._DownloadingResId == resId then
        return
    end
    local resItem = self._Model:GetResourceItem(resId)
    resItem:PrepareDownload()
    table.insert(self._ResWaitDnLdQueue, resId)
    self:DoResDownload()
end

function XSubPackageAgency:DoResDownload()
    -- XLog.Warning("SP/DN DoResDownload", self._DownloadingResId, self._ResWaitDnLdQueue)
    if XTool.IsNumberValid(self._DownloadingResId) then
        return
    end

    local index = 1
    local targetResId = self._ResWaitDnLdQueue[index]
    table.remove(self._ResWaitDnLdQueue, index)
    local resItem = self._Model:GetResourceItem(targetResId)
    resItem:StartDownload()
    self:InitDownloader()
    self._DownloadingResId = targetResId
    self._DownloadCenter:StartById(targetResId)
end

function XSubPackageAgency:OnResDownloadRelease()
    -- XLog.Warning("SP/DN OnResDownloadRelease", self._ResWaitDnLdQueue, self._PreparePauseSubpackageId, self._DownloadingResId)

    if self._DownloadCenter then
        self._DownloadCenter:SetFailedTaskGroupMethod(2)
    end
    -- 记录下载完成 不然登录会变成热更新
    if self._DownloadingResId then
        local resItem = self._Model:GetResourceItem(self._DownloadingResId)
        if resItem:IsComplete() then
            self._LaunchDlcManager.SetLaunchDownloadRecord(self._DownloadingResId)
            CS.UnityEngine.PlayerPrefs.Save()
        end
        self._DownloadingResId = nil
    end

    if XTool.IsNumberValid(self._PreparePauseSubpackageId) then
        local item = self._Model:GetSubpackageItem(self._PreparePauseSubpackageId)
        item:Pause()
        self._TipDialog = false

        XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PAUSE, self._PreparePauseSubpackageId)
    end

    if XTool.IsNumberValid(self._PreparePauseSubpackageId) then -- subPackage正在暂停
        return
    end

    -- 队列优先下载res
    if not XTool.IsTableEmpty(self._ResWaitDnLdQueue) then
        self:DoResDownload()
    else
        self:StartDownload()
    end
end

--- 添加到下载队列
---@param subpackageId number  分包Id
--------------------------
function XSubPackageAgency:AddToDownload(subpackageId)
    -- XLog.Warning("SP/DN AddToDownload", subpackageId, self._IsDownloading, self._SubpackageWaitDnLdQueue)
    if not self:IsOpen() then
        return
    end
    if not self._SubpackageWaitDnLdQueue then
        self._SubpackageWaitDnLdQueue = {}
    end
    if self._IsDownloading and self._DownloadPackageId == subpackageId then
        return
    end
    local item = self._Model:GetSubpackageItem(subpackageId)

    if item:IsComplete() then
        return
    end
    for _, id in ipairs(self._SubpackageWaitDnLdQueue) do
        if id == subpackageId then
            return
        end
    end
    table.insert(self._SubpackageWaitDnLdQueue, subpackageId)
    item:PrepareDownload()

    -- 用户点击下载，标记分包为激活状态
    self._LaunchDlcManager.SetSubPackageActive(subpackageId, true)

    if not self._IsDownloading and not self._IsShowingWifiTip and XTool.IsTableEmpty(self._ResWaitDnLdQueue) then
        self:StartDownload()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

--- 将必要资源添加到下载队列
function XSubPackageAgency:AddNecessaryToDownload()
    --开始下载必要资源
    local subIds = self._Model:GetNecessarySubIds()
    for _, subId in ipairs(subIds) do
        self:AddToDownload(subId)
    end
end

--- Subpackage粒度开始下载
--------------------------
function XSubPackageAgency:StartDownload()
    -- XLog.Warning("SP/DN StartDownload", self._SubpackageWaitDnLdQueue)
    --没有需要下载的了
    if XTool.IsTableEmpty(self._SubpackageWaitDnLdQueue) or XTool.IsNumberValid(self._DownloadingResId) then
        return
    end
    local isWifi = CS.XNetworkReachability.IsViaLocalArea()
    --wifi or 已经弹过提示
    if isWifi or self._TipDialog then
        self:DoDownload()
        return
    end

    if self._IsShowingWifiTip then
        return
    end
    self._IsShowingWifiTip = true
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("DlcDownloadWIFIText"), nil, function()
        self:PauseAll()
        self._IsShowingWifiTip = false
    end, function()
        self._IsShowingWifiTip = false
        self._TipDialog = true
        self:DoDownload()
    end)
end

--执行下载逻辑
function XSubPackageAgency:DoDownload()
    -- XLog.Warning("SP/DN DoDownload 1 ", self._SubpackageWaitDnLdQueue, self._IsDownloading, self._DownloadPackageId)

    if not self:IsOpen() then
        return
    end
    if XTool.IsTableEmpty(self._SubpackageWaitDnLdQueue) or self._IsDownloading or XTool.IsNumberValid(self._DownloadPackageId) then
        return
    end
    -- XLog.Warning("SP/DN DoDownload 2 ", self._SubpackageWaitDnLdQueue, self._IsDownloading, self._DownloadPackageId)

    local index = 1
    local subpackageId = self._SubpackageWaitDnLdQueue[index]
    table.remove(self._SubpackageWaitDnLdQueue, index)
    self._DownloadPackageId = subpackageId
    self._IsDownloading = true
    self:DoRecordSubpackageDoDownload(subpackageId)

    local item = self._Model:GetSubpackageItem(subpackageId)
    --更新状态
    -- XLog.Warning("SP/DN DoDownload 3 ", subpackageId, item:GetState())
    item:StartDownload()
    -- XLog.Warning("SP/DN DoDownload 4 ", subpackageId, item:GetState())
    --恢复下载状态
    self._IsPause = false
    --开始下载
    item:StartResDownload()
    --事件通知
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_START, subpackageId)
end

--标记为暂停状态
function XSubPackageAgency:PauseDownload(subpackageId)
    -- XLog.Warning("SP/DN PauseDownload", subpackageId, self._SubpackageWaitDnLdQueue)
    local subpackageItem = self._Model:GetSubpackageItem(subpackageId)
    subpackageItem:PreparePause()
    subpackageItem._WaitPause = true
    self._IsPause = true
    local resIdList = self._Model:GetSubpackageTemplate(subpackageId).ResIds
    local removeIndices = {}
    local targetPauseResId = nil
    for i, resId in ipairs(resIdList) do
        for k, resIdInQueue in pairs(self._ResWaitDnLdQueue) do
            if resId == resIdInQueue then
                table.insert(removeIndices, k)
            end
        end
        local resItem = self._Model:GetResourceItem(resId)
        if resItem:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING then
            targetPauseResId = resId
            -- XLog.Warning("SP/DN 暂停TG 0 ", targetPauseResId, resItem:GetTaskGroup().State)
        end
    end
    table.sort(removeIndices, function (a, b)
        return a < b
    end)

    for i = #removeIndices, 1, -1 do
        table.remove(self._ResWaitDnLdQueue, removeIndices[i])
    end
    if self._DownloadCenter and targetPauseResId then
        local resItem = self._Model:GetResourceItem(targetPauseResId)
        -- XLog.Warning("SP/DN 暂停TG 1 ", targetPauseResId, resItem:GetTaskGroup().State)
        self._DownloadCenter:PauseById(targetPauseResId)
        -- XLog.Warning("SP/DN 暂停TG 2 ", targetPauseResId, resItem:GetTaskGroup().State)
    end

    --等待暂停
    self._PreparePauseSubpackageId = subpackageId
    --事件通知
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

-- 暂停必要资源下载
function XSubPackageAgency:PauseNecessaryDownload()
    local subIds = self._Model:GetNecessarySubIds()

    if not XTool.IsTableEmpty(subIds) then
        for _, subId in ipairs(subIds) do
            if subId == self._DownloadPackageId then
                self:PauseDownload(subId)
            else
                self:ProcessPrepare(subId)
            end
        end
    end
end

--暂停队列中的所有下载
function XSubPackageAgency:PauseAll()
    if not self:IsOpen() then
        return
    end
    if self._IsDownloading and XTool.IsNumberValid(self._DownloadPackageId) then
        self:PauseDownload(self._DownloadPackageId)
    end
    for _, subId in pairs(self._SubpackageWaitDnLdQueue or {}) do
        local item = self._Model:GetSubpackageItem(subId)
        item:InitState()
    end
    self._SubpackageWaitDnLdQueue = {}

    for _, resId in pairs(self._ResWaitDnLdQueue) do
        local item = self._Model:GetResourceItem(resId)
        item:InitState()
    end
    self._ResWaitDnLdQueue = {}

    self:ChangeThread(true)
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_COMPLETE)
end

--释放下载器
function XSubPackageAgency:OnDownloadRelease()
    -- XLog.Warning("SP/DN OnDownloadRelease", self._PreparePauseSubpackageId, self._SubpackageWaitDnLdQueue, self._IsDownloading)
    if not self:IsOpen() then
        return
    end

    if XTool.IsNumberValid(self._PreparePauseSubpackageId) then
        local item = self._Model:GetSubpackageItem(self._PreparePauseSubpackageId)
        item:Pause()
        self._TipDialog = false

        XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PAUSE, self._PreparePauseSubpackageId)
    end

    --下载队列为空了
    if XTool.IsTableEmpty(self._SubpackageWaitDnLdQueue) then
        --切换为单线程下载
        self:ChangeThread(true)
    end

    self._IsDownloading = false
    self._IsDownloadGroup = false
    self._DownloadPackageId = 0
    self._PreparePauseSubpackageId = 0
    self._Downloader = nil

    -- 保底若 OnResDownloadRelease 被拦截了 这里还能再处理一次队列下载
    if not XTool.IsNumberValid(self._DownloadingResId) then
        self:StartDownload()
    end
end

--处理等待中
function XSubPackageAgency:ProcessPrepare(subpackageId)
    if not self:IsOpen() then
        return
    end
    --等到暂停结束
    if self:IsPreparePause() and self._PreparePauseSubpackageId == subpackageId then
        return
    end
    local index
    --从下载队列里移除
    for idx, subId in pairs(self._SubpackageWaitDnLdQueue) do
        if subId == subpackageId then
            index = idx
            break
        end
    end
    if index then
        table.remove(self._SubpackageWaitDnLdQueue, index)
    end
    local item = self._Model:GetSubpackageItem(subpackageId)
    item:InitState()

    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

--单个分包下载完毕
function XSubPackageAgency:OnComplete(subpackageId)
    self._IsDownloading = false
    -- local id = self._DownloadPackageId
    local id = subpackageId
    self._CompleteIdCache = id
    self._DownloadPackageId = 0

    -- 如果有相关任务 告诉服务端完成
    local subpackageCfg = self._Model:GetSubpackageTemplate(id)
    if subpackageCfg and XTool.IsNumberValid(subpackageCfg.DownloadTaskId) then
        self:RequestTask(subpackageCfg.DownloadTaskId)
    end

    -- XLog.Warning("SP/DN OnComplete", id, self._SubpackageWaitDnLdQueue, self._ResWaitDnLdQueue)
    XUiManager.PopupLeftTip(XUiHelper.GetText("DlcDownloadCompleteTitle"), self._Model:GetSubPackageName(id))
    local item = self._Model:GetSubpackageItem(id)
    item:Complete()
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_COMPLETE)

    if not self.IsSyncScene and self:CheckNecessaryComplete() then
        self.IsSyncScene = true
        XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)
    end

    --埋点
    self:DoRecordSubpackageComplete(id)
    self:Print(string.format("[SubPackage] Subpackage(%s) Download Complete!", subpackageId))
    self._LaunchDlcManager.SetSubPackageFinished(subpackageId, true)
end

function XSubPackageAgency:OnProgressUpdate(progress, taskGrpId)
    local resItem = self._Model:GetResourceItem(taskGrpId)
    if resItem then
        resItem:UpdateMaxProgress(progress)
        XEventManager.DispatchEvent(XEventId.EVENT_RES_UPDATE, taskGrpId, progress)
    end
    local subpackageIds = self._Model:GetSubpackageIdByResId(taskGrpId)
    if not XTool.IsTableEmpty(subpackageIds) then
        for _, subpackageId in pairs(subpackageIds) do
            local subpackageItem = self._Model:GetSubpackageItem(subpackageId)
            XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_UPDATE, subpackageId, subpackageItem:GetProgress())
        end
    end
end

-- [新增] 检查资源是否被其他分包占用
function XSubPackageAgency:IsResUsedByOtherProcessSubpackage(checkResId, excludeSubpackageId)
    local ownerSubIds = self._Model:GetSubpackageIdByResId(checkResId)
    if XTool.IsTableEmpty(ownerSubIds) then
        return false 
    end

    for _, subId in ipairs(ownerSubIds) do
        -- 排除当前正在卸载的这个分包
        if subId ~= excludeSubpackageId then
            -- 【判定 1】分包级保护：只要有一个主人是“已完成”状态，必须保护
            if self:CheckSubpackageComplete(subId) then
                return true 
            end

            -- 【判定 2】资源级精细保护：该资源有实际下载进度
            local resItem = self._Model:GetResourceItem(checkResId)
            if resItem and resItem:GetDownloadSize() > 0 then
                return true
            end
        end
    end
    return false
end

-- [重构] 外部调用的单个资源卸载接口（自动异步）
function XSubPackageAgency:UninstallResourceById(resId, cb)
    if not resId or resId <= 0 then return end

    -- 如果正在进行批量卸载（锁住了），则不允许单独插队
    if self._IsUninstalling then
        XLog.Warning("正在卸载资源，请稍候...")
        return
    end

    -- 正在下载中，不允许卸载（避免下载与卸载并发导致状态异常）
    if self._IsDownloading or XTool.IsNumberValid(self._DownloadingResId) then
        XUiManager.TipText("SubpackageUninstallRejectDownloading")
        return
    end

    -- 递增版本号，使旧协程失效
    self._UninstallVersion = self._UninstallVersion + 1
    local currentVersion = self._UninstallVersion

    -- 定义执行体
    local execute = function()
        self._IsUninstalling = true -- 加上锁

        -- 调用核心逻辑
        local cancelled = self:_UninstallResCore(resId, currentVersion)
        if cancelled then return end

        -- 版本号校验
        if self._UninstallVersion ~= currentVersion then
            XLog.Warning("[XSubPackageAgency] UninstallResourceById 协程被取消")
            return
        end

        -- 刷新事件
        local affectedSubpackageIds = self._Model:GetSubpackageIdByResId(resId)
        if affectedSubpackageIds then
            for _, subId in ipairs(affectedSubpackageIds) do
                local subItem = self._Model:GetSubpackageItem(subId)
                if subItem then
                    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_UPDATE, subId, subItem:GetProgress())
                    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subId)
                end
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_RES_UPDATE, resId, 0)
        
        -- 卸载后销毁下载器，确保下次下载时重新创建并注册新的 TaskGroup
        if self._DownloadCenter then
            self._DownloadCenter = nil
        end

        self._IsUninstalling = false -- 解锁
        XLog.Warning(string.format("[XSubPackageAgency] 单资源异步卸载完成 ResId=%d", resId))
        if cb then cb() end
    end

    -- [智能环境判断]
    local co = coroutine.running()
    if co then
        -- 情况A：已经在协程里了（极少情况，除非有其他系统调它），直接跑
        execute()
    else
        -- 情况B：主线程调用的（如按钮点击），启动协程包裹它
        RunAsyn(execute)
    end
end

-- [重构] 分包卸载接口
function XSubPackageAgency:UninstallSubpackageById(subpackageId, cb)
    if not subpackageId or subpackageId <= 0 then return end

    if self._IsUninstalling then
        XLog.Warning("正在卸载资源，请稍候...")
        return
    end

    -- 正在下载中，不允许卸载（避免下载与卸载并发导致状态异常）
    if self._IsDownloading or XTool.IsNumberValid(self._DownloadingResId) then
        XUiManager.TipText("SubpackageUninstallRejectDownloading")
        return
    end

    -- 递增版本号，使旧协程失效
    self._UninstallVersion = self._UninstallVersion + 1
    local currentVersion = self._UninstallVersion

    RunAsyn(function()
        self._IsUninstalling = true

        local template = self:GetSubpackageTemplate(subpackageId)
        if not template or not template.ResIds then
            self._IsUninstalling = false
            if cb then cb() end
            return
        end

        XLog.Warning(string.format("[XSubPackageAgency] 开始协程卸载 SubpackageId=%d", subpackageId))

        for _, resId in ipairs(template.ResIds) do
            -- 版本号校验
            if self._UninstallVersion ~= currentVersion then
                XLog.Warning("[XSubPackageAgency] UninstallSubpackageById 协程被取消")
                return
            end

            local isLocked = self:IsResUsedByOtherProcessSubpackage(resId, subpackageId)

            if isLocked then
                XLog.Warning(string.format("跳过 ResId=%d", resId))
            else
                -- [关键] 直接调用 Core，因为它已经支持 yield，且当前已经在协程里
                local cancelled = self:_UninstallResCore(resId, currentVersion)
                if cancelled then return end

                -- Res 之间的额外休息（可选）
                asynWaitSecond(0)
                -- yield 恢复后再次校验
                if self._UninstallVersion ~= currentVersion then
                    XLog.Warning("[XSubPackageAgency] UninstallSubpackageById 协程被取消")
                    return
                end
            end
        end

        -- 最终校验
        if self._UninstallVersion ~= currentVersion then
            return
        end
        local item = self._Model:GetSubpackageItem(subpackageId)
        if item then
            XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_UPDATE, subpackageId, item:GetProgress())
            XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_COMPLETE)
        
        -- 卸载后销毁下载器，确保下次下载时重新创建并注册新的 TaskGroup
        if self._DownloadCenter then
            self._DownloadCenter = nil
        end

        self._IsUninstalling = false
        XLog.Warning("[XSubPackageAgency] 卸载完成")
        -- 用户卸载分包，标记为非激活状态
        self._LaunchDlcManager.SetSubPackageActive(subpackageId, false)
        self._LaunchDlcManager.SetSubPackageFinished(subpackageId, false)
        if cb then cb() end
    end)
end

-- [修复] 内部辅助：检查某个物理文件是否被"当前操作目标以外"的活跃资源占用
-- @param physicalFileName 物理文件名（hash名，即 info[1]），与 _FileToResIds 的 key 维度一致
-- @param excludeResIds table 需要排除的资源ID列表（通常是当前要卸载的分包包含的所有ResId）
function XSubPackageAgency:_IsFileProtected(physicalFileName, excludeResIds)
    local owners = self._FileToResIds[physicalFileName]
    if not owners then return false end

    for _, ownerResId in ipairs(owners) do
        -- 如果该 ownerResId 不在“排除列表”中（说明属于其他分包或独立资源）
        local isTargetRes = false
        for _, exId in ipairs(excludeResIds) do
            if ownerResId == exId then
                isTargetRes = true
                break
            end
        end

        if not isTargetRes then
            -- 检查这个“外部引用者”是否处于活跃状态（已下载或有进度）
            local isCompleted = self._LaunchDlcManager.HasDownloadedDlc(ownerResId)
            local resItem = self._Model:GetResourceItem(ownerResId)
            local hasProgress = resItem and resItem:GetDownloadSize() > 0

            if isCompleted or hasProgress then
                return true -- 被外部活跃资源引用，受保护
            end
        end
    end
    return false
end

-- [新增] 获取分包下所有实际_UninstallResCore删除时会删的文件
-- @param subpackageId 分包Id
-- @return table { [resId] = { "path1", "path2", ... } }
function XSubPackageAgency:GetUninstallableFileInfoBySubpackageId(subpackageId)
    local result = {}
    if not subpackageId or subpackageId <= 0 then return result end

    local template = self:GetSubpackageTemplate(subpackageId)
    if not template or not template.ResIds then return result end

    local currentSubResIds = template.ResIds

    for _, resId in ipairs(currentSubResIds) do
        local resItem = self._Model:GetResourceItem(resId)
        -- 只有本地确实存在的资源才需要统计
        if resItem and resItem:GetDownloadSize() > 0 then
            local indexInfo = self._SubIndexInfo[resId]
            if indexInfo then
                local deletableFiles = {}
                for assetPath, info in pairs(indexInfo) do
                    local physicalFileName = info[1]
                    -- 判定逻辑：传入物理文件名（与 _FileToResIds 的 key 维度一致）
                    if not self:_IsFileProtected(physicalFileName, currentSubResIds) and CS.System.IO.File.Exists(self:GetSavePath(physicalFileName)) then
                        -- info[1] 通常是文件的全路径或相对路径名
                        table.insert(deletableFiles, info[1])
                    end
                end
                
                -- 如果该 Res 下有可删文件，存入结果
                if #deletableFiles > 0 then
                    result[resId] = deletableFiles
                end
            end
        end
    end

    return result
end

-- [修改] 检查分包是否有可卸载的资源 (控制删除按钮显示)
-- 逻辑：只要分包有进度，且处于暂停或完成状态，即视为可卸载
function XSubPackageAgency:CheckSubpackageCanUninstall(subpackageId)
    if not subpackageId or subpackageId <= 0 then 
        return false 
    end

    local item = self._Model:GetSubpackageItem(subpackageId)
    if not item then
        return false
    end

    -- 1. 检查是否有下载进度
    local downloadSize = item:GetDownloadSize()
    if downloadSize <= 0 then
        return false
    end

    -- 2. 检查状态 (暂停 或 完成)
    local state = item:GetState()
    local STATE_ENUM = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE

    if state == STATE_ENUM.PAUSE or state == STATE_ENUM.COMPLETE then
        return true
    end

    return false
end

-- [新增] 核心卸载逻辑（私有，必须在协程中运行）
--- @param resId number 资源Id
function XSubPackageAgency:_UninstallResCore(resId, currentVersion)
    local indexInfo = self._SubIndexInfo[resId]
    if not indexInfo then return false end

    local allRelatedResIds = { resId } -- 至少排除自己
    -- 这里可以根据业务需求扩展，通常单资源卸载只排除自己，分包卸载则排除整个分包的 ResIds
    print(string.format("[Core] 开始执行物理删除 ResId=%d", resId))

    -- 1. 业务数据清理
    self._LaunchDlcManager.ClearDownloadRecord(resId)
    self._LaunchDlcManager.AddUninstalledResId(resId)
    local unistallResItem = self._Model:GetResourceItem(resId)
    unistallResItem:Uninstall()

    local deleteCount = 0
    local batchCounter = 0

    for assetPath, info in pairs(indexInfo) do
        local physicalFileName = info[1]
        local savePath = self:GetSavePath(physicalFileName)

        -- 2. 依赖检查：传入物理文件名（与 _FileToResIds 的 key 维度一致）
        if not self:_IsFileProtected(physicalFileName, allRelatedResIds) then
            -- 3. 物理删除
            CS.XFileTool.DeleteFile(savePath)
            deleteCount = deleteCount + 1

            -- [关键] 强制分帧：每删 10 个文件，向当前协程申请休息
            batchCounter = batchCounter + 1
            if batchCounter >= BATCH_DELETE_COUNT then
                batchCounter = 0
                asynWaitSecond(0) -- 让出控制权给下一帧
                -- 版本号校验：重连/登出后旧协程应立即退出
                if currentVersion and self._UninstallVersion ~= currentVersion then
                    XLog.Warning("[XSubPackageAgency] _UninstallResCore 协程被取消")
                    return true -- true 表示被取消
                end
            end
        end
    end

    -- 4. 内存刷新
    self._Model:RemoveResCache(resId)
    local affectedSubpackageIds = self._Model:GetSubpackageIdByResId(resId)
    if affectedSubpackageIds then
        for _, subId in ipairs(affectedSubpackageIds) do
            local subItem = self._Model:GetSubpackageItem(subId)
            if subItem then
                for assetPath, info in pairs(indexInfo) do
                    subItem:InitFileInfo(assetPath, info, resId)
                end
                subItem:FileInitComplete()
            end
        end
    end

    -- 补调新 XResource 的 FileInitComplete，确保状态正确初始化
    local newResItem = self._Model:GetResourceItem(resId)
    if newResItem then
        newResItem:FileInitComplete()
    end
end

function XSubPackageAgency:ResolveResIndex()
    if not self:IsOpen() then
        return
    end
    if self._IsResolve then
        return
    end
    
    -- 初始化文件反向索引表：Key = FileName, Value = {ResId1, ResId2, ...}
    -- 用于在 UninstallResourceById 中快速判断文件是否被其他 ResId 引用
    self._FileToResIds = self._FileToResIds or {}

    XLog.Warning("XSubPackageAgency:ResolveResIndex Start")

    for resId, indexInfo in pairs(self._SubIndexInfo) do
        if resId and resId > 0 then
            
            -- 【修复】构建 物理文件名(hash) -> ResIdList 的映射
            -- key 必须是 info[1]（物理文件名），而非 assetPath（indexInfo 的 key）
            -- 因为不同 assetPath 可能映射到同一个物理文件，按 assetPath 建索引会遗漏跨 assetPath 的共享
            for assetPath, info in pairs(indexInfo) do
                local physicalFileName = info[1]
                if not self._FileToResIds[physicalFileName] then
                    self._FileToResIds[physicalFileName] = {}
                end
                -- 去重：同一 resId 下多个 assetPath 可能指向同一物理文件
                local alreadyExists = false
                for _, existingResId in ipairs(self._FileToResIds[physicalFileName]) do
                    if existingResId == resId then
                        alreadyExists = true
                        break
                    end
                end
                if not alreadyExists then
                    table.insert(self._FileToResIds[physicalFileName], resId)
                end
            end

            -- 原有的 Item 初始化逻辑
            local subpackageIds = self._Model:GetSubpackageIdByResId(resId)
            if not XTool.IsTableEmpty(subpackageIds) then
                for _, subpackageId in pairs(subpackageIds) do
                    local item = self._Model:GetSubpackageItem(subpackageId)
                    if item then
                        for assetPath, info in pairs(indexInfo) do
                            item:InitFileInfo(assetPath, info, resId)
                        end
                    end
                end
            else
                XLog.Error("XSubPackageAgency:ResolveResIndex subpackageIds is empty, resId:", resId)
            end
        end
    end

    self._Model:ResolveComplete()
    self._IsResolve = true
end

function XSubPackageAgency:InitDownloader()
    if not self._DownloadCenter then
        self._DownloadCenter = CS.XMTDownloadCenter()
        self._DownloadCenter:SetThreadNumber(self._ThreadCount)
        local groupIds = self._Model:GetGroupIdList()
        for _, groupId in ipairs(groupIds) do
            local group = self._Model:GetGroupTemplate(groupId)
            for _, subpackageId in ipairs(group.SubPackageId) do
                local item = self._Model:GetSubpackageItem(subpackageId)
                if item and not item:IsComplete() then
                    local taskGroups = item:GetTaskGroups()
                    for k, taskGroup in pairs(taskGroups) do
                        taskGroup.NotifyStateChanged = handler(self, self.OnStateChanged)
                        taskGroup.NotifyProgressChanged = handler(self, self.OnProgressUpdate)
                        self._DownloadCenter:RegisterTaskGroup(taskGroup)
                    end
                end
            end
        end
    end

    self._DownloadCenter:Run()
end

function XSubPackageAgency:GetSavePath(fileName)
    if self._IsNeedLaunchTest then
        return stringFormat("%s/%s/%s", LaunchTestDirDoc, RES_FILE_TYPE.MATRIX_FILE, fileName)
    end
    return stringFormat("%s/%s/%s", self._DocumentFilePath, RES_FILE_TYPE.MATRIX_FILE, fileName)
end

function XSubPackageAgency:GetUrlPath(fileName)

    return stringFormat("%s/%s", self:GetUrlPrefix(), fileName)
end

function XSubPackageAgency:GetUrlPrefix()
    if self._UrlPrefix then
        return self._UrlPrefix
    end
    if self._IsNeedLaunchTest then
        self._UrlPrefix = stringFormat("%s/%s/%s", "client/patch/com.kurogame.haru.internal.debug.subpack/1.0.0/android", CS.XRemoteConfig.DocumentVersion, RES_FILE_TYPE.MATRIX_FILE)
        return self._UrlPrefix
    end
    self._UrlPrefix = stringFormat("%s/%s/%s", self._DocumentUrl, CS.XRemoteConfig.DocumentVersion, RES_FILE_TYPE.MATRIX_FILE)

    return self._UrlPrefix
end

function XSubPackageAgency:GetNecessarySubIds()
    return self._Model:GetNecessarySubIds()
end

--- 获取指定分包资源总大小
function XSubPackageAgency:GetSubPackageTotalSizeBySubId(subId)
    local subPackage = self:GetSubpackageItem(subId)

    if subPackage then
        return subPackage:GetTotalSize()
    else
        XLog.Error('找不到对应的分包资源数据，subId：' .. tostring(subId))
        return 0
    end
end

--- 获取指定分包资源已经下载部分的大小
function XSubPackageAgency:GetSubPackageDownloadSizeBySubId(subId)
    local subPackage = self:GetSubpackageItem(subId)

    if subPackage then
        return subPackage:GetDownloadSize()
    else
        XLog.Error('找不到对应的分包资源数据，subId：' .. tostring(subId))
        return 0
    end
end

function XSubPackageAgency:ChangeThread(isSingle)

    local count = isSingle and SingleThreadCount or MultiThreadCount

    if isSingle and self._IsDownloading and self._ThreadCount == MultiThreadCount then
        XUiManager.TipText("QuitFullDownloadTip")
    end

    self._ThreadCount = count
    if self._DownloadCenter then
        self._DownloadCenter:SetThreadNumber(self._ThreadCount)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_MULTI_COUNT_CHANGED)
end

function XSubPackageAgency:IsMultiThread()
    if not self._IsDownloading then
        return false
    end
    return self._ThreadCount == MultiThreadCount
end

--正在切换线程数量
function XSubPackageAgency:IsChangingThread()
    if not self._IsDownloading then
        return false
    end

    if not self._DownloadCenter then
        return false
    end
    return self._DownloadCenter:GetCurrentRunningTaskNumber() ~= self._ThreadCount
end

function XSubPackageAgency:OnStateChanged(taskGpId, state)
    local item = self._Model:GetResourceItem(taskGpId)
    if item then
        item:OnStateChanged(state)
    end
end

---判断分包是否下载完成
---@return boolean
function XSubPackageAgency:CheckSubpackageComplete(subpackageId)
    if not self:IsOpen() then
        return true
    end

    if type(subpackageId) ~= "number" then
        return true
    end

    --无需下载
    if subpackageId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.INVALID then
        return true
    elseif subpackageId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY then --检测必要资源
        return self:CheckNecessaryComplete()
    end

    local item = self._Model:GetSubpackageItem(subpackageId)
    if not item then
        return true
    end

    --当前分包未下载完
    if not item:IsComplete() then
        return false
    end
    local complete = true
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    local bindIds = template.PreIds
    if XTool.IsTableEmpty(bindIds) then
        return complete
    end
    --检查当前分包绑定的分包是否下载完毕
    for _, bindId in ipairs(bindIds) do
        local item = self._Model:GetSubpackageItem(bindId)
        if item and not item:IsComplete() then
            complete = false
            break
        end
    end

    return complete
end

function XSubPackageAgency:SetHasResIdCheckStoryId(storyId)
    self._Model.HasResIdCheckStoryId[storyId] = true
end

function XSubPackageAgency:GetHasResIdCheckStoryId(storyId)
    return self._Model.HasResIdCheckStoryId[storyId]
end

function XSubPackageAgency:CheckResDownloadComplete(resId)
    local resItem = self._Model:GetResourceItem(resId)
    local flag = resItem:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    return flag
end

-- 检查多个StageId对应的ResIdList资源是否下载完毕
function XSubPackageAgency:CheckStageIdListResIdListDownloadComplete(stageIdList, downloadedCb)
    if (not self:IsOpen()) or XMVCA.XSubPackage:GetDefaultSkipVideoPreloadDownloadTip() then
        if downloadedCb then downloadedCb() end
        return true
    end

    local allDownloaded = true
    local resIdSet = {}

    for _, stageId in ipairs(stageIdList) do
        local config = self:GetModelStageIdToResIdListConfigByStageId(stageId)
        if config then
            for _, resId in ipairs(config.ResIdList) do
                resIdSet[resId] = true -- 去重
            end
        end
    end

    for resId, _ in pairs(resIdSet) do
        if not self:CheckResDownloadComplete(resId) then
            allDownloaded = false
            break
        end
    end

    if allDownloaded then
        if downloadedCb then downloadedCb() end
    else
        local resIdList = {}
        for resId, _ in pairs(resIdSet) do
            table.insert(resIdList, resId)
        end
        XLuaUiManager.Open("UiVideoPreloadDownloadTip", resIdList, downloadedCb)
    end

    return allDownloaded
end


-- 检查必要资源是否下载完毕
function XSubPackageAgency:CheckNecessaryComplete()
    if not self:IsOpen() then
        return true
    end
    local complete = true
    local necessaryIds = self._Model:GetNecessarySubIds()
    for _, subpackageId in ipairs(necessaryIds) do
        local item = self._Model:GetSubpackageItem(subpackageId)
        if item and not item:IsComplete() then
            complete = false
            break
        end
    end
    return complete
end

--- 检查必要资源是否正在下载中
function XSubPackageAgency:CheckNecessaryDownloading()
    if not self:IsOpen() then
        return true
    end
    local downloading = false
    local necessaryIds = self._Model:GetNecessarySubIds()
    for _, subpackageId in ipairs(necessaryIds) do
        local item = self._Model:GetSubpackageItem(subpackageId)
        if item and item:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING then
            downloading = true
            break
        end
    end
    return downloading
end

--- 检查必要资源是否处于下载队列且未暂停
function XSubPackageAgency:CheckNecessaryIsReadyDownload()
    if not self:IsOpen() then
        return true
    end
    local isReady = false
    local necessaryIds = self._Model:GetNecessarySubIds()
    for _, subpackageId in ipairs(necessaryIds) do
        local item = self._Model:GetSubpackageItem(subpackageId)
        if item then
            if item:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING or item:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD then
                isReady = true
                break
            end
        end
    end
    return isReady
end

--- 检查必要资源是否处于暂停中
function XSubPackageAgency:CheckNecessaryIsPaused()
    if not self:IsOpen() then
        return true
    end
    local isPause = true
    local necessaryIds = self._Model:GetNecessarySubIds()
    for _, subpackageId in ipairs(necessaryIds) do
        local item = self._Model:GetSubpackageItem(subpackageId)
        if item then
            local state = item:GetState()
            
            if state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE and
                    state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
                isPause = false
                break
            end
        end
    end
    return isPause
end

function XSubPackageAgency:CheckAllComplete()
    if not self:IsOpen() then
        return true
    end
    local complete = true
    local groupIds = self._Model:GetGroupIdList()
    for _, groupId in pairs(groupIds) do
        local template = self._Model:GetGroupTemplate(groupId)
        for _, subpackageId in ipairs(template.SubPackageId) do
            local item = self._Model:GetSubpackageItem(subpackageId)
            if not item:IsComplete() then
                complete = false
                break
            end
        end
        if not complete then
            break
        end
    end

    return complete
end

--- 检查指定功能类型所需的分包是否已经全部下载完成
--- @param enterType any 功能入口类型，例如 XFunctionManager.FunctionName.MainLine
--- @param param any 附加参数，例如关卡id、角色id等
function XSubPackageAgency:CheckSubpackageDownloadByFunctionType(enterType, param)
    return self:CheckSubpackage(enterType, param, true)
end

function XSubPackageAgency:CheckSubpackage(enterType, param, ignorePopUi)
    if not self:IsOpen() then
        return true
    end
    local subIds = self._Model:GetAllSubpackageIds(enterType, param)
    local complete = true
    if not XTool.IsTableEmpty(subIds) then
        for _, subId in pairs(subIds) do
            complete = self:CheckSubpackageComplete(subId)
            if not complete then
                break
            end
        end
    end
    if IsDebugBuild then
        local strSubId = XTool.IsTableEmpty(subIds) and "nil" or table.concat(subIds, ", ")
        local log = stringFormat("[拦截] 拦截类型：%s 拦截参数：%s 分包Id: %s, 下载完成：%s"
        , enterType, param, strSubId, tostring(complete))
        XLog.Error(log)
    end
    --需要拦截
    if not complete then
        if not ignorePopUi then
            self:DoRecordIntercept(enterType, param)
            XLuaUiManager.Open("UiDownloadPreview", subIds)
            -- XLog.Debug("SP/DN 打开UiDownloadPreview ", enterType, subIds)
        end
        return false
    end
    return true
end

-- 拦截则返回false tips:目前基本是给系统侧临时拦截视频分包用(已弃用)
function XSubPackageAgency:CheckSubpackageByIdAndIntercept(subpackageId)
    if not self:IsOpen() then
        return true
    end

    local isComplete = self:CheckSubpackageComplete(subpackageId)
    if not isComplete then
        self:DoRecordIntercept(nil, subpackageId)
        XLuaUiManager.Open("UiDownloadPreview", {subpackageId})
        return false
    end
    return true
end

function XSubPackageAgency:CheckSubpackageByCvType(cvType)
    local isComplete = self:CheckCvDownload(cvType)
    if not isComplete then
        local subpackageIds = self._Model:GetAllSubpackageIds(XFunctionManager.FunctionName.CharacterVoice, cvType)
        if not XTool.IsTableEmpty(subpackageIds) then
            XLog.Warning(stringFormat("[Subpackage Intercept(CV)]:\n\tCVType:%s\tSubpackageIds:%s",
                    tostring(cvType), table.concat(subpackageIds, ", ")))
            XLuaUiManager.Open("UiDownloadPreview", subpackageIds)
        else
            isComplete = true
        end
    end
    return isComplete
end

function XSubPackageAgency:CheckCvDownload(cvType)
    if not self:IsOpen() then
        return true
    end

    local subId = self._Model:GetEntrySubpackageId(XFunctionManager.FunctionName.CharacterVoice, cvType)
    return self:CheckSubpackageComplete(subId)
end

function XSubPackageAgency:DownloadAllByGroup(groupId)
    if not self:IsOpen() then
        return
    end
    local template = self._Model:GetGroupTemplate(groupId)
    local subIds = template.SubPackageId
    local downloading = {}
    for _, subId in pairs(self._SubpackageWaitDnLdQueue) do
        downloading[subId] = subId
    end
    local need = {}
    for _, subId in ipairs(subIds) do
        --没在正在下载的列表
        if not downloading[subId] then
            local item = self._Model:GetSubpackageItem(subId)
            --未下载完
            if not item:IsComplete() then
                table.insert(need, subId)
            end
        end
    end

    table.sort(need, function(a, b)
        return a < b
    end)
    for _, subId in ipairs(need) do
        self:AddToDownload(subId)
    end
    self._IsDownloadGroup = true
end

function XSubPackageAgency:IsNecessaryGroup(groupId)
    local template = self._Model:GetGroupTemplate(groupId)
    local subIds = template and template.SubPackageId or {}
    local subId = subIds[1]
    if not XTool.IsNumberValid(subId) then
        return false
    end
    local subT = self._Model:GetSubpackageTemplate(subId)
    return subT.Type == XEnumConst.SUBPACKAGE.SUBPACKAGE_TYPE.NECESSARY
end

---@return string
function XSubPackageAgency:GetDownloadingTip()
    if not self:IsOpen() then
        return
    end
    if not self._IsDownloading and not XTool.IsNumberValid(self._CompleteIdCache) then
        return
    end
    local id
    if self._IsDownloading then
        id = self._DownloadPackageId
        return XUiHelper.GetText("DlcDownloadingItemText", self._Model:GetSubPackageName(id))
    else
        id = self._CompleteIdCache
        self._CompleteIdCache = nil
        return XUiHelper.GetText("DlcItemCompleteText", self._Model:GetSubPackageName(id))
    end
end

function XSubPackageAgency:GetWifiAutoState(groupId)
    if self:IsNecessaryGroup(groupId) then
        return self._LaunchDlcManager.IsSelectWifiAutoDownload()
    end
    return self._Model:GetWifiAutoSelect(groupId)
end

function XSubPackageAgency:SetWifiAutoState(groupId, value)
    if self:IsNecessaryGroup(groupId) then
        self._LaunchDlcManager.SetSelectWifiAutoDownloadValue(value)
    else
        self._Model:SaveWifiAutoSelect(groupId, value)
    end

    self:OnNetworkReachabilityChanged()
end

function XSubPackageAgency:OnPreEnterFight()

end

function XSubPackageAgency:OnExitFight()
    if not self._ErrorSubpackageId then
        return
    end
    self:ErrorDialog("FileManagerInitFileTableInGameDownloadError", nil, function()
        self:AddToDownload(self._ErrorSubpackageId)
        self._ErrorSubpackageId = nil
    end, nil, CsXApplication.GetText("Retry"))

end

function XSubPackageAgency:MarkErrorDialogOnFight(subpackageId)
    self:PauseAll()
    self._ErrorSubpackageId = subpackageId
end

function XSubPackageAgency:DoDownloadError(subpackageId)
    --如果在战斗中
    if not CS.XFightInterface.IsOutFight then
        self:MarkErrorDialogOnFight(subpackageId)
        return
    end
    self:PauseAll()
    self:ErrorDialog("FileManagerInitFileTableInGameDownloadError", nil, function()
        self:AddToDownload(subpackageId)
    end, nil, CsXApplication.GetText("Retry"))
end

function XSubPackageAgency:ErrorDialog(errorCode, cancelCb, confirmCb, cancelStr, confirmStr)

    cancelCb = cancelCb or function()
    end
    confirmCb = confirmCb or function()
    end

    CS.XTool.WaitCoroutine(CsXApplication.CoDialog(CsXApplication.GetText("Tip"),
            CsXApplication.GetText(errorCode), cancelCb, confirmCb, cancelStr, confirmStr))
end

function XSubPackageAgency:OnNetworkReachabilityChanged()
    if not self:IsOpen() then
        return
    end

    local notConnected = CS.XNetworkReachability.IsNotReachable()
    if notConnected and self._IsDownloading then
        self:DoDownloadError(self._DownloadPackageId)
        return
    end

    local isWifi = CS.XNetworkReachability.IsViaLocalArea()

    if isWifi then
        local groupIds = self._Model:GetGroupIdList()
        for _, groupId in ipairs(groupIds) do
            if self:GetWifiAutoState(groupId) then
                self:DownloadAllByGroup(groupId)
            end
        end
    else
        self:PauseAll()
    end
end

function XSubPackageAgency:OnLoginSuccess()
    if not self:IsOpen() then
        return
    end
    --self:RequestSelectSubTask()
    --已经在下载了，就不用处理了
    if self._IsDownloading then
        return
    end
    --非wifi环境
    if not CS.XNetworkReachability.IsViaLocalArea() then
        return
    end
    --玩家未选中自动下载
    if not self._LaunchDlcManager.IsSelectWifiAutoDownload() then
        return
    end
    --开始下载必要资源
    local subIds = self._Model:GetNecessarySubIds()
    for _, subId in ipairs(subIds) do
        self:AddToDownload(subId)
    end
end

function XSubPackageAgency:OnLoginOut()
    if not self:IsOpen() then
        return
    end

    -- 递增版本号，使正在运行的卸载协程失效
    self._UninstallVersion = (self._UninstallVersion or 0) + 1
    self._IsUninstalling = false
    self:PauseAll()
end

function XSubPackageAgency:OnSingleTaskFinish(eventName, args)
    local resourceName = args[0]
    --resourceName 是带前缀的
    local fullLen = string.len(resourceName)
    local prefixLen = string.len(self:GetUrlPrefix())
    --Lua 下标从1开始，去掉斜杠
    local fileName = string.sub(resourceName, prefixLen + 2, fullLen)
    self._LaunchDlcManager.SetDownloadedFile(fileName, true)
end

function XSubPackageAgency:IsPreparePause()
    return XTool.IsNumberValid(self._PreparePauseSubpackageId)
end

--是否为可选资源
function XSubPackageAgency:IsOptional(subpackageId)
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    return template.Type == XEnumConst.SUBPACKAGE.SUBPACKAGE_TYPE.OPTIONAL
end

function XSubPackageAgency:CheckRedPoint()
    return self:CheckTaskRedPont()
end

function XSubPackageAgency:CheckTaskRedPont()
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageNecessaryTaskId")
    if not XTool.IsNumberValid(taskId) then
        return false
    end

    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if not taskData then
        return false
    end

    return taskData.State == XDataCenter.TaskManager.TaskState.Achieved
end

--选择基础包任务完成
function XSubPackageAgency:RequestSelectSubTask()
    --未选择基础包
    -- 1:基础资源 2:完整资源
    local downloadMode = self._LaunchDlcManager.IsFullDownload(CS.XInfo.Version) and 2 or 1
    if downloadMode == 2 then
        return
    end
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageTaskId")
    if not XTool.IsNumberValid(taskId) then
        return
    end

    self:RequestTask(taskId)
end

--必要资源下载完成任务完成
function XSubPackageAgency:RequestNecessaryTask(responseCb, faultCb)
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageNecessaryTaskId")
    if not XTool.IsNumberValid(taskId) then
        if faultCb then
            faultCb()
        end
        return
    end

    self:RequestTask(taskId, responseCb, faultCb)
end

--- 判断必要资源下载任务是否领取奖励
function XSubPackageAgency:CheckNecessaryTaskState(state)
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageNecessaryTaskId")
    
    if not XTool.IsNumberValid(taskId) then
        XLog.Error('判断必要资源下载任务是否领取奖励, 没有找到任务配置：SubpackageNecessaryTaskId')
        return false
    end
    
    local data = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if not data then
        XLog.Error('必要资源下载任务数据不存在，taskId：'..tostring(taskId))
        return false
    end

    return data.State == state
end

function XSubPackageAgency:RequestTask(taskId, responseCb, faultCb)
    --分包未开放
    if not self:IsOpen() then
        return
    end

    local data = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if not data then
        if faultCb then
            faultCb()
        end
        return
    end

    if data.State == XDataCenter.TaskManager.TaskState.Achieved
            or data.State == XDataCenter.TaskManager.TaskState.Finish then
        if faultCb then
            faultCb()
        end
        return
    end

    XDataCenter.TaskManager.RequestClientTaskFinish(taskId, responseCb, faultCb)
end

function XSubPackageAgency:GetSubpackageIdByResId(resId)
    return self._Model:GetSubpackageIdByResId(resId)
end

function XSubPackageAgency:GetSubpackageItem(subpackageId)
    return self._Model:GetSubpackageItem(subpackageId)
end

function XSubPackageAgency:GetResourceItem(resId)
    return self._Model:GetResourceItem(resId)
end

function XSubPackageAgency:GetSubpackageTemplate(subpackageId)
    return self._Model:GetSubpackageTemplate(subpackageId)
end

function XSubPackageAgency:GetAllResAndSubpackageItemDic()
    return self._Model._ResourceDict, self._Model._SubpackageDict
end

function XSubPackageAgency:GetModelStageIdToResIdList()
    return self._Model:GetStageIdToResIdList()
end

function XSubPackageAgency:GetModelStageIdToResIdListConfigByStageId(stageId)
    return self._Model:GetStageIdToResIdListConfigByStageId(stageId)
end

function XSubPackageAgency:SetDefaultSkipVideoPreloadDownloadTip(flag)
    self.DefaultSkipVideoPreloadDownloadTip = flag
end

function XSubPackageAgency:GetDefaultSkipVideoPreloadDownloadTip()
    return self.DefaultSkipVideoPreloadDownloadTip
end

---------------------------------------------------------
-- 打印所有 SubIndexInfo 数据（单条日志）
-- 结构：
-- ResId
--   - FileName | Size | Sha1
---------------------------------------------------------
function XSubPackageAgency:PrintAllSubIndexInfo()
    local indexInfo = self._SubIndexInfo
    if XTool.IsTableEmpty(indexInfo) then
        XLog.Warning("[分包Info][SubIndexInfo] EMPTY")
        return
    end

    local lines = {}
    lines[#lines + 1] = "================ [分包Info _SubIndexInfo数据] BEGIN ================"

    for resId, fileDict in pairs(indexInfo) do
        lines[#lines + 1] = string.format("ResId: %s", tostring(resId))

        if XTool.IsTableEmpty(fileDict) then
            lines[#lines + 1] = "  (Empty)"
        else
            for _, info in pairs(fileDict) do
                -- info = { fileName, sha1, size }
                local fileName = info[1]
                local sha1 = info[2]
                local size = info[3]

                lines[#lines + 1] = string.format(
                    "  - %s | Size: %s | Sha1: %s",
                    tostring(fileName),
                    tostring(size),
                    tostring(sha1)
                )
            end
        end
    end

    lines[#lines + 1] = "================ [分包Info][SubIndexInfo] END =================="

    -- 一次性输出，保证只有一条日志
    XLog.Warning(table.concat(lines, "\n"))
end

function XSubPackageAgency:PrintAllItemInfo()
    local resItemDic, subpackageItemDic = self:GetAllResAndSubpackageItemDic()
    local resItemString = "[分包Info Item数据]\nResInfo\n"
    local subPackageItemString = "\nSubpackageInfo\n"

    for _, item in pairs(resItemDic) do
        local formatted = string.format("ResId:%s, State:%s, TaskGropState:%s, DownloadSize:%s, TotalSize:%d, 进度:%s\n", 
        item._Id, item:GetState(), item:GetTaskGroup().State, item:GetDownloadSize(), item:GetTotalSize(), item:GetProgress())

        resItemString = resItemString .. formatted
    end

    for _, item in pairs(subpackageItemDic) do
        local formatted = string.format("SubpackageId:%s, State:%s, DownloadSize:%s, TotalSize:%s, 进度:%s\n", item._Id, item:GetState(), item:GetDownloadSize(), item:GetTotalSize(), item:GetProgress())
        subPackageItemString = subPackageItemString .. formatted
    end

    XLog.Warning(resItemString .. subPackageItemString)
end

function XSubPackageAgency:DoRecordSubpackageDoDownload(subpackageId)
    local subpackageItem = self:GetSubpackageItem(subpackageId)
    local dict = {}
    dict["subpackage_id"] = subpackageId
    dict["subpackage_totalSize"] = subpackageItem:GetTotalSize()
    dict["document_version"] = CS.XRemoteConfig.DocumentVersion
    dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
    CS.XRecord.Record(dict, "80037", "SubpackageDoDownload")
end

function XSubPackageAgency:DoRecordSubpackageComplete(subpackageId)
    if not self._LaunchDlcManager then
        return
    end
    if self:IsOptional(subpackageId) then
        local subpackageItem = self:GetSubpackageItem(subpackageId)
        local dict = {}
        dict["subpackage_id"] = subpackageId
        dict["subpackage_totalSize"] = subpackageItem:GetTotalSize()
        dict["document_version"] = CS.XRemoteConfig.DocumentVersion
        dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["cv_hk_complete"] = tostring(self:CheckCvDownload(XEnumConst.CV_TYPE.HK))
        dict["cv_en_complete"] = tostring(self:CheckCvDownload(XEnumConst.CV_TYPE.EN))
        dict["cv_jp_complete"] = tostring(self:CheckCvDownload(XEnumConst.CV_TYPE.JPN))
        CS.XRecord.Record(dict, "80034", "SubpackageOptional")
    else
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(CheckStageId)
        local dict = {}
        dict["document_version"] = CS.XRemoteConfig.DocumentVersion
        dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["pass_main_line"] = tostring(stageInfo.Passed)
        dict["subpackage_id"] = tostring(subpackageId)
        dict["necessary_complete"] = tostring(self:CheckNecessaryComplete())

        CS.XRecord.Record(dict, "80033", "SubpackageNecessary")
    end
end

function XSubPackageAgency:DoRecordIntercept(entryType, param)
    local dict = {}
    dict["document_version"] = CS.XRemoteConfig.DocumentVersion
    dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    dict["ui_name"] = XLuaUiManager.GetTopUiName()
    dict["entry_type"] = tostring(entryType or "empty")
    dict["param"] = tostring(param or "empty")
    CS.XRecord.Record(dict, "80035", "SubpackageIntercept")
end

function XSubPackageAgency:DoRecordDownloadError(fileName, fileSize)
    local dict = {}
    dict["file_name"] = fileName
    dict["file_size"] = fileSize
    dict["version"] = self._DocumentVersion
    dict["type"] = RES_FILE_TYPE.MATRIX_FILE

    CS.XRecord.Record(dict, "80007", "XFileManagerDownloadError")
end

function XSubPackageAgency:Print(info)
    CsLog.Debug(info)
end

return XSubPackageAgency