---@class XEnvelopeGuessingModel : XModel
local XEnvelopeGuessingModel = XClass(XModel, "XEnvelopeGuessingModel")

function XEnvelopeGuessingModel:OnInit()
    self:ResetAll()
end

function XEnvelopeGuessingModel:ResetAll()
    --这里执行重登数据清理
    self._ActivityId = 0
    self._WatchedCharacterIdSet = {}
    self._OpenedCharacterIds = {}
    self._OpenedCharacterIdSet = {}
    self._InstrumentBindings = {}
    self._PrevOpenedCharacterCount = nil    -- 上一次打开界面时已开启角色数量
    self._HasReward = false
end

function XEnvelopeGuessingModel:ClearPrivate()
    --这里执行内部数据清理
end

function XEnvelopeGuessingModel:OnNotifyEnvelope(data)
    self._ActivityId = data.ActivityId or 0
    self._HasReward = data.HasReward or false
end

function XEnvelopeGuessingModel:OnEnvelopeEnterRequest(data)
    if not data then
        return
    end
    self._InstrumentBindings = data.InstrumentBindings or {}
    self._OpenedCharacterIds = data.OpenedCharacterIds or {}
    self._OpenedCharacterIdSet = XTool.ArrayToSet(data.OpenedCharacterIds or {})
    self._WatchedCharacterIdSet = XTool.ArrayToSet(data.AvgWatchedCharacterIds or {})
    self._HasReward = false
end

function XEnvelopeGuessingModel:HasDailyReward()
    return self._HasReward or false
end

function XEnvelopeGuessingModel:OnCharacterOpened(characterId)
    if not self._OpenedCharacterIdSet[characterId] then
        self._OpenedCharacterIdSet[characterId] = true
        table.insert(self._OpenedCharacterIds, characterId)
    end
end

function XEnvelopeGuessingModel:OnCharacterStoryWatched(characterId)
    self._WatchedCharacterIdSet[characterId] = true
end

function XEnvelopeGuessingModel:IsCharacterStoryWatched(characterId)
    return self._WatchedCharacterIdSet[characterId] or false
end

function XEnvelopeGuessingModel:OnInstrumentBindingSaved(instrumentBinding)
    self._InstrumentBindings = instrumentBinding or {}
end

-- 返回上次界面打开时已开启的角色数量，并更新这个数值为当前已开启角色数量
-- 第一个返回值为上次打开时角色数量，第二个返回值为当前已开启角色数量
function XEnvelopeGuessingModel:UpdatePrevOpenedCharacterCount()
    local prev = self._PrevOpenedCharacterCount
    local cur = self:GetOpenedCharacterCount()
    self._PrevOpenedCharacterCount = cur
    return prev, cur
end

function XEnvelopeGuessingModel:GetInstrumentBinding(instrumentId)
    return self._InstrumentBindings[instrumentId]
end

function XEnvelopeGuessingModel:GetAllInstrumentBindings()
    return self._InstrumentBindings
end

-- 查找绑定到指定角色的乐器
function XEnvelopeGuessingModel:GetInstrumentByBoundCharacterId(characterId)
    return XTool.FindKeyByValue(self._InstrumentBindings, characterId)
end

function XEnvelopeGuessingModel:IsCharacterOpened(charId)
    if not XTool.IsNumberValid(charId) then
        return false
    end
    return self._OpenedCharacterIdSet[charId] or false
end

function XEnvelopeGuessingModel:GetOpenedCharacterCount()
    return #self._OpenedCharacterIds
end

function XEnvelopeGuessingModel:GetAllOpenedCharacters()
    return self._OpenedCharacterIds
end

-- 返回0表示没有开启活动
function XEnvelopeGuessingModel:GetActivityId()
    return self._ActivityId
end

-- 检查活动是否开启
function XEnvelopeGuessingModel:IsActivityOpen()
    return XTool.IsNumberValid(self._ActivityId)
end

return XEnvelopeGuessingModel
