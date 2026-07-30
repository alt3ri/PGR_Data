---@class XEnvelopeGuessingControl : XControl
---@field _Model XEnvelopeGuessingModel
local XEnvelopeGuessingControl = XClass(XControl, "XEnvelopeGuessingControl")

local TableKey = {
    EnvelopeCharacter = { DirPath = XConfigUtil.DirectoryType.Share },
    EnvelopeList = { DirPath = XConfigUtil.DirectoryType.Share },
    EnvelopeInstrument = { DirPath = XConfigUtil.DirectoryType.Share }
}

XTool.ExportMemberMethods(XEnvelopeGuessingControl, "_Model", {
    "GetInstrumentBinding",
    "IsCharacterOpened",
    "GetOpenedCharacterCount",
    "IsCharacterStoryWatched",
    "GetAllOpenedCharacters",
    "UpdatePrevOpenedCharacterCount",
    "GetInstrumentByBoundCharacterId"
})

function XEnvelopeGuessingControl:OnInit()
    self:InitConfigByTabKey("MiniActivity/Envelope", TableKey)
end

function XEnvelopeGuessingControl:EnvelopeEnterRequest(cb)
    XNetwork.Call("EnvelopeEnterRequest", {}, function(data)
        if data.Code == XCode.Success then
            self._Model:OnEnvelopeEnterRequest(data)
        end

        if cb then cb(data) end
    end)
end

function XEnvelopeGuessingControl:OnRelease()
end

function XEnvelopeGuessingControl:IsValidTaskState(state)
    return state == XDataCenter.TaskManager.TaskState.Finish
        or state == XDataCenter.TaskManager.TaskState.Achieved
        or state == XDataCenter.TaskManager.TaskState.Active
        or state == XDataCenter.TaskManager.TaskState.Accepted
end

function XEnvelopeGuessingControl:GetAllCharacterConfigs()
    return self:GetAllConfigByTabKey(TableKey.EnvelopeCharacter)
end

function XEnvelopeGuessingControl:GetCharacterConfig(characterId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.EnvelopeCharacter, characterId)
end

function XEnvelopeGuessingControl:IsAllCharactersOpened()
    return self._Model:GetOpenedCharacterCount() >= #self:GetAllCharacterConfigs()
end

function XEnvelopeGuessingControl:EnvelopeIdToCharacterId(envelopeId)
    local e = self:GetConfigByTabKeyAndIdKey(
        TableKey.EnvelopeList, envelopeId)

    return e.CharacterId
end

function XEnvelopeGuessingControl:GetAllEnvelopes()
    return self:GetAllConfigByTabKey(TableKey.EnvelopeList)
end

function XEnvelopeGuessingControl:GetAllInstruments()
    return self:GetAllConfigByTabKey(TableKey.EnvelopeInstrument)
end

function XEnvelopeGuessingControl:EnvelopeOpenRequest(
    envelopeIds,
    isFastOpen,
    cb)

    XNetwork.Call(
        "EnvelopeOpenRequest",
        { Ids = envelopeIds, IsFastOpen = isFastOpen },
        function(reply)
            if reply.Code == XCode.Success then
                for _, e in ipairs(envelopeIds) do
                    self._Model:OnCharacterOpened(self:EnvelopeIdToCharacterId(e))
                end
            end

            if cb then cb(reply) end
        end)
end

function XEnvelopeGuessingControl:EnvelopeSelectOpenRequest(characterId, cb)
    XNetwork.Call(
        "EnvelopeSelectOpenRequest",
        { CharacterId = characterId },
        function(reply)
            if reply.Code == XCode.Success then
                self._Model:OnCharacterOpened(characterId)
            end

            if cb then cb(reply) end
        end)
end

-- instrumentBinding必须被MarkAsTable
function XEnvelopeGuessingControl:SaveInstrumentBinding(instrumentBinding, cb)
    XNetwork.Call(
        "EnvelopeBindRequest",
        { Bindings = instrumentBinding },
        function(reply)
            if reply.Code == XCode.Success then
                self._Model:OnInstrumentBindingSaved(instrumentBinding)
            end

            if cb then cb(reply) end
        end)
end

function XEnvelopeGuessingControl:SetInstrumentBinding(
    instrumentId,
    characterId,
    cb)

    local allBindings = XTool.Clone(self._Model:GetAllInstrumentBindings())
    local anotherInst = nil
    local anotherChar = nil

    if characterId then
        anotherInst = XTool.FindKeyByValue(allBindings, characterId)
        if anotherInst then
            anotherChar = allBindings[instrumentId]
            allBindings[anotherInst] = anotherChar
        end
    end

    allBindings[instrumentId] = characterId
    XMessagePack.MarkAsTable(allBindings)
    self:SaveInstrumentBinding(allBindings, function(data)
        cb(data, anotherInst, anotherChar)
    end)
end

function XEnvelopeGuessingControl:CheckFastOpenUnlocked()
    local activity = XMVCA.XEnvelopeGuessing:GetCurrentActivity()
    return self._Model:GetOpenedCharacterCount() >= activity.FastOpenTarget
end

-- 检查开包券是否足够开一次包
function XEnvelopeGuessingControl:CheckTicketItemEnough()
    local conf = XMVCA.XEnvelopeGuessing:GetCurrentActivity()
    return XDataCenter.ItemManager.CheckItemCountById(conf.TicketItemId, 1)
end

-- 检查定向机会Item是否足够开一次定向包
function XEnvelopeGuessingControl:CheckChoiceTicketItemEnough()
    local conf = XMVCA.XEnvelopeGuessing:GetCurrentActivity()
    return XDataCenter.ItemManager.CheckItemCountById(conf.SelectChoiceItemId, 1)
end

return XEnvelopeGuessingControl
