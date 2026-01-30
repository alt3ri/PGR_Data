local XSGDroneEntityBase = require("XModule/XSkyGardenDroneGame/XEntity/XSGDroneEntityBase")
local XSGDroneStageEntity = require("XModule/XSkyGardenDroneGame/XEntity/XSGDroneStageEntity")

---@class XSGDroneChapterEntity : XSGDroneEntityBase
local XSGDroneChapterEntity = XClass(XSGDroneEntityBase, "XSGDroneChapterEntity")

function XSGDroneChapterEntity:OnInit(chapterId)
    self._ChapterId = chapterId
    ---@type XSGDroneStageEntity[]
    self._StageList = {}
    self:_InitStageList()
end

function XSGDroneChapterEntity:IsNil()
    return not XTool.IsNumberValid(self:GetChapterId())
end

function XSGDroneChapterEntity:IsFirstUnlock()
    if not self:IsUnlock() then
        return false
    end

    return self._Model:CheckChapterFirstUnlock(self:GetChapterId())
end

function XSGDroneChapterEntity:IsUnlock()
    local timeId = self:GetTimeId()

    if not XFunctionManager.CheckInTimeByTimeId(timeId, true) then
        return false
    end

    local conditionId = self:GetConditionId()

    if XTool.IsNumberValid(conditionId) then
        local isSuccess = XMVCA.XBigWorldService:CheckCondition(conditionId)

        if not isSuccess then
            return false
        end
    end

    local stageEntities = self:GetStageList()

    if not XTool.IsTableEmpty(stageEntities) then
        for _, stageEntity in pairs(stageEntities) do
            if stageEntity:IsUnlock() then
                return true
            end
        end
    end

    return false
end

function XSGDroneChapterEntity:IsComplete()
    if not self:IsUnlock() then
        return false
    end

    local stages = self:GetStageList()

    for _, stageEntity in pairs(stages) do
        if not stageEntity:IsComplete() then
            return false
        end
    end

    return true
end

function XSGDroneChapterEntity:IsNew()
    local stages = self:GetStageList()

    for _, stageEntity in pairs(stages) do
        if stageEntity:IsNew() then
            return true
        end
    end

    return false
end

function XSGDroneChapterEntity:GetChapterId()
    return self._ChapterId
end

function XSGDroneChapterEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterNameById(self:GetChapterId())
    end

    return ""
end

function XSGDroneChapterEntity:GetType()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterTypeById(self:GetChapterId())
    end

    return XMVCA.XSkyGardenDroneGame.ChapterType.Normal
end

function XSGDroneChapterEntity:GetTimeId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterTimeIdById(self:GetChapterId())
    end

    return 0
end

function XSGDroneChapterEntity:GetConditionId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterConditionById(self:GetChapterId())
    end

    return 0
end

function XSGDroneChapterEntity:GetTeachDroneId()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterTeachDroneIdById(self:GetChapterId())
    end

    return 0
end

function XSGDroneChapterEntity:GetIcon()
    if not self:IsNil() then
        return self._Model:GetSgDroneGameChapterIconUrlById(self:GetChapterId())
    end

    return ""
end

function XSGDroneChapterEntity:GetLockTip()
    local timeId = self:GetTimeId()

    if not XFunctionManager.CheckInTimeByTimeId(timeId, true) then
        return self._OwnControl:GetChapterLockTip(1)
    end

    local conditionId = self:GetConditionId()

    if XTool.IsNumberValid(conditionId) then
        local isSuccess, tip = XMVCA.XBigWorldService:CheckCondition(conditionId)

        if not isSuccess then
            return tip or ""
        end
    end

    local stageEntities = self:GetStageList()
    local isStageUnlock = false

    if not XTool.IsTableEmpty(stageEntities) then
        for _, stageEntity in pairs(stageEntities) do
            if stageEntity:IsUnlock() then
                isStageUnlock = true
                break
            end
        end
    end

    if not isStageUnlock then
        return self._OwnControl:GetChapterLockTip(2)
    end

    return ""
end

---@return XSGDroneStageEntity[]
function XSGDroneChapterEntity:GetStageList()
    return self._StageList
end

---@return XSGDroneStageEntity
function XSGDroneChapterEntity:GetStageEntity(stageId)
    for _, stageEntity in pairs(self:GetStageList()) do
        if stageEntity:GetStageId() == stageId then
            return stageEntity
        end
    end

    return nil
end

function XSGDroneChapterEntity:GetCurrentStarCount()
    local starCount = 0

    for _, stageEntity in pairs(self:GetStageList()) do
        starCount = starCount + stageEntity:GetCurrentStarCount()
    end

    return starCount
end

function XSGDroneChapterEntity:GetTotalStarCount()
    local starCount = 0

    for _, stageEntity in pairs(self:GetStageList()) do
        starCount = starCount + stageEntity:GetTotalStarCount()
    end

    return starCount
end

function XSGDroneChapterEntity:GetStarProgressText()
    local currentStarCount = self:GetCurrentStarCount()
    local totalStarCount = self:GetTotalStarCount()

    return string.format("<color=#030303>%d</color>/%d", currentStarCount, totalStarCount)
end

function XSGDroneChapterEntity:RecordUnlock()
    if self:IsUnlock() then
        self._Model:RecordChapterUnlock(self:GetChapterId())
    end
end

function XSGDroneChapterEntity:_InitStageList()
    if not self:IsNil() then
        local stageIdList = self._Model:GetSgDroneGameChapterStageIdsById(self:GetChapterId())
        
        if not XTool.IsTableEmpty(stageIdList) then
            for _, stageId in pairs(stageIdList) do
                table.insert(self._StageList, self:AddChildEntity(XSGDroneStageEntity, stageId))
            end
        end
    end
end

return XSGDroneChapterEntity
