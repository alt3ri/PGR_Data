local XLaunchDlcManager = require("XLaunchDlcManager")

---@class XSubpackage 分包数据
---@field _Id number
---@field _State number
---@field _TotalSize number
local XSubpackage = XClass(nil, "XSubpackage")

local CSXMTDownloadTaskGroupState = XTool.GetDownloadStateEnum()

function XSubpackage:Ctor(packageId)
    self._Id = packageId
    self._TotalSize = -1
    self._DownSize = 0
    self._WaitPause = false
    self._PeakProgress = 0 -- 达到的最大进度
    ---@type XResource[]
    self._ResItemDic = {}
    self._TaskGroups = nil
end

function XSubpackage:InitState()
    -- [新增 Fix]：初始化时优先检查逻辑卸载状态
    -- 如果满足卸载条件（独占资源已卸载 或 共享资源被其他占用），则直接定为 UNINSTALLED
    -- 防止因为残留文件或共享文件导致状态被重置为 PAUSE
    if not XTool.IsTableEmpty(self._ResItemDic) then
        self:UpdateUninstallState()
        if self:IsUninstalled() then
            return
        end
    end

    -- [原有逻辑]：基于物理文件大小的判断
    local downloadSize = self:GetDownloadSize()
    local totalSize = self:GetTotalSize()
    if totalSize and totalSize <= 0 then
        XLog.Error("XSubpackage:InitState SizeError, totalSize = " .. totalSize .. ", id = " .. self._Id)
    end

    if downloadSize <= 0 then
        if totalSize <= 0 then
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
        else
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD
        end

    elseif downloadSize > 0 and downloadSize < totalSize then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
    else
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    end
end

function XSubpackage:GetState()
    return self._State
end

function XSubpackage:GetProgress()
    if XTool.IsTableEmpty(self._ResItemDic) then
        XLog.Warning("XSubpackage:GetProgress, _ResItemDic is empty")
        return 0
    end

    local prg = 0
    local totalDownSize = 0
    local totalAllSize = 0
    for k, resItem in pairs(self._ResItemDic) do
        totalDownSize = totalDownSize + resItem:GetDownloadSize()
        totalAllSize = totalAllSize + resItem:GetTotalSize()
    end
    prg = totalDownSize / totalAllSize
    return prg
end

function XSubpackage:GetMaxProgress()
    return math.max(self:GetProgress(), self._PeakProgress)
end

function XSubpackage:UpdateMaxProgress()
    local prg = 0
    for k, resItem in pairs(self._ResItemDic) do
        prg = prg + resItem:GetMaxProgress()
    end
    self._PeakProgress = math.max(prg, self._PeakProgress)
end

-- 下载过程中，临时文件可能出错，删除掉会导致进度减少
function XSubpackage:IsProgressLess()
    return self:GetProgress() < self._PeakProgress
end

function XSubpackage:GetTotalSize()
    -- local size = 0
    -- for k, resItem in pairs(self._ResItemDic) do
    --     size = size + resItem:GetTotalSize()
    -- end
    return XMVCA.XSubPackage:GetSubpackageTotalSize(self._Id)
end

function XSubpackage:GetDownloadSize()
    local bytes = 0
    for k, resItem in pairs(self._ResItemDic) do
        bytes = bytes + resItem:GetDownloadSize()
    end
    return bytes
end

function XSubpackage:StartResDownload(forceResumePausedRes)
    for resId, resItem in pairs(self._ResItemDic) do
        local state = resItem:GetState()
        -- P5 原逻辑：跳过 COMPLETE 和 PAUSE
        -- [F5] 扩展：当 forceResumePausedRes 为 true 时，PAUSE 也恢复入队
        if state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
           and (forceResumePausedRes or state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE) then
            XMVCA.XSubPackage:AddResToDownload(resId)
        end
    end
end

function XSubpackage:PrepareDownload()
    -- XLog.Debug("SP/DN _State PREPARE_DOWNLOAD |", self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:StartDownload()
    -- XLog.Debug("SP/DN _State DOWNLOADING", self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
end

--等待状态
function XSubpackage:PreparePause()
    -- XLog.Debug("SP/DN _State PREPARE_DOWNLOAD +", self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:Pause()
    -- XLog.Debug("SP/DN _State PAUSE |", self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XSubpackage:Complete()
    -- XLog.Debug("SP/DN _State COMPLETE |", self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    self:Release()
end

function XSubpackage:IsComplete()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
end

function XSubpackage:IsPrepare()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:IsPause()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

---更新分包的卸载状态
---判定逻辑：如果所有“可卸载”的资源（即非共享资源）都已经卸载，则分包进入 UNINSTALLED 状态
function XSubpackage:UpdateUninstallState()
    if XTool.IsTableEmpty(self._ResItemDic) then return end

    local allUninstallableDone = true
    for resId, resItem in pairs(self._ResItemDic) do
        -- 检查资源是否被其他分包占用（不可卸载）
        local isLocked = XMVCA.XSubPackage:IsResUsedByOtherProcessSubpackage(resId, self._Id)
        
        -- 如果资源既没有卸载，也不是因为被占用而跳过，说明还没卸载完
        if not resItem:IsUninstalled() and not isLocked then
            allUninstallableDone = false
            break
        end
    end

    if allUninstallableDone then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED
    end
end

--- [F2] 根据所有子资源的实际状态，重新计算分包的聚合状态
--- 用于 Res级操作后同步 Sub 状态（如从 UNINSTALLED/NOT_DOWNLOAD 恢复时）
--- 调用时机：XResource:PrepareDownload 检测到父Sub为 UNINSTALLED/NOT_DOWNLOAD 时
function XSubpackage:UpdateAggregateState()
    if XTool.IsTableEmpty(self._ResItemDic) then return end

    local hasDownloading = false
    local hasPrepare = false
    local hasPause = false
    local allComplete = true
    local allUninstalled = true

    for _, resItem in pairs(self._ResItemDic) do
        local state = resItem:GetState()
        if state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
            allComplete = false
        end
        if state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED then
            allUninstalled = false
        end
        if state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING then
            hasDownloading = true
        elseif state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD then
            hasPrepare = true
        elseif state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE then
            hasPause = true
        end
    end

    if allComplete then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    elseif allUninstalled then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED
    elseif hasDownloading or hasPrepare then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
    elseif hasPause then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
    else
        local downloadSize = self:GetDownloadSize()
        local totalSize = self:GetTotalSize()
        if downloadSize > 0 and downloadSize < totalSize then
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
        elseif downloadSize >= totalSize then
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
        else
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD
        end
    end
end

function XSubpackage:IsUninstalled()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED
end

function XSubpackage:GetSubpackageSizeWithUnit()
    local size = self:GetTotalSize()
    return XMVCA.XSubPackage:TransformSize(size)
end

function XSubpackage:InitFileInfo(filePath, data, resId)
    local resItem = self._ResItemDic[resId]
    if XTool.IsTableEmpty(resItem) then
        resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        self._ResItemDic[resId] = resItem
    end
    resItem:InitFileInfo(filePath, data)
end

-- [XSubpackage.lua] 新增方法
function XSubpackage:RemoveResCache(resId)
    -- 1. 移除对旧 Res 对象的引用
    if self._ResItemDic[resId] then
        self._ResItemDic[resId] = nil
    end
    
    -- 2. 清除 TaskGroups 缓存 (因为它里面存的是旧 Res 的 TaskGroup)
    -- 下次调用 GetTaskGroups 时会自动重新获取新的
    self._TaskGroups = nil 
end

function XSubpackage:InvalidateTaskGroupsCache()
    self._TaskGroups = nil
end

function XSubpackage:FileInitComplete()
    -- self._TaskGroup:AddFinishedSizeAfterAddTask(self._DownSize)
    self:InitState()
    -- self._RepeatName = nil
end

---@return XMTDownloadTaskGroup
function XSubpackage:GetTaskGroups()
    if self._TaskGroups then
        return self._TaskGroups
    end

    local res = {}
    for k, resItem in pairs(self._ResItemDic) do
        table.insert(res, resItem:GetTaskGroup())
    end
    self._TaskGroups = res
    return res
end

---@param center XMTDownloadCenter
function XSubpackage:OnStateChanged(resState)
    local state = nil
    local taskGroups = self:GetTaskGroups()
    if resState == CSXMTDownloadTaskGroupState.CompleteError then
        state = CSXMTDownloadTaskGroupState.CompleteError
    elseif self._WaitPause then
        local hasRegistered = false
        local hasComplete = false
        local hasOtherState = false
        for i = 1, #taskGroups do
            if taskGroups[i].State == CSXMTDownloadTaskGroupState.Registered then
                hasRegistered = true
            end
            if taskGroups[i].State == CSXMTDownloadTaskGroupState.Complete then
                hasComplete = true
            end
            if taskGroups[i].State ~= CSXMTDownloadTaskGroupState.Registered and taskGroups[i].State ~= CSXMTDownloadTaskGroupState.Complete then
                hasOtherState = true
            end

            if hasOtherState then
                return
            end
        end
        if hasRegistered or hasComplete then
            state = CSXMTDownloadTaskGroupState.Registered
        end
    else
        -- 同步所有ResItem的TaskGroup状态
        -- 先检查完成状态
        local isResStateComplete = true
        for k, resItem in pairs(self._ResItemDic) do
            if resItem:GetState() ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
                isResStateComplete = false
            end
        end

        if isResStateComplete then
            state = CSXMTDownloadTaskGroupState.Complete
        else
            state = taskGroups[1].State
            if #taskGroups > 1 then
                for i = 2, #taskGroups do
                    if taskGroups[i].State ~= state then
                        return
                    end
                    state = taskGroups[i].State
                end
            end
        end
    end

    -- print("SP/DN OnStateChanged", self._Id, resState, state, self._WaitPause)

    if state == CSXMTDownloadTaskGroupState.Registered and self._WaitPause then
        XMVCA.XSubPackage:OnDownloadRelease()
        self._WaitPause = false
    elseif state == CSXMTDownloadTaskGroupState.Complete then
        local formattedStrings = {}
        for i = 1, #taskGroups do
            -- 使用 string.format 来格式化单个任务组的信息，并将其添加到表中
            table.insert(formattedStrings, string.format("%s, %s\n", taskGroups[i].Id, taskGroups[i].State))
        end

        -- 最后使用 table.concat 将所有格式化的字符串合并为一个完整的字符串
        local stringRes = table.concat(formattedStrings)
        -- print("SP/DN OnStateChanged 全子Res 完成？\n ",stringRes)

        XMVCA.XSubPackage:OnComplete(self._Id)
        XMVCA.XSubPackage:OnDownloadRelease()
        self._WaitPause = false
    elseif state == CSXMTDownloadTaskGroupState.Pausing then
        self._WaitPause = true
    elseif state == CSXMTDownloadTaskGroupState.CompleteError then
        XMVCA.XSubPackage:DoDownloadError(self._Id)
        XMVCA.XSubPackage:OnDownloadRelease()
    end
end

--下载完成后，将对应的数据结构与C#引用置空
function XSubpackage:Release()
    for k, resItem in pairs(self._ResItemDic) do
        resItem:Release()
    end
end

return XSubpackage