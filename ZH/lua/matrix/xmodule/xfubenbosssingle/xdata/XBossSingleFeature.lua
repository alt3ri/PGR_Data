---@class XBossSingleFeature
local XBossSingleFeature = XClass(nil, "XBossSingleFeature")

function XBossSingleFeature:Ctor(featureId, stageId, characterIds)
    self:SetData(featureId, stageId, characterIds)
end

---@param config XTableBossSingleChallengeFeature
function XBossSingleFeature:SetData(featureId, stageId, characterIds)
    if featureId and stageId then
        local config = XMVCA.XFubenBossSingle:GetFeatureConfigById(featureId)
        local eventIds = config.FightEventIds
        local stageData = XMVCA.XFuben:GetStageData(stageId)

        self._FeatureId = config.Id
        self._Name = config.Name
        self._Desc = config.Desc
        self._Icon = config.Icon
        self._TriangleBg = config.TriangleBg
        self._Type = config.Type or 1  -- v4.2 新增：type=1表示原本功能，type=2表示可选择词缀
        self._ScoreRate = config.ScoreRate or 1  -- v4.2 新增：讨伐值倍率
        self._TotalScore = XMVCA.XFubenBossSingle:GetStageTotalScoreByStageId(stageId)
        self._StageId = stageId
        self._Score = stageData and stageData.Score or 0
        self._FightEventIds = {}
        self._CharacterList = characterIds or {}
        self._IsRecording = false

        if not XTool.IsTableEmpty(eventIds) then
            for _, eventId in pairs(eventIds) do
                table.insert(self._FightEventIds, eventId)
            end
        end
    end
end

function XBossSingleFeature:GetFeatureId()
    return self._FeatureId
end

function XBossSingleFeature:GetName()
    return self._Name
end

function XBossSingleFeature:GetDesc()
    return self._Desc
end

function XBossSingleFeature:GetIcon()
    return self._Icon
end

function XBossSingleFeature:GetTriangleBg()
    return self._TriangleBg
end

function XBossSingleFeature:GetTotalScore()
    return self._TotalScore
end

function XBossSingleFeature:GetStageId()
    return self._StageId
end

function XBossSingleFeature:GetScore()
    return self._Score
end

function XBossSingleFeature:GetFightEventIds()
    return self._FightEventIds
end

function XBossSingleFeature:GetFightEventIdByIndex(index)
    return self._FightEventIds[index or 1]
end

function XBossSingleFeature:GetIsCharacterEmpty()
    return XTool.IsTableEmpty(self._CharacterList)
end

function XBossSingleFeature:GetCharacterList()
    return self._CharacterList
end

function XBossSingleFeature:GetCharacterByIndex(index)
    return self._CharacterList[index or 1]
end

function XBossSingleFeature:SetIsRecording(value)
    self._IsRecording = value
end

function XBossSingleFeature:GetIsRecording()
    return self._IsRecording
end

function XBossSingleFeature:GetIsRecord()
    return not (self:GetIsCharacterEmpty() and self:GetScore() == 0)
end

--- v4.2 新增：获取词缀类型（type=1表示原本功能，type=2表示可选择词缀）
---@return number
function XBossSingleFeature:GetType()
    return self._Type or 1
end

--- v4.2 新增：判断是否为可选择词缀
---@return boolean
function XBossSingleFeature:IsSelectable()
    return self:GetType() == 2
end

--- v4.2 新增：获取讨伐值倍率
---@return number
function XBossSingleFeature:GetScoreRate()
    return self._ScoreRate or 1
end

function XBossSingleFeature:CheckCharacterClash(characterId)
    if self:GetIsCharacterEmpty() then
        return false
    else
        for _, id in pairs(self._CharacterList) do
            if id == characterId then
                return true
            end
        end

        return false
    end
end

return XBossSingleFeature
