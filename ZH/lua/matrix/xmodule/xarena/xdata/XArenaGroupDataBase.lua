local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")

---@class XArenaGroupDataBase : XArenaDataBase
local XArenaGroupDataBase = XClass(XArenaDataBase, "XArenaGroupDataBase")

function XArenaGroupDataBase:GetSelfGroupPlayerData()
    return self:GetGroupPlayerDataByPlayerId(XPlayer.Id)
end

function XArenaGroupDataBase:GetSelfRank()
    return self:FindGroupPlayerDataByPlayerId(XPlayer.Id)
end

function XArenaGroupDataBase:GetGroupPlayerList()
    return {}
end

---@return XArenaGroupPlayerData
function XArenaGroupDataBase:GetGroupPlayerDataByPlayerId(playerId)
    return nil
end

function XArenaGroupDataBase:FindGroupPlayerDataByPlayerId(playerId)
    return 0
end

function XArenaGroupDataBase:GetWaveRate()
    return 0
end

function XArenaGroupDataBase:GetArenaLevel()
    return XMVCA.XArena:GetActivityCurrentLevel()
end

function XArenaGroupDataBase:GetChallengeId()
    return XMVCA.XArena:GetActivityCurrentChallengeId()
end

return XArenaGroupDataBase