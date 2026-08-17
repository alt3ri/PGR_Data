---@class XEnvelopeGuessingControl : XControl
---@field _Model XEnvelopeGuessingModel
local XEnvelopeGuessingControl = XClass(XControl, "XEnvelopeGuessingControl")

local TableKey = {
    EnvelopeCharacter = {},
    EnvelopeList = {},
    EnvelopeInstrument = {},
}

function XEnvelopeGuessingControl:OnInit()
    self:InitConfigByTabKey("MiniActivity/Envelope", TableKey)
end

function XEnvelopeGuessingControl:OnRelease()
end

--region 请求协议相关
function XEnvelopeGuessingControl:EnvelopeOpenRequest(envelopeId, cb)
    local request = {
        Id = envelopeId,
    }
    XNetwork.Call("EnvelopeOpenRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:OnCharacterOpened(self:EnvelopeIdToCharacterId(envelopeId))
        if cb then cb() end
    end)
end

function XEnvelopeGuessingControl:EnvelopeSelectOpenRequest(characterId, cb)
    local request = {
        CharacterId = characterId,
    }
    XNetwork.Call("EnvelopeSelectOpenRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:OnCharacterOpened(characterId)
        if cb then cb() end
    end)
end

function XEnvelopeGuessingControl:EnvelopeBindRequest(instrumentBinding, cb)
    XMessagePack.MarkAsTable(instrumentBinding)
    local request = {
        Bindings = instrumentBinding,
    }
    XNetwork.Call("EnvelopeBindRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:OnInstrumentBindingSaved(instrumentBinding)
        if cb then cb() end
    end)
end
--endregion

--region 活动相关
function XEnvelopeGuessingControl:HandleActivityEnd()
    XLuaUiManager.RunMain(true)
    XUiManager.TipText("CommonActivityEnd")
end
--endregion

--region 章节相关
---@return XTableEnvelopeCharacter[]
function XEnvelopeGuessingControl:GetAllCharacterConfigs()
    return self:GetAllConfigByTabKey(TableKey.EnvelopeCharacter)
end

---@return XTableEnvelopeCharacter
function XEnvelopeGuessingControl:GetCharacterConfig(characterId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.EnvelopeCharacter, characterId)
end

function XEnvelopeGuessingControl:GetCharacterName(characterId)
    local config = self:GetCharacterConfig(characterId)
    return config and config.CharacterName or ""
end

function XEnvelopeGuessingControl:IsAllCharactersOpened()
    return self._Model:GetOpenedCharacterCount() >= #self:GetAllCharacterConfigs()
end
--endregion

--region EnvelopeList 相关
---@return XTableEnvelopeList[]
function XEnvelopeGuessingControl:GetAllEnvelopes()
    return self:GetAllConfigByTabKey(TableKey.EnvelopeList)
end

function XEnvelopeGuessingControl:EnvelopeIdToCharacterId(envelopeId)
    ---@type XTableEnvelopeList
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.EnvelopeList, envelopeId)
    return config and config.CharacterId or 0
end
--endregion

--region 乐器相关
---@return XTableEnvelopeInstrument[]
function XEnvelopeGuessingControl:GetAllInstruments()
    return self:GetAllConfigByTabKey(TableKey.EnvelopeInstrument)
end

function XEnvelopeGuessingControl:SetInstrumentBinding(instrumentId, characterId, cb)
    local allBindings = XTool.Clone(self._Model:GetAllInstrumentBindings())
    local anotherInst
    local anotherChar

    if XTool.IsNumberValid(characterId) then
        anotherInst = XTool.FindKeyByValue(allBindings, characterId)
        if anotherInst then
            anotherChar = allBindings[instrumentId]
            allBindings[anotherInst] = anotherChar
        end
    end

    allBindings[instrumentId] = characterId
    self:EnvelopeBindRequest(allBindings, function()
        if cb then
            cb(anotherInst, anotherChar)
        end
    end)
end
--endregion

--region 任务相关
function XEnvelopeGuessingControl:IsValidTaskState(state)
    return state == XDataCenter.TaskManager.TaskState.Finish
        or state == XDataCenter.TaskManager.TaskState.Achieved
        or state == XDataCenter.TaskManager.TaskState.Active
        or state == XDataCenter.TaskManager.TaskState.Accepted
end
--endregion

--region Model里的方法
function XEnvelopeGuessingControl:GetInstrumentBinding(instrumentId)
    return self._Model:GetInstrumentBinding(instrumentId)
end

function XEnvelopeGuessingControl:IsCharacterOpened(characterId)
    return self._Model:IsCharacterOpened(characterId)
end

function XEnvelopeGuessingControl:GetOpenedCharacterCount()
    return self._Model:GetOpenedCharacterCount()
end

function XEnvelopeGuessingControl:IsCharacterStoryWatched(characterId)
    return self._Model:IsCharacterStoryWatched(characterId)
end

function XEnvelopeGuessingControl:GetAllOpenedCharacters()
    return self._Model:GetAllOpenedCharacters()
end

function XEnvelopeGuessingControl:UpdatePrevOpenedCharacterCount()
    return self._Model:UpdatePrevOpenedCharacterCount()
end

function XEnvelopeGuessingControl:GetInstrumentByBoundCharacterId(characterId)
    return self._Model:GetInstrumentByBoundCharacterId(characterId)
end
--endregion

--region 其它
function XEnvelopeGuessingControl:CheckFastOpenUnlocked()
    local config = XMVCA.XEnvelopeGuessing:GetActivityConfig()
    return self._Model:GetOpenedCharacterCount() >= config.FastOpenTarget
end

-- 检查开包券是否足够开一次包
function XEnvelopeGuessingControl:CheckTicketItemEnough()
    local config = XMVCA.XEnvelopeGuessing:GetActivityConfig()
    return XDataCenter.ItemManager.CheckItemCountById(config.TicketItemId, 1)
end

-- 检查定向机会Item是否足够开一次定向包
function XEnvelopeGuessingControl:CheckChoiceTicketItemEnough()
    local config = XMVCA.XEnvelopeGuessing:GetActivityConfig()
    return XDataCenter.ItemManager.CheckItemCountById(config.SelectChoiceItemId, 1)
end

function XEnvelopeGuessingControl:GetPrevOpenedEnvelopeStorageKey()
    local activityId = self._Model:GetActivityId()
    return "PrevOpenedEnvelopeStorageKey_" .. XPlayer.Id .. "_" .. activityId
end
--endregion

return XEnvelopeGuessingControl
