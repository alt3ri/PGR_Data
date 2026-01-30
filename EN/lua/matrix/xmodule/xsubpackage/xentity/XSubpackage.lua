local XLaunchDlcManager = require("XLaunchDlcManager")

---@class XSubpackage 分包数据
---@field _Id number
---@field _State number
---@field _TotalSize number
local XSubpackage = XClass(nil, "XSubpackage")

function XSubpackage:Ctor(packageId)
    self._Id = packageId
    self._TotalSize = -1
    self._DownSize = 0
    self._WaitPause = false
    self._MaxProgress = 0
    ---@type XResource[]
    self._ResItemDic = {}
    self._TaskGroups = nil
end

function XSubpackage:InitState()
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
    return math.max(self:GetProgress(), self._MaxProgress)
end

function XSubpackage:UpdateMaxProgress()
    local prg = 0
    for k, resItem in pairs(self._ResItemDic) do
        prg = prg + resItem:GetMaxProgress()
    end
    self._MaxProgress = math.max(prg, self._MaxProgress)
end

-- 下载过程中，临时文件可能出错，删除掉会导致进度减少
function XSubpackage:IsProgressLess()
    return self:GetProgress() < self._MaxProgress
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

function XSubpackage:StartResDownload()
    for resId, resItem in pairs(self._ResItemDic) do
        if resItem:GetState() ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
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
    if resState == CS.XMTDownloadTaskGroupState.CompleteError then
        state = CS.XMTDownloadTaskGroupState.CompleteError
    elseif self._WaitPause then
        local hasRegistered = false
        local hasComplete = false
        local hasOtherState = false
        for i = 1, #taskGroups do
            if taskGroups[i].State == CS.XMTDownloadTaskGroupState.Registered then
                hasRegistered = true
            end
            if taskGroups[i].State == CS.XMTDownloadTaskGroupState.Complete then
                hasComplete = true
            end
            if taskGroups[i].State ~= CS.XMTDownloadTaskGroupState.Registered and taskGroups[i].State ~= CS.XMTDownloadTaskGroupState.Complete then
                hasOtherState = true
            end

            if hasOtherState then
                return
            end
        end
        if hasRegistered or hasComplete then
            state = CS.XMTDownloadTaskGroupState.Registered
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
            state = CS.XMTDownloadTaskGroupState.Complete
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

    if state == CS.XMTDownloadTaskGroupState.Registered and self._WaitPause then
        XMVCA.XSubPackage:OnDownloadRelease()
        self._WaitPause = false
    elseif state == CS.XMTDownloadTaskGroupState.Complete then
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
    elseif state == CS.XMTDownloadTaskGroupState.Pausing then
        self._WaitPause = true
    elseif state == CS.XMTDownloadTaskGroupState.CompleteError then
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