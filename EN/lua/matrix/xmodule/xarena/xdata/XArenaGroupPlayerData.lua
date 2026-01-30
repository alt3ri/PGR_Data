local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")

---@class XArenaGroupPlayerData : XArenaDataBase
local XArenaGroupPlayerData = XClass(XArenaDataBase, "XArenaGroupPlayerData")

function XArenaGroupPlayerData:_InitData(data)
    self._Id = data.Id
    self._Name = data.Name
    self._CurrentHeadPortraitId = data.CurrHeadPortraitId
    self._CurrentHeadFrameId = data.CurrHeadFrameId
    self._Point = data.Point
    self._ContributeScore = data.ContributeScore
    self._LastPointTime = data.LastPointTime
    self._CurrentMedalId = data.CurrMedalId
end

function XArenaGroupPlayerData:_ClearData()
    self._Id = nil
    self._Name = nil
    self._CurrentHeadPortraitId = nil
    self._CurrentHeadFrameId = nil
    self._Point = nil
    self._ContributeScore = nil
    self._LastPointTime = nil
    self._CurrentMedalId = nil
end

function XArenaGroupPlayerData:GetId()
    return self._Id
end

function XArenaGroupPlayerData:GetName()
    return self._Name
end

function XArenaGroupPlayerData:GetCurrentHeadPortraitId()
    return self._CurrentHeadPortraitId
end

function XArenaGroupPlayerData:GetCurrentHeadFrameId()
    return self._CurrentHeadFrameId
end

function XArenaGroupPlayerData:GetPoint()
    return self._Point
end

function XArenaGroupPlayerData:GetContributeScore()
    return self._ContributeScore
end

function XArenaGroupPlayerData:GetLastPointTime()
    return self._LastPointTime
end

function XArenaGroupPlayerData:GetCurrentMedalId()
    return self._CurrentMedalId
end

return XArenaGroupPlayerData
