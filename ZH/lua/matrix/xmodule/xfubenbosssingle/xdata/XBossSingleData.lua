local XBossSingleStageHistory = require("XModule/XFubenBossSingle/XData/XBossSingleStageHistory")
local XBossSingleTrialStageInfo = require("XModule/XFubenBossSingle/XData/XBossSingleTrialStageInfo")

---@class XBossSingleData
local XBossSingleData = XClass(nil, "XBossSingleData")

function XBossSingleData:Ctor(data)
    self._IsEmpty = true
    self._IsForceExit = false
    self:SetData(data)
end

function XBossSingleData:SetData(data)
    if data then
        local historyList
        --region 本期关卡记录
        -- v3.8 从这个版本开始，使用新的字段
        if data.IsResetOpen then
            if not data.StageRecordList then
                XLog.Error("[XBossSingleData] 已经收到了v3.8新版本代码的标记，但是StageRecordList却为空")
            end
            historyList = {}
            
            -- 先遍历一遍旧的记录，填上去
            for _, historyData in pairs(data.HistoryList) do
                historyList[historyData.StageId] = historyData
            end
            
            -- 再遍历一遍新的记录，覆盖上去
            --for _, historyData in pairs(data.StageRecordList) do
            --    local oldHistoryData = historyList[historyData.StageId]
            --    -- 新纪录有队伍, 则使用新记录的, 否则使用旧记录的队伍
            --    if oldHistoryData then
            --        if not historyData.Characters or #historyData.Characters == 0 then
            --            historyData.Characters = oldHistoryData.Characters
            --        end
            --    end
            --    historyList[historyData.StageId] = historyData
            --end
            
            -- 上一期的分数记录，自动作战有用
            self._HistoryListBestRecord = data.HistoryList
            -- 当前记录
            self._RecordCurrent = data.StageRecordList
        else
            historyList = data.HistoryList
        end
        --endregion
        
        local trialStageInfoList = data.TrialStageInfoList
        local challengeHistoryList = data.ChallengeStageHistoryList

        self._IsEmpty = false
        self._ActivityNo = data.ActivityNo

        --region 本期当前总讨伐值
        -- v3.8 从这个版本开始，使用新的字段
        if data.IsResetOpen then
            if not data.CurTotalScore then
                XLog.Error("[XBossSingleData] 已经收到了v3.8新版本代码的标记，但是CurTotalScore却为空")
            end
            self._TotalScore = data.CurTotalScore or 0
            -- 本期的最佳分数记录
            self._TotalScoreBestRecord = data.TotalScore
        else
            self._TotalScore = data.TotalScore
            self._TotalScoreBestRecord = data.TotalScore
        end
        --endregion
        
        self._MaxScore = data.MaxScore
        self._OldLevelType = data.OldLevelType
        self._LevelType = data.LevelType
        self._ChallengeCount = data.ChallengeCount
        self._RemainTime = data.RemainTime
        self._AutoFightCount = data.AutoFightCount
        self._CharacterPoints = data.CharacterPoints
        self._RewardIds = data.RewardIds
        self._RewardGroupId = data.RewardGroupId
        self._RankPlatform = data.RankPlatform
        self._BossList = data.BossList
        self._AfreshId = data.AfreshId or 0
        self._ChallengeSectionId = data.ChallengeSectionId or 0
        self._ChallengeFeatureGroupId = data.ChallengeFeatureGroupId or 0
        self._ChallengeLevelType = data.ChallengeLevelType
        self._ChallengeTotalScore = data.ChallengeTotalScore
        self._ChallengeDeleteRecordTime = data.ChallengeDeleteRecordTime or 0
        --- 结束时间是服务器刷新下发的，这里主动计算出结束的时间戳，方便倒计时计算
        self._EndTime = XTime.GetServerNowTimestamp() + data.RemainTime
        ---@type XBossSingleStageHistory[]
        self._HistoryList = {}
        ---@type XBossSingleStageHistory[]
        self._ChallengeStageHistoryList = {}
        ---@type table<number, XBossSingleTrialStageInfo>
        self._TrialStageInfoMap = {}

        if not XTool.IsTableEmpty(historyList) then
            for _, historyData in pairs(historyList) do
                table.insert(self._HistoryList, XBossSingleStageHistory.New(historyData))
            end
        end
        if not XTool.IsTableEmpty(trialStageInfoList) then
            for _, trialStageInfo in pairs(trialStageInfoList) do
                self._TrialStageInfoMap[trialStageInfo.StageId] = XBossSingleTrialStageInfo.New(trialStageInfo)
            end
        end
        if not XTool.IsTableEmpty(challengeHistoryList) then
            for _, historyData in pairs(challengeHistoryList) do
                table.insert(self._ChallengeStageHistoryList, XBossSingleStageHistory.New(historyData))
            end
        end

        -- v3.8 新增重置按钮
        self._IsResetOpen = data.IsResetOpen
    end
end

function XBossSingleData:GetActivityNo()
    return self._ActivityNo
end

function XBossSingleData:GetTotalScore()
    return self._TotalScore
end

function XBossSingleData:GetMaxScore()
    return self._MaxScore
end

function XBossSingleData:GetOldLevelType()
    return self._OldLevelType
end

function XBossSingleData:GetLevelType()
    return self._LevelType
end

function XBossSingleData:SetChallengeCount(value)
    self._ChallengeCount = value
end

function XBossSingleData:GetChallengeCount()
    return self._ChallengeCount
end

function XBossSingleData:GetRemainTime()
    return self._RemainTime
end

function XBossSingleData:GetAutoFightCount()
    return self._AutoFightCount
end

function XBossSingleData:GetRewardGroupId()
    return self._RewardGroupId
end

function XBossSingleData:GetRankPlatform()
    return self._RankPlatform
end

function XBossSingleData:GetCharacterPointMap()
    return self._CharacterPoints
end

function XBossSingleData:AddRewardId(rewardId)
    if self._RewardIds then
        table.insert(self._RewardIds, rewardId)
    end
end

function XBossSingleData:GetRewardIdList()
    return self._RewardIds
end

function XBossSingleData:GetBossList()
    return self._BossList
end

---@return XBossSingleStageHistory[]
function XBossSingleData:GetHistoryList()
    return self._HistoryList
end

---@return table<number, XBossSingleTrialStageInfo>
function XBossSingleData:GetTrialStageInfoMap()
    return self._TrialStageInfoMap
end

function XBossSingleData:GetIsEmpty()
    return self._IsEmpty
end

function XBossSingleData:GetEndTime()
    return self._EndTime
end

function XBossSingleData:GetAfreshId()
    return self._AfreshId
end

function XBossSingleData:GetChallengeSectionId()
    return self._ChallengeSectionId
end

function XBossSingleData:GetChallengeFeatureGroupId()
    return self._ChallengeFeatureGroupId
end

---@return XBossSingleStageHistory[]
function XBossSingleData:GetChallengeStageHistoryList()
    return self._ChallengeStageHistoryList
end

function XBossSingleData:GetChallengeLevelType()
    return self._ChallengeLevelType
end

function XBossSingleData:GetChallengeTotalScore()
    return self._ChallengeTotalScore
end

function XBossSingleData:GetChallengeDeleteRecordTime()
    return self._ChallengeDeleteRecordTime
end

function XBossSingleData:IsResetOpen()
    return self._IsResetOpen
end

function XBossSingleData:GetMaxTotalScore()
    return self._MaxTotalScore
end

function XBossSingleData:GetHistoryBestRecord()
    return self._HistoryListBestRecord
end

function XBossSingleData:GetRecordCurrent()
    return self._RecordCurrent
end

function XBossSingleData:GetTotalScoreBestRecord()
    return self._TotalScoreBestRecord or 0
end

function XBossSingleData:IsForceExit()
    return self._IsForceExit
end

function XBossSingleData:ClearForceExit()
    self._IsForceExit = false
end

function XBossSingleData:SetForceExit(value)
    self._IsForceExit = value or false
end

return XBossSingleData
