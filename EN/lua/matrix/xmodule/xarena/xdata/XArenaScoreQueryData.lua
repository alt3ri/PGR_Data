local XArenaGroupDataBase = require("XModule/XArena/XData/XArenaGroupDataBase")
local XArenaGroupPlayerData = require("XModule/XArena/XData/XArenaGroupPlayerData")

---@class XArenaScoreQueryData : XArenaGroupDataBase
local XArenaScoreQueryData = XClass(XArenaGroupDataBase, "XArenaScoreQueryData")

function XArenaScoreQueryData:_InitData(data)
    local groupPlayerList = data.GroupPlayerList

    self._Code = data.Code
    self._ActivityNo = data.ActivityNo
    self._ChallengeId = data.ChallengeId
    self._WaveRate = data.WaveRate
    self._ArenaLevel = data.ArenaLevel
    self._ContributeScore = data.ContributeScore
    ---@type XArenaGroupPlayerData[]
    self._GroupPlayerList = {}
    ---@type table<number, XArenaGroupPlayerData>
    self._GroupPlayerMap = {}

    if not XTool.IsTableEmpty(groupPlayerList) then
        for i, groupPlayer in pairs(groupPlayerList) do
            local playerData = XArenaGroupPlayerData.New(groupPlayer)

            self._GroupPlayerList[i] = playerData
            self._GroupPlayerMap[playerData:GetId()] = playerData
        end
    end
end

function XArenaScoreQueryData:_ClearData()
    self._Code = nil
    self._ActivityNo = nil
    self._ChallengeId = nil
    self._WaveRate = nil
    self._ArenaLevel = nil
    self._ContributeScore = nil
    self._GroupPlayerList = nil
    self._GroupPlayerMap = nil
end

function XArenaScoreQueryData:GetCode()
    return self._Code
end

function XArenaScoreQueryData:GetActivityNo()
    return self._ActivityNo
end

function XArenaScoreQueryData:GetChallengeId()
    return self._ChallengeId
end

function XArenaScoreQueryData:GetWaveRate()
    return self._WaveRate
end

function XArenaScoreQueryData:GetArenaLevel()
    return self._ArenaLevel
end

function XArenaScoreQueryData:GetContributeScore()
    return self._ContributeScore
end

---@return XArenaGroupPlayerData[]
function XArenaScoreQueryData:GetGroupPlayerList()
    return self._GroupPlayerList
end

---@return XArenaGroupPlayerData
function XArenaScoreQueryData:GetGroupPlayerDataByPlayerId(playerId)
    return self._GroupPlayerMap[playerId]
end

function XArenaScoreQueryData:FindGroupPlayerDataByPlayerId(playerId)
    local groupList = self:GetGroupPlayerList()

    if not XTool.IsTableEmpty(groupList) then
        for i, playerData in pairs(groupList) do
            if playerData:GetId() == playerId then
                return i
            end
        end
    end

    return 0
end

function XArenaScoreQueryData:GetIsSuccess()
    return self:GetCode() == XCode.Success
end

return XArenaScoreQueryData
