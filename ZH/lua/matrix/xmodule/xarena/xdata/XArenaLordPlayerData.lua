local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")

---@class XArenaLordPlayerData : XArenaDataBase
local XArenaLordPlayerData = XClass(XArenaDataBase, "XArenaLordPlayerData")

function XArenaLordPlayerData:_InitData(data)
    self._Id = data.Id
    self._Name = data.Name
    self._CurrentHeadPortraitId = data.CurrHeadPortraitId
    self._CurrentHeadFrameId = data.CurrHeadFrameId
    self._Point = data.Point
end

function XArenaLordPlayerData:_ClearData()
    self._Id = nil
    self._Name = nil
    self._CurrentHeadPortraitId = nil
    self._CurrentHeadFrameId = nil
    self._Point = nil
end

function XArenaLordPlayerData:GetId()
    return self._Id
end

function XArenaLordPlayerData:GetName()
    return self._Name
end

function XArenaLordPlayerData:GetCurrentHeadPortraitId()
    return self._CurrentHeadPortraitId
end

function XArenaLordPlayerData:GetCurrentHeadFrameId()
    return self._CurrentHeadFrameId
end

function XArenaLordPlayerData:GetPoint()
    return self._Point
end

return XArenaLordPlayerData
