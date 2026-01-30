local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")

---@class XArenaActivityResultData : XArenaDataBase
local XArenaActivityResultData = XClass(XArenaDataBase, "XArenaActivityResultData")

function XArenaActivityResultData:_InitData(data)
    self._ChallengeId = data.ChallengeId
    self._GroupRank = data.GroupRank
    self._Point = data.Point
    self._OldArenaLevel = data.OldArenaLevel
    self._NewArenaLevel = data.NewArenaLevel
    self._IsProtected = data.IsProtected
    self._ContributeScore = data.ContributeScore
    self._RewardGoodsList = data.RewardGoodsList
end

function XArenaActivityResultData:_ClearData()
    self._ChallengeId = nil
    self._GroupRank = nil
    self._Point = nil
    self._OldArenaLevel = nil
    self._NewArenaLevel = nil
    self._IsProtected = nil
    self._ContributeScore = nil
    self._RewardGoodsList = nil
end

function XArenaActivityResultData:GetChallengeId()
    return self._ChallengeId
end

function XArenaActivityResultData:GetGroupRank()
    return self._GroupRank
end

function XArenaActivityResultData:GetPoint()
    return self._Point
end

function XArenaActivityResultData:GetOldArenaLevel()
    return self._OldArenaLevel
end

function XArenaActivityResultData:GetNewArenaLevel()
    return self._NewArenaLevel
end

function XArenaActivityResultData:GetIsProtected()
    return self._IsProtected
end

function XArenaActivityResultData:GetContributeScore()
    return self._ContributeScore
end

function XArenaActivityResultData:GetRewardGoodsList()
    return self._RewardGoodsList
end

return XArenaActivityResultData
