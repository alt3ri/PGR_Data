local XBigWorldCharacterUiEffectInfo = require("XModule/XBigWorldCharacter/Data/XBigWorldCharacterUiEffectInfo")

local XBigWorldCharacter

---@class XBigWorldCharacterModel : XModel
---@field _CharDict table<number, XBigWorldCharacter>
local XBigWorldCharacterModel = XClass(XModel, "XBigWorldCharacterModel")

local pairs = pairs

local TableCharacter = {
    BigWorldCharacter = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCharacterUiEffect = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
}

local TableFashion = {
    BigWorldFashion = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldCharacterModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Character", TableCharacter)
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Fashion", TableFashion)
    self:ResetData()
end

function XBigWorldCharacterModel:ClearPrivate()
end

function XBigWorldCharacterModel:ResetAll()
    self:ResetData()
end

function XBigWorldCharacterModel:ResetData()
    self._TrialCharacterIds = {}
    self._TrialCharacterMap = {}
    self._IsTrialCoverTeam = false

    self._UnlockRoleDict = {}
    self._AllRoleIds = false
    self._CurrentTeamId = 0

    self._CharDict = {}

    ---@type table<number, XBigWorldCharacterUiEffectInfo[]>
    self._CharacterUiEffectMap = false
end

function XBigWorldCharacterModel:GetCurrentTeamId()
    return self._CurrentTeamId
end

function XBigWorldCharacterModel:SetCurrentTeamId(teamId)
    self._CurrentTeamId = teamId or 0
end

--- 获取Dlc角色配置
---@param characterId number
---@return XTableBigWorldCharacter
--------------------------
function XBigWorldCharacterModel:GetDlcCharacterTemplate(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableCharacter.BigWorldCharacter, characterId)
end

function XBigWorldCharacterModel:IsCommandant(characterId)
    local t = self:GetDlcCharacterTemplate(characterId)
    return t and t.IsCommandant or false
end

--- 获取全部角色(不包含指挥官)
---@return number[]
--------------------------
function XBigWorldCharacterModel:GetAllRoleIds()
    if self._AllRoleIds then
        return self._AllRoleIds
    end

    local list = {}
    ---@type table<number, XTableBigWorldCharacter>
    local templates = self._ConfigUtil:GetByTableKey(TableCharacter.BigWorldCharacter)
    for id, _ in pairs(templates) do
        if not self:IsCommandant(id) then
            list[#list + 1] = id
        end
    end
    self._AllRoleIds = list
    return list
end

function XBigWorldCharacterModel:IsRoleUnlock(characterId)
    if self._UnlockRoleDict[characterId] then
        return true
    end
    local t = self:GetDlcCharacterTemplate(characterId)
    local conditionId = t.Condition
    if not XTool.IsNumberValid(conditionId) then
        self._UnlockRoleDict[characterId] = true
        return true
    end
    local ret, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
    if ret then
        self._UnlockRoleDict[characterId] = true
        return true
    end

    return false
end

--- 获取Dlc时装配置
---@param fashionId number
---@return XTableBigWorldFashion
--------------------------
function XBigWorldCharacterModel:GetDlcFashionTemplate(fashionId, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableFashion.BigWorldFashion, fashionId, noTips)
end

function XBigWorldCharacterModel:GetFashionId(characterId)
    local t = self:GetDlcCharacterTemplate(characterId)
    if not t then
        return 0
    end
    if self:IsCommandant(characterId) then
        return XMVCA.XBigWorldCommanderDIY:GetCurrentFashionId()
    end
    -- 空花单独设置的涂装
    local char = self:GetDlcCharacter(characterId)
    local fashionId = char:GetFashionId()
    if fashionId and fashionId > 0 then
        return fashionId
    end
    ----角色未拥有
    -- local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
    -- if not isOwn then
    --    fashionId = t.DefaultFashionId
    -- else
    --    local character = XMVCA.XCharacter:GetCharacter(characterId)
    --    --随机涂装，则采用配置
    --    if character.RandomFashion then
    --        fashionId = t.DefaultFashionId
    --    else
    --        fashionId = character.FashionId
    --    end
    -- end
    fashionId = t.DefaultFashionId
    char:SetFashionId(fashionId)
    return fashionId
end

function XBigWorldCharacterModel:GetDefaultFashionId(characterId)
    if self:IsCommandant(characterId) then
        return XMVCA.XBigWorldCommanderDIY:GetCurrentFashionId()
    end
    local t = self:GetDlcCharacterTemplate(characterId)
    return t.DefaultFashionId
end

function XBigWorldCharacterModel:GetHeadInfo(characterId)
    local char = self:GetDlcCharacter(characterId)
    local info = char:GetHeadInfo()
    if info then
        return info
    end
    info = {
        HeadFashionId = self:GetDefaultFashionId(characterId),
        HeadFashionType = XFashionConfigs.HeadPortraitType.Default,
    }
    char:SetHeadInfo(info.HeadFashionId, info.HeadFashionType)

    return info
end

function XBigWorldCharacterModel:GetDlcCharacter(id)
    if self._CharDict[id] then
        return self._CharDict[id]
    end
    if not XBigWorldCharacter then
        XBigWorldCharacter = require("XModule/XBigWorldCharacter/Data/XBigWorldCharacter")
    end
    local char = XBigWorldCharacter.New(id)
    self._CharDict[id] = char

    return char
end

-- region CharacterUiEffect

---@return XTableBigWorldCharacterUiEffect[]
function XBigWorldCharacterModel:GetDlcCharacterUiEffectTemplates()
    return self._ConfigUtil:GetByTableKey(TableCharacter.BigWorldCharacterUiEffect) or {}
end

---@return table<number, XBigWorldCharacterUiEffectInfo[]>
function XBigWorldCharacterModel:GetCharacterUiEffectMap()
    if not self._CharacterUiEffectMap then
        local configs = self:GetDlcCharacterUiEffectTemplates()

        self._CharacterUiEffectMap = {}
        for id, config in pairs(configs) do
            local fashionId = config.FashionId
            local effectInfo = XBigWorldCharacterUiEffectInfo.New(config)

            if not self._CharacterUiEffectMap[fashionId] then
                self._CharacterUiEffectMap[fashionId] = {}
            end

            table.insert(self._CharacterUiEffectMap[fashionId], effectInfo)
        end
    end

    return self._CharacterUiEffectMap
end

---@return XBigWorldCharacterUiEffectInfo[]
function XBigWorldCharacterModel:GetCharacterUiEffectInfos(fashionId)
    local effectMap = self:GetCharacterUiEffectMap()

    return effectMap[fashionId]
end

-- endregion

-- region 试用角色

function XBigWorldCharacterModel:UpdateTrialCharacterIds(characterIds, isCover, firstCharacterId)
    self:ClearTrialCharacterIds()
    self._IsTrialCoverTeam = isCover or false

    if characterIds then
        local displayCharacterId = 0

        XTool.LoopCollection(characterIds, function(characterId)
            if characterId == firstCharacterId then
                displayCharacterId = characterId
            end

            table.insert(self._TrialCharacterIds, characterId)
            self._TrialCharacterMap[characterId] = true
        end)

        if not XTool.IsTableEmpty(self._TrialCharacterIds) then
            if not XTool.IsNumberValid(displayCharacterId) then
                displayCharacterId = self._TrialCharacterIds[1]
            end

            if XTool.IsNumberValid(displayCharacterId) then
                XMVCA.XBigWorldUI:Open("UiBigWorldTrialRolePopup", displayCharacterId)
            end
        end
    end
end

function XBigWorldCharacterModel:ClearTrialCharacterIds()
    self._TrialCharacterIds = {}
    self._TrialCharacterMap = {}
    self._IsTrialCoverTeam = false
end

function XBigWorldCharacterModel:CheckTrialCharacter(characterId)
    if XTool.IsNumberValid(characterId) then
        return self._TrialCharacterMap[characterId] or false
    end

    return false
end

-- endregion

return XBigWorldCharacterModel
