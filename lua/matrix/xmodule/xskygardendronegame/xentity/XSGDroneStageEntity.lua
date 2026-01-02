local XSGDroneEntityBase = require("XModule/XSkyGardenDroneGame/XEntity/XSGDroneEntityBase")

---@class XSGDroneStageEntity : XSGDroneEntityBase
local XSGDroneStageEntity = XClass(XSGDroneEntityBase, "XSGDroneStageEntity")

function XSGDroneStageEntity:OnInit(stageId)
    self._StageId = stageId
end

function XSGDroneStageEntity:IsNil()
    return not XTool.IsNumberValid(self:GetStageId())
end

function XSGDroneStageEntity:IsComplete()
    if not self:IsNil() then
        if self:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
            local stageData = self._Model:GetStageData(self:GetStageId())
    
            if stageData then
                return stageData:IsFinish()
            end
        elseif self:GetType() == XMVCA.XSkyGardenDroneGame.StageType.MainLine then
            return self:IsPass()
        end
    end

    return false
end

function XSGDroneStageEntity:IsNew()
    return false
end

function XSGDroneStageEntity:IsSkip()
    if not self:IsNil() then
        return XTool.IsNumberValid(self:GetSkipId())
    end

    return false
end

function XSGDroneStageEntity:IsUnlock()
    local preStageId = self:GetPreStageId()

    if XTool.IsNumberValid(preStageId) then
        local chapterEntities = self._OwnControl:GetChapterEntities()

        if not XTool.IsTableEmpty(chapterEntities) then
            for _, chapterEntity in pairs(chapterEntities) do
                local stageEntity = chapterEntity:GetStageEntity(preStageId)
                
                if stageEntity then
                    return stageEntity:IsPass()
                end
            end
        end

        return false
    end

    local conditionId = self:GetConditionId()

    if XTool.IsNumberValid(conditionId) then
        return XMVCA.XBigWorldService:CheckCondition(conditionId)
    end

    return true
end

function XSGDroneStageEntity:IsTargetComplete(targetId)
    if not self:IsNil() then
        local stageData = self._Model:GetStageData(self:GetStageId())

        if stageData then
            return stageData:IsTargetFinish(targetId)
        end
    end

    return false
end

function XSGDroneStageEntity:IsPass()
    if not self:IsNil() then
        if self:IsUnlock() then
            if self:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
                if self:IsComplete() then
                    return true
                end

                local starTargetIds = self:GetStarTagetIds()
                
                if not XTool.IsTableEmpty(starTargetIds) then
                    return self:IsTargetComplete(starTargetIds[1])
                end
            elseif self:GetType() == XMVCA.XSkyGardenDroneGame.StageType.MainLine then
                local objectiveId = self:GetObjectiveId()
                local questId = self:GetQuestId()
                
                if XTool.IsNumberValid(questId) and XTool.IsNumberValid(objectiveId) then
                    return XMVCA.XBigWorldQuest:CheckObjectiveFinish(questId, objectiveId)
                end
            end
        end
    end

    return false
end

function XSGDroneStageEntity:IsEnableAssistance()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterIsEnableAssistanceById(self:GetChapterId()) or false
    end

    return false
end

function XSGDroneStageEntity:IsFirst()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageIsFirstById(self:GetStageId()) or false
    end

    return false
end

function XSGDroneStageEntity:GetStageId()
    return self._StageId
end

---@return XSGDroneChapterEntity
function XSGDroneStageEntity:GetChapterEntity()
    return self._ParentEntity
end

function XSGDroneStageEntity:GetChapterId()
    local chapterEntity = self:GetChapterEntity()

    if chapterEntity then
        return chapterEntity:GetChapterId()
    end

    return 0
end

function XSGDroneStageEntity:GetChapterNextStageEntity()
    local chapterEntity = self:GetChapterEntity()

    if chapterEntity then
        local stageEntities = chapterEntity:GetStageList()

        if not XTool.IsTableEmpty(stageEntities) then
            for _, stageEntity in pairs(stageEntities) do
                if stageEntity:GetPreStageId() == self:GetStageId() then
                    return stageEntity
                end
            end
        end
    end

    return nil
end

function XSGDroneStageEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageNameById(self:GetStageId())
    end

    return ""
end

function XSGDroneStageEntity:GetDesc()
    if not self:IsNil() then
        local desc = self._Model:GetSgDroneGameStageDescById(self:GetStageId())

        if not desc then
            return ""
        end

        return XUiHelper.ReplaceTextNewLine(desc)
    end

    return ""
end

function XSGDroneStageEntity:GetCostTime()
    if not self:IsNil() then
        local stageData = self._Model:GetStageData(self:GetStageId())

        if stageData then
            return stageData:GetMinCostTime()
        end
    end

    return 0
end

function XSGDroneStageEntity:GetType()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageTypeById(self:GetStageId())
    end

    return 0
end

function XSGDroneStageEntity:GetPreStageId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStagePreStageIdById(self:GetStageId())
    end

    return 0
end

function XSGDroneStageEntity:GetConditionId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageConditionById(self:GetStageId())
    end

    return 0
end

function XSGDroneStageEntity:GetMapId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageMapIdById(self:GetStageId())
    end

    return 0
end

function XSGDroneStageEntity:GetSkipId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageSkipIdById(self:GetStageId())
    end

    return 0
end

function XSGDroneStageEntity:GetIcon()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageIconUrlById(self:GetStageId())
    end

    return ""
end

function XSGDroneStageEntity:GetObjectiveId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageObjectiveIdById(self:GetStageId())
    end

    return 0
end

function XSGDroneStageEntity:GetQuestId()
    if not self:IsNil() then
        local objectiveId = self:GetObjectiveId()
        
        if XTool.IsNumberValid(objectiveId) then
            return XMVCA.XBigWorldQuest:GetQuestIdByObjectiveId(objectiveId)
        end
    end

    return 0
end

function XSGDroneStageEntity:GetEasyDroneHp()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterEasyDroneHpById(self:GetChapterId())
    end

    return 0
end

function XSGDroneStageEntity:GetHardModeText()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterHardModeTextById(self:GetChapterId())
    end

    return ""
end

function XSGDroneStageEntity:GetStarTagetIds()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageStarTargetsById(self:GetStageId())
    end

    return nil
end

function XSGDroneStageEntity:GetRewardIds()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameStageStarRewardIdsById(self:GetStageId())
    end

    return nil
end

function XSGDroneStageEntity:GetRewards()
    local rewardIds = self:GetRewardIds()
    local rewards = {}

    if not XTool.IsTableEmpty(rewardIds) then
        for _, rewardId in ipairs(rewardIds) do
            local reward = XRewardManager.GetRewardList(rewardId)

            if reward then
                table.insert(rewards, reward[1])
            end
        end
    end

    return rewards
end

function XSGDroneStageEntity:GetStarTargetIdByIndex(index)
    local starTargetIds = self:GetStarTagetIds()

    if not XTool.IsTableEmpty(starTargetIds) then
        return starTargetIds[index]
    end

    return 0
end

function XSGDroneStageEntity:GetCurrentStarCount()
    if not self:IsNil() then
        local stageData = self._Model:GetStageData(self:GetStageId())

        if stageData then
            local targetIds = self:GetStarTagetIds()

            if not XTool.IsTableEmpty(targetIds) then
                local currentCount = 0

                for _, targetId in pairs(targetIds) do
                    if stageData:IsTargetFinish(targetId) then
                        currentCount = currentCount + 1
                    end
                end

                return currentCount
            end
        end
    end

    return 0
end

function XSGDroneStageEntity:GetTotalStarCount()
    if not self:IsNil() then
        local starTargetIds = self:GetStarTagetIds()

        if not XTool.IsTableEmpty(starTargetIds) then
            return #starTargetIds
        end
    end

    return 0
end

return XSGDroneStageEntity
