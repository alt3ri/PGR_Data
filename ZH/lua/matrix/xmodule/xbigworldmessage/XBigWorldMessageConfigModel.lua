---@class XBigWorldMessageConfigModel : XModel
local XBigWorldMessageConfigModel = XClass(XModel, "XBigWorldMessageConfigModel")

local MessageTableKey = {
    BigWorldMessage = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldMessageContacts = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    BigWorldMessageIcon = {
        Identifier = "Key",
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    BigWorldMessageStep = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldMessageConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Message", MessageTableKey)
end

---@return XTableBigWorldMessage[]
function XBigWorldMessageConfigModel:GetBigWorldMessageConfigs()
    return self._ConfigUtil:GetByTableKey(MessageTableKey.BigWorldMessage) or {}
end

---@return XTableBigWorldMessage
function XBigWorldMessageConfigModel:GetBigWorldMessageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MessageTableKey.BigWorldMessage, id, false) or {}
end

function XBigWorldMessageConfigModel:GetBigWorldMessageTypeById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.Type
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsIdById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.ContactsId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageIsMultipleById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.IsMultiple
end

function XBigWorldMessageConfigModel:GetBigWorldMessagePriorityById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.Priority
end

function XBigWorldMessageConfigModel:GetBigWorldMessageAwardIdById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.RewardId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageFirstStepIdById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.FirstStepId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageQuestIdById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.QuestId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageConditionIdsById(id)
    local config = self:GetBigWorldMessageConfigById(id)

    return config.ConditionIds
end

---@return XTableBigWorldMessageIcon[]
function XBigWorldMessageConfigModel:GetBigWorldMessageIconConfigs()
    return self._ConfigUtil:GetByTableKey(MessageTableKey.BigWorldMessageIcon) or {}
end

---@return XTableBigWorldMessageIcon
function XBigWorldMessageConfigModel:GetBigWorldMessageIconConfigByKey(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MessageTableKey.BigWorldMessageIcon, key, false) or {}
end
function XBigWorldMessageConfigModel:GetBigWorldMessageIconIconByKey(key)
    local config = self:GetBigWorldMessageIconConfigByKey(key)

    return config.Icon
end
---@return XTableBigWorldMessageContacts[]
function XBigWorldMessageConfigModel:GetBigWorldMessageContactsConfigs()
    return self._ConfigUtil:GetByTableKey(MessageTableKey.BigWorldMessageContacts) or {}
end

---@return XTableBigWorldMessageContacts
function XBigWorldMessageConfigModel:GetBigWorldMessageContactsConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MessageTableKey.BigWorldMessageContacts, id, false) or {}
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsNameById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.Name
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsIconById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.Icon
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsTextById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.Text
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsConditionIdsById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.ConditionIds
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsNamesById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.Names
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsIconsById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.Icons
end

function XBigWorldMessageConfigModel:GetBigWorldMessageContactsTextsById(id)
    local config = self:GetBigWorldMessageContactsConfigById(id)

    return config.Texts
end

---@return XTableBigWorldMessageStep[]
function XBigWorldMessageConfigModel:GetBigWorldMessageStepConfigs()
    return self._ConfigUtil:GetByTableKey(MessageTableKey.BigWorldMessageStep) or {}
end

---@return XTableBigWorldMessageStep
function XBigWorldMessageConfigModel:GetBigWorldMessageStepConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MessageTableKey.BigWorldMessageStep, id, false) or {}
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepDurationById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.Duration
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepIsCanSkipById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.IsCanSkip
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepTypeById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.Type
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepSpeakerIdById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.SpeakerId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepEmojiById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.Emoji
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepVideoImageById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.VideoImage
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepVideoIdById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.VideoId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepPhotoRefIdById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.PhotoRefId
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepImageById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.Image
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepTextById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.Text
end

function XBigWorldMessageConfigModel:GetBigWorldMessageStepNextStepById(id)
    local config = self:GetBigWorldMessageStepConfigById(id)

    return config.NextStep
end

return XBigWorldMessageConfigModel
