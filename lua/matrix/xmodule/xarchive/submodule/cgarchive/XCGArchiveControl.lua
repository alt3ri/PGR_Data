--- CG图鉴的子control
---@class XCGArchiveControl: XControl
---@field private _Model XArchiveModel
---@field private _MainControl XArchiveControl
local XCGArchiveControl = XClass(XControl, 'XCGArchiveControl')

function XCGArchiveControl:OnInit()

end

function XCGArchiveControl:AddAgencyEvent()

end

function XCGArchiveControl:RemoveAgencyEvent()

end

function XCGArchiveControl:OnRelease()

end

--region ---------- 红点相关 ---------->>>

function XCGArchiveControl:ClearAllCGReddot()
    self._Model.ArchiveCGData:ClearAllCGReddot()
    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
end

function XCGArchiveControl:ClearCGRedPointByGroup(groupId)
    local list = self._Model:GetArchiveCGDetailList()[groupId]
    
    local hasClearAnyReddot = false
    
    if not XTool.IsTableEmpty(list) then
        ---@param cgDetail XArchiveCGEntity
        for i, cgDetail in pairs(list) do
            if self._Model.ArchiveCGData:ClearCGReddot(cgDetail:GetGroupId(), cgDetail.Id) then
                hasClearAnyReddot = true
            end
        end
    end

    if hasClearAnyReddot then
        self._Model.ArchiveCGData:SaveCGReddot()
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
    end
end

function XCGArchiveControl:ClearCGRedPointById(id)
    ---@type XArchiveCGEntity
    local cgDetailData = self._Model:GetArchiveCGDetailData()[id]

    if cgDetailData and cgDetailData:GetIsShowRedPoint() then
        if self._Model.ArchiveCGData:ClearCGReddot(cgDetailData:GetGroupId(), cgDetailData.Id) then
            self._Model.ArchiveCGData:SaveCGReddot()
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
        end
    end
end

--endregion <<<-------------------------

return XCGArchiveControl