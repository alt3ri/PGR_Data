----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateShowSelectDownload.lua
-- description: 模块更新 - 选择下载界面
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsInfo = CS.XInfo
local CsGameEventManager = CS.XGameEventManager.Instance

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateShowSelectDownload : XModuleUpdateStateBase
local XModuleUpdateStateShowSelectDownload = XLaunchConst.CreateMetaTable("XModuleUpdateStateShowSelectDownload", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateShowSelectDownload:OnEnter()
    self.XLaunchDlcManager = require("XLaunchDlcManager")
    if not self.XLaunchDlcManager.NeedShowSelect() then
        self:OnFinish()
        return
    end

    -- 基础包大小（index base table）
    local updateSize = self.UpdateManager:GetBaseDownloadSize()
    -- 全量包大小（base + index dlc table）
    local allUpdateSize = self.UpdateManager:GetTotalDownloadSize()
    if allUpdateSize <= 0 then
        self:OnFinish()
        return
    end

    local dlcIndexTable = self.UpdateManager.NewVersionDlcIndexTable
    if not dlcIndexTable or not next(dlcIndexTable) then
        CS.XLog.Warning("[XModuleUpdateStateShowSelectDownload] no dlc index table")
        self:OnFinish()
        return
    end

    local downloadAbMap = self.UpdateManager:GetDownloadABMap() or {}
    local downloadPatchMap = self.UpdateManager:GetDownloadPatchMap() or {}
    self.XLaunchDlcManager.CalculateDownloadSize(dlcIndexTable, downloadAbMap, downloadPatchMap)
    
    local notifyEventFunc
    notifyEventFunc = function(evt, data)
        CsGameEventManager:RemoveEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, notifyEventFunc)
        local isFullDownload, removeResIds
        if data.Length > 0 then
            isFullDownload = data[0]
        end
        if data.Length > 1 then
            removeResIds = data[1] or {}
        end
        self:OnDoneSelect(isFullDownload, removeResIds)
    end
    CsGameEventManager:RegisterEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, notifyEventFunc)
    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT, updateSize, allUpdateSize)
end

function XModuleUpdateStateShowSelectDownload:OnDoneSelect(isFullDownload, removeResIds)
    -- print("SP/DN OnDoneSelect", isFullDownload, UpdateTableCount, removeResIds, type(removeResIds) == "table" and table.unpack(removeResIds))
    self.XLaunchDlcManager.DoneSelect(CsInfo.Version)
    -- self.XLaunchDlcManager.SetIsFullDownload(isFullDownload)
    local hasRemoveResIds = removeResIds and type(removeResIds) == "table" and next(removeResIds)
    -- 防止版本更新时切换与上一次下载选项不同的情况错误读取到removeResIds
    self.XLaunchDlcManager.SetRemoveResIdsRecord(hasRemoveResIds and removeResIds or "", isFullDownload)
    if isFullDownload then
        self.XLaunchDlcManager.SetAllLaunchDownloadRecord()
    end

    self:OnFinish()
end

return XModuleUpdateStateShowSelectDownload
