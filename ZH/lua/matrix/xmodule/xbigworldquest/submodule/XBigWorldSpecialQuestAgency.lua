---@type XBigWorldQuestAgency
local XBigWorldQuestAgency = XClassPartial("XBigWorldQuestAgency")

local RecordInvitePopup = {}

--region 邀约任务

function XBigWorldQuestAgency:GetInviteIds()
    return self._Model:GetInviteIds()
end

function XBigWorldQuestAgency:CheckAllInviteFinish()
    local inviteIds = self._Model:GetInviteIds()
    if XTool.IsTableEmpty(inviteIds) then
        return true
    end
    for _, inviteId in ipairs(inviteIds) do
        if not self:CheckInviteFinish(inviteId) then
            return false
        end
    end
    return true
end

function XBigWorldQuestAgency:GetAllInviteProgress()
    local inviteIds = self._Model:GetInviteIds()
    if XTool.IsTableEmpty(inviteIds) then
        return 0, 0
    end
    local finish, sum = 0, 0
    for _, inviteId in ipairs(inviteIds) do
        local resFinish, resSum = self:GetInviteProgress(inviteId)
        finish = finish + resFinish
        sum = sum + resSum
    end
    return finish, sum
end

function XBigWorldQuestAgency:GetInviteProgress(inviteId)
    local finish, sum = 0, 0
    local resultIds = self._Model:GetInviteQuestResultIds(inviteId)
    if not XTool.IsTableEmpty(resultIds) then
        for _, resultId in ipairs(resultIds) do
            if self:CheckInviteResultFinish(resultId) then
                finish = finish + 1
            end
            sum = sum + 1
        end
    end
    return finish, sum
end

function XBigWorldQuestAgency:GetInviteQuestResultIds(inviteId)
    return self._Model:GetInviteQuestResultIds(inviteId)
end

function XBigWorldQuestAgency:CheckInviteFinish(inviteId)
    local resultIds = self._Model:GetInviteQuestResultIds(inviteId)
    if XTool.IsTableEmpty(resultIds) then
        return true
    end
    for _, resultId in ipairs(resultIds) do
        if not self:CheckInviteResultFinish(resultId) then
            return false
        end
    end
    return true
end

function XBigWorldQuestAgency:CheckInviteResultFinish(resultId)
    return self._Model:CheckInviteResultFinish(resultId)
end

function XBigWorldQuestAgency:IsFirstFinishResult()
    return self._Model:IsFirstFinishResult()
end

function XBigWorldQuestAgency:CheckInviteRewardReceived(questId)
    return self._Model:CheckInviteRewardReceived(questId)
end

function XBigWorldQuestAgency:OpenInvitationView(questId)
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldInviteQuest, true) then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskMainInvitation", questId)
end

function XBigWorldQuestAgency:OpenInvitationDetail(questId, resultId, isSequence, showTagNew)
    if isSequence then
        return XMVCA.XBigWorldUI:OpenWithFightSequence("UiBigWorldTaskPopupEndingDetail", false, questId, resultId,
            showTagNew)
    end
    return XMVCA.XBigWorldUI:Open("UiBigWorldTaskPopupEndingDetail", questId, resultId, showTagNew)
end

function XBigWorldQuestAgency:OpenInvitationPopup(questId)
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskObtainInvitation", questId)
end

function XBigWorldQuestAgency:IsUnderTakenInviteQuest()
    return self._Model:IsUnderTakenInviteQuest()
end

function XBigWorldQuestAgency:CheckPhotoQuestNeedUpload()
    return self._Model:CheckPhotoQuestNeedUpload()
end

--endregion 邀约任务

--region 环境任务

function XBigWorldQuestAgency:RequestEnvironmentQuestGroupChange(levelId, groupId, callback)
    if not XTool.IsNumberValid(levelId) or not XTool.IsNumberValid(groupId) then
        return
    end

    XNetwork.Call("DlcEnvironmentQuestGroupChangeRequest", {
        LevelId = levelId,
        QuestGroupId = groupId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateEnvironmentOnDuty(res.EnvironmentQuestData)
        if callback then
            callback()
        end
    end)
end

function XBigWorldQuestAgency:UpdateEnvironmentOnDuty(data)
    self._Model:UpdateEnvironmentOnDuty(data)
end

function XBigWorldQuestAgency:GetEnvironmentIds()
    return self._Model:GetEnvironmentIds()
end

function XBigWorldQuestAgency:GetEnvironmentIdsByGroup(groupId)
    return self._Model:GetEnvironmentIdsByGroup(groupId)
end

function XBigWorldQuestAgency:CheckAllEnvironmentFinish()
    local environmentIds = self._Model:GetEnvironmentIds()
    if XTool.IsTableEmpty(environmentIds) then
        return true
    end
    for _, environmentId in ipairs(environmentIds) do
        if not self:CheckEnvironmentFinish(environmentId) then
            return false
        end
    end
    return true
end

function XBigWorldQuestAgency:CheckEnvironmentFinish(id)
    local objectiveIds = self._Model:GetEnvironmentQuestObjectiveIds(id)
    if XTool.IsTableEmpty(objectiveIds) then
        return true
    end
    for _, objectiveId in ipairs(objectiveIds) do
        local questId = XMVCA.XBigWorldQuest:GetQuestIdByObjectiveId(objectiveId)
        if not self:CheckObjectiveFinish(questId, objectiveId) then
            return false
        end
    end
    return true
end

function XBigWorldQuestAgency:GetAllEnvironmentProgress()
    local environmentIds = self._Model:GetEnvironmentIds()
    if XTool.IsTableEmpty(environmentIds) then
        return 0, 0
    end
    local finish, sum = 0, 0
    for _, id in ipairs(environmentIds) do
        local resFinish, resSum = self:GetEnvironmentProgress(id)
        finish = finish + resFinish
        sum = sum + resSum
    end
    return finish, sum
end

function XBigWorldQuestAgency:GetEnvironmentProgress(id)
    local finish, sum = 0, 0
    local objectiveIds = self._Model:GetEnvironmentQuestObjectiveIds(id)
    if not XTool.IsTableEmpty(objectiveIds) then
        for _, objectiveId in ipairs(objectiveIds) do
            local questId = XMVCA.XBigWorldQuest:GetQuestIdByObjectiveId(objectiveId)
            if self:CheckObjectiveFinish(questId, objectiveId) then
                finish = finish + 1
            end
            sum = sum + 1
        end
    end
    return finish, sum
end

function XBigWorldQuestAgency:OpenEnvironmentPopupView(id)
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupEnvironmentalStory", id)
end

--endregion 环境任务

--region 配置相关
function XBigWorldQuestAgency:GetInviteQuestRoleIcon(inviteId, noTips)
    return self._Model:GetInviteQuestRoleIcon(inviteId, noTips)
end

function XBigWorldQuestAgency:IsInviteQuest(questId)
    if not questId or questId <= 0 then
        return false
    end
    return self:GetQuestCategory(questId) == self.QuestCategory.InviteQuest
end

function XBigWorldQuestAgency:GetInviteQuestName(inviteId)
    return self._Model:GetInviteQuestName(inviteId)
end

function XBigWorldQuestAgency:GetEnvironmentQuestRoleIcon(id)
    return self._Model:GetEnvironmentQuestRoleIcon(id)
end

function XBigWorldQuestAgency:GetEnvironmentQuestPriority(id)
    return self._Model:GetEnvironmentQuestPriority(id)
end

function XBigWorldQuestAgency:GetEnvironmentQuestGroupId(id)
    return self._Model:GetEnvironmentQuestGroupId(id)
end

function XBigWorldQuestAgency:GetEnvironmentQuestShowReward(id)
    return self._Model:GetEnvironmentQuestShowReward(id)
end

function XBigWorldQuestAgency:GetEnvironmentQuestName(id)
    return self._Model:GetEnvironmentQuestName(id)
end

function XBigWorldQuestAgency:GetEnvironmentQuestSkipId(id)
    return self._Model:GetEnvironmentQuestSkipId(id)
end

---@return XTableDlcEnvironmentQuestLevel[]
function XBigWorldQuestAgency:GetEnvironmentQuestGroupLevelConfigs()
    local levelConfigs = self._Model:GetEnvironmentQuestGroupLevelConfigs()
    local result = {}

    for _, config in pairs(levelConfigs) do
            local conditionId = config.ConditionId

            if not XTool.IsNumberValid(conditionId) or XMVCA.XBigWorldService:CheckCondition(conditionId) then
                table.insert(result, config)
            end
        end

    return result
end

---@return XTableDlcEnvironmentQuestGroup
function XBigWorldQuestAgency:GetEnvironmentQuestGroupTemplate(groupId)
    return self._Model:GetEnvironmentQuestGroupTemplate(groupId)
end

function XBigWorldQuestAgency:GetEnvironmentQuestGroupLevelId(groupId)
    return self._Model:GetEnvironmentQuestGroupLevelId(groupId)
end

function XBigWorldQuestAgency:GetRecordEnvironmentalGroup(levelId)
    return self._Model:GetRecordEnvironmentalGroup(levelId)
end

function XBigWorldQuestAgency:SetRecordEnvironmentalGroup(levelId)
    return self._Model:SetRecordEnvironmentalGroup(levelId)
end

function XBigWorldQuestAgency:SaveEnvironmentalGroupNews(levelId)
    return self._Model:SaveEnvironmentalGroupNews(levelId)
end

function XBigWorldQuestAgency:GetEnvironmentQuestGroupOnDuty(levelId)
    return self._Model:GetEnvironmentOnDuty(levelId)
end

--endregion

function XBigWorldQuestAgency:IsInvitePopped(questId)
    return RecordInvitePopup[questId] ~= nil
end

function XBigWorldQuestAgency:SetInvitePopup(questId)
    RecordInvitePopup[questId] = true
end
