local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")

---@class XArenaActivityData : XArenaDataBase
local XArenaActivityData = XClass(XArenaDataBase, "XArenaActivityData")

function XArenaActivityData:_InitData(data)
    self._ActivityNo = data.ActivityNo
    self._ChallengeId = data.ChallengeId
    self._Status = data.Status
    self._NextStatusTime = data.NextStatusTime
    self._ArenaLevel = data.ArenaLevel
    self._IsJoinActivity = data.JoinActivity == 1
    self._UnlockCount = data.UnlockCount
    self._TeamTime = data.TeamTime
    self._FightTime = data.FightTime
    self._ResultTime = data.ResultTime
    self._MaxPointStageList = data.MaxPointStageList
    self._ContributeScore = data.ContributeScore
    self._StopResetTime = data.StopResetTime
    self._ProtectedScore = data.ProtectedScore
    self._BeforeChallengeId = data.BeforeChallengeId
    self._BeforeArenaLevel = data.BeforeArenaLevel
    self._ArenaIndex = data.ArenaIndex
end

function XArenaActivityData:_ClearData()
    self._ActivityNo = nil
    self._ChallengeId = nil
    self._Status = nil
    self._NextStatusTime = nil
    self._ArenaLevel = nil
    self._IsJoinActivity = nil
    self._UnlockCount = nil
    self._TeamTime = nil
    self._FightTime = nil
    self._ResultTime = nil
    self._MaxPointStageList = nil
    self._ContributeScore = nil
    self._StopResetTime = nil
    self._ProtectedScore = nil
    self._BeforeChallengeId = nil
    self._BeforeArenaLevel = nil
    self._ArenaIndex = nil
end

function XArenaActivityData:GetActivityNo()
    return self._ActivityNo
end

function XArenaActivityData:GetChallengeId()
    return self._ChallengeId
end

function XArenaActivityData:SetChallengeId(value)
    self._ChallengeId = value
end

function XArenaActivityData:GetStatus()
    return self._Status
end

function XArenaActivityData:GetNextStatusTime()
    return self._NextStatusTime
end

function XArenaActivityData:GetArenaLevel()
    return self._ArenaLevel
end

function XArenaActivityData:SetArenaLevel(value)
    self._ArenaLevel = value
end

function XArenaActivityData:GetIsJoinActivity()
    return self._IsJoinActivity
end

function XArenaActivityData:SetIsJoinActivity(value)
    self._IsJoinActivity = value
end

function XArenaActivityData:GetUnlockCount()
    return self._UnlockCount
end

function XArenaActivityData:GetTeamTime()
    return self._TeamTime
end

function XArenaActivityData:GetFightTime()
    return self._FightTime
end

function XArenaActivityData:GetResultTime()
    return self._ResultTime
end

function XArenaActivityData:GetMaxPointStageList()
    return self._MaxPointStageList
end

function XArenaActivityData:GetContributeScore()
    return self._ContributeScore
end

function XArenaActivityData:SetContributeScore(value)
    self._ContributeScore = value
end

function XArenaActivityData:GetStopResetTime()
    return self._StopResetTime
end

function XArenaActivityData:SetStopResetTime(value)
    self._StopResetTime = value
end

function XArenaActivityData:GetProtectedScore()
    return self._ProtectedScore
end

function XArenaActivityData:GetBeforeChallengeId()
    return self._BeforeChallengeId
end

function XArenaActivityData:GetBeforeArenaLevel()
    return self._BeforeArenaLevel
end

function XArenaActivityData:GetArenaIndex()
    return self._ArenaIndex
end

function XArenaActivityData:ClearBeforeChallengeAndArenaId()
    self._BeforeChallengeId = 0
    self._BeforeArenaLevel = 0
end

return XArenaActivityData
