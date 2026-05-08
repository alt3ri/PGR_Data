---@class XBigWorldQuestControl : XControl
---@field private _Model XBigWorldQuestModel
local XBigWorldQuestControl = XClass(XControl, "XBigWorldQuestControl")

local pairs = pairs

function XBigWorldQuestControl:OnInit()
end

function XBigWorldQuestControl:AddAgencyEvent()
end

function XBigWorldQuestControl:RemoveAgencyEvent()

end

function XBigWorldQuestControl:OnRelease()
end

function XBigWorldQuestControl:GetMainLineTipDesc(tipId)
    local template = self._Model:GetMainLineTipTemplate(tipId)
    return template and template.Desc or ""
end

function XBigWorldQuestControl:GetMainLineTipTemplate(tipId)
    return self._Model:GetMainLineTipTemplate(tipId)
end

function XBigWorldQuestControl:GetQuestTypeIds()
    return self._Model:GetQuestTypeIds()
end

function XBigWorldQuestControl:GetQuestTypeColorStr(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.Color or ""
end

function XBigWorldQuestControl:GetQuestTypeIcon(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.Icon or ""
end

function XBigWorldQuestControl:GetQuestTypeBriefIcon(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.BriefIcon or ""
end

function XBigWorldQuestControl:GetQuestTypeName(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.Name or ""
end

function XBigWorldQuestControl:GetQuestTypeBigIcon(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.BigIcon or ""
end

function XBigWorldQuestControl:GetGroupIdsByTypeId(typeId)
    return self._Model:GetGroupIdsByTypeId(typeId)
end

function XBigWorldQuestControl:GetGroupName(groupId)
    return self._Model:GetGroupName(groupId)
end

function XBigWorldQuestControl:GetGroupIcon(groupId)
    return self._Model:GetGroupIcon(groupId)
end

function XBigWorldQuestControl:GetQuestName(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.Name or ""
end

function XBigWorldQuestControl:GetQuestRewardId(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.RewardId or 0
end

function XBigWorldQuestControl:GetQuestType(questId)
    return self:GetAgency():GetQuestTypeByQuestId(questId)
end

function XBigWorldQuestControl:GetQuestDesc(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.Desc or 0
end

function XBigWorldQuestControl:GetQuestFirstStepId(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.FirstStepId or 0
end

function XBigWorldQuestControl:GetQuestIcon(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.QuestIcon
end

function XBigWorldQuestControl:GetQuestState(questId)
    local questData = self._Model:GetQuestData(questId)
    return questData:GetState()
end

function XBigWorldQuestControl:GetGroupIdByQuestId(questId)
    return self._Model:GetGroupIdByQuestId(questId, true)
end

function XBigWorldQuestControl:IsTrackQuest(questId)
    return self._Model:IsTrackQuest(questId)
end

---@return XBigWorldQuestStep[]
function XBigWorldQuestControl:GetActiveStepData(questId)
    local questData = self._Model:GetQuestData(questId)
    return questData:GetActiveStepData()
end

function XBigWorldQuestControl:GetReceiveQuestIds()
    return self._Model:GetReceiveQuestIds()
end

function XBigWorldQuestControl:GetQuestIdsByGroupId(groupId, questIds)
    questIds = questIds or self:GetReceiveQuestIds()
    if XTool.IsTableEmpty(questIds) then
        return
    end

    local list
    for _, questId in pairs(questIds) do
        local gId = self:GetGroupIdByQuestId(questId, true)
        if gId > 0 and gId == groupId then
            if not list then
                list = {}
            end
            list[#list + 1] = questId
        end
    end

    return list
end

function XBigWorldQuestControl:GetStepReward(stepId)
    local template = self._Model:GetQuestStepTemplate(stepId)
    return template and template.RewardId or 0
end

function XBigWorldQuestControl:GetStepText(stepId)
    return self._Model:GetQuestStepText(stepId)
end

function XBigWorldQuestControl:GetStepLocation(stepId)
    return XMVCA.XBigWorldQuest:GetStepLocation(stepId)
end

function XBigWorldQuestControl:GetStepData(questId, stepId)
    local questData = self._Model:GetQuestData(questId)
    local stepData = questData:TryGetStep(stepId)
    return stepData
end

function XBigWorldQuestControl:GetObjectiveTitle(objectiveId)
    return self._Model:GetObjectiveTitle(objectiveId)
end

function XBigWorldQuestControl:GetObjectiveDescription(objectiveId)
    local t = self._Model:GetQuestStepObjectiveTemplate(objectiveId)
    return t and t.Description or ""
end

function XBigWorldQuestControl:GetObjectiveProgressDesc(objectiveId, progress, max)
    return XMVCA.XBigWorldQuest:GetObjectiveProgressDesc(objectiveId, progress, max)
end

function XBigWorldQuestControl:GetChapterId()
    -- 第一期没有章节概念，后续会改成读表
    return 1001
end

function XBigWorldQuestControl:GetChapterUrl(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.ChapterUrl or ""
end

function XBigWorldQuestControl:GetChapterFullBg(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.FullBg or ""
end

function XBigWorldQuestControl:GetChapterMapName(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.MapName or ""
end

function XBigWorldQuestControl:GetChapterName(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.ChapterName or ""
end

function XBigWorldQuestControl:GetChapterArchiveIds(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.ArchiveIds or nil
end

function XBigWorldQuestControl:GetQuestIdByArchiveId(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.QuestId or 0
end

function XBigWorldQuestControl:GetPreQuestIdByArchiveId(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.PreQuestId or 0
end

function XBigWorldQuestControl:GetArchiveIcon(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.Icon or 0
end

function XBigWorldQuestControl:GetArchiveCompleteText(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.CompleteText or 0
end

--region 邀约任务
function XBigWorldQuestControl:GetInviteIds()
    return self._Model:GetInviteIds()
end

function XBigWorldQuestControl:GetInviteQuestPriority(id)
    return self._Model:GetInviteQuestPriority(id)
end

function XBigWorldQuestControl:GetInviteQuestCondition(id)
    return self._Model:GetInviteQuestCondition(id)
end

function XBigWorldQuestControl:GetInviteQuestModelId(id)
    return self._Model:GetInviteQuestModelId(id)
end

function XBigWorldQuestControl:GetInviteQuestRolePath(id)
    return self._Model:GetInviteQuestRolePath(id)
end

function XBigWorldQuestControl:GetInviteQuestTotalRewardId(id)
    return self._Model:GetInviteQuestTotalRewardId(id)
end

function XBigWorldQuestControl:GetInviteQuestResultIds(id)
    return self._Model:GetInviteQuestResultIds(id)
end

function XBigWorldQuestControl:GetInviteQuestResultName(id)
    return self._Model:GetInviteQuestResultName(id)
end

function XBigWorldQuestControl:GetInviteQuestResultBanner(id)
    return self._Model:GetInviteQuestResultBanner(id)
end

function XBigWorldQuestControl:GetInviteQuestResultDesc(id)
    return self._Model:GetInviteQuestResultDesc(id)
end

function XBigWorldQuestControl:GetInviteQuestResultCGAsset(id)
    return self._Model:GetInviteQuestResultCGAsset(id)
end

function XBigWorldQuestControl:GetInviteQuestResultRewardId(id)
    return self._Model:GetInviteQuestResultRewardId(id)
end

function XBigWorldQuestControl:GetInviteQuestPopTipText(id)
    local tip = self._Model:GetInviteQuestPopTipText(id)
    if string.IsNilOrEmpty(tip) then
        return tip
    end
    return XUiHelper.ReplaceTextNewLine(tip)
end

function XBigWorldQuestControl:GetInviteQuestTipText(id)
    local tip = self._Model:GetInviteQuestTipText(id)
    if string.IsNilOrEmpty(tip) then
        return tip
    end
    return XUiHelper.ReplaceTextNewLine(tip)
end

function XBigWorldQuestControl:RequestAcceptInviteQuest(questId, func)
    XNetwork.Call("DlcInviteQuestAcceptRequest", { QuestId = questId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if func then
            func()
        end
    end)
end

function XBigWorldQuestControl:RequestReceiveInviteReward(questId, func)
    if not questId or questId <= 0 then
        XLog.Error("XBigWorldQuestControl:GetInviteQuestResultRewardId questId is nil or 0, questId = ", questId)
        return
    end
    local isReceived = self._Model:CheckInviteRewardReceived(questId)
    if isReceived then
        XLog.Error("XBigWorldQuestControl:GetInviteQuestResultRewardId reward is received, inviteId = ", inviteId)
        return
    end
    local results = self._Model:GetInviteQuestResultIds(questId)
    local count = results and #results or 0
    
    XNetwork.Call("DlcInviteQuestResultNumRewardRequest", { QuestId = questId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:ReceiveInviteReward(questId, count)
        if func then
            func()
        end
    end)
end
--endregion 邀约任务

return XBigWorldQuestControl