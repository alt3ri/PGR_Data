---@class XBigWorldCharacterTrialData
local XBigWorldCharacterTrialData = XClass(nil, "XBigWorldCharacterTrialData")

function XBigWorldCharacterTrialData:Ctor()
    self._TrialCharacterMap = {}
    self._SelfCharacterIds = {}
    self._DisplayCharacterId = 0
    self._IsTrialCoverTeam = false
end

function XBigWorldCharacterTrialData:AddSelfCharacterId(characterId)
    if self:IsTrialCharacter(characterId) then
        self._SelfCharacterIds[characterId] = true
    end
end

function XBigWorldCharacterTrialData:RemoveSelfCharacterId(characterId)
    self._SelfCharacterIds[characterId] = nil
end

function XBigWorldCharacterTrialData:IsSelfCharacter(characterId)
    if not XTool.IsNumberValid(characterId) then
        return false
    end

    return self._SelfCharacterIds[characterId] or false
end

function XBigWorldCharacterTrialData:AddTrialCharacterId(characterId)
    self._TrialCharacterMap[characterId] = true
end

function XBigWorldCharacterTrialData:RemoveTrialCharacterId(characterId)
    self._TrialCharacterMap[characterId] = nil
end

function XBigWorldCharacterTrialData:IsTrialCharacter(characterId)
    if not XTool.IsNumberValid(characterId) then
        return false
    end

    return self._TrialCharacterMap[characterId] or false
end

function XBigWorldCharacterTrialData:SetIsTrialCoverTeam(isCover)
    self._IsTrialCoverTeam = isCover or false
end

function XBigWorldCharacterTrialData:IsTrialCoverTeam()
    return self._IsTrialCoverTeam
end

function XBigWorldCharacterTrialData:SetDisplayCharacterId(characterId)
    if self:IsTrialCharacter(characterId) then
        self._DisplayCharacterId = characterId or 0
    end
end

function XBigWorldCharacterTrialData:GetDisplayCharacterId()
    return self._DisplayCharacterId
end

function XBigWorldCharacterTrialData:IsDisplayCharacter()
    local displayCharacterId = self:GetValidDisplayCharacterId()

    if XTool.IsNumberValid(displayCharacterId) then
        return not self:IsSelfCharacter(displayCharacterId)
    end

    return false
end

function XBigWorldCharacterTrialData:GetValidDisplayCharacterId()
    local displayCharacterId = self:GetDisplayCharacterId()

    if XTool.IsNumberValid(displayCharacterId) then
        if self:IsTrialCharacter(displayCharacterId) then
            return displayCharacterId
        end
    end

    if not XTool.IsTableEmpty(self._TrialCharacterMap) then
        for characterId, _ in pairs(self._TrialCharacterMap) do
            if not self:IsSelfCharacter(characterId) then
                return characterId
            end
        end
    end

    return 0
end

function XBigWorldCharacterTrialData:Clear()
    self._TrialCharacterMap = {}
    self._SelfCharacterIds = {}
    self._DisplayCharacterId = 0
    self._IsTrialCoverTeam = false
end

return XBigWorldCharacterTrialData