local XRaceConfig = require("XModule/XRace/XRaceConfig")

---@class XRaceModel : XRaceConfig
local XRaceModel = XClass(XRaceConfig, "XRaceModel")

function XRaceModel:OnInit()
    XRaceConfig.OnInit(self)
    ---@type number
    self.ActivityId = nil
    ---@type number 当前比赛Id
    self._CurRoundId = nil
    ---@type XRaceCharacterTrackInfo[] 进入当前比赛的角色顺序
    self._CurTrackInfo = nil
    ---@type RaceRoundResult[] 服务端下发的基础比赛信息
    self._BaseRoundDict = {}
    ---@type table 服务端下发的竞猜和个人信息
    self._BasePlayerData = {}
    ---@type table 服务端下发的单场竞猜结果
    self._BaseRoundGuessResult = {}
    ---@type table 服务端下发的赛事竞猜结果
    self._BaseMatchGuessResult = {}
    ---@type table<number,table<number,table<number,number>>> 单场竞猜支持率 key=roundId、guessId、characterId/OptionIdx
    self._RoundSupportDict = {}
    ---@type table<number,table<number,number>> 赛事竞猜支持率 key=guessId、characterId/OptionIdx
    self._MatchSupportDict = {}
end

function XRaceModel:ClearPrivate()
    XRaceConfig.ClearPrivate(self)
    self._MaxCharacterGrade = nil
    self._RoleRandomSite = nil
    self._EliminatorOpenTime = nil
    self._TimeStrToNumber = nil
    self._SortRoundId = nil
    self._SettleParam = nil
end

function XRaceModel:ResetAll()
    XRaceConfig.ResetAll(self)
    self.ActivityId = nil
    self._CurRoundId = nil
    self._BaseRoundDict = {}
    self._BasePlayerData = {}
    self._BaseRoundGuessResult = {}
    self._BaseMatchGuessResult = {}
    self._RoundSupportDict = {}
    self._MatchSupportDict = {}
end

function XRaceModel:GetCurRound()
    return self._CurRoundId
end

function XRaceModel:NotifyRacePlayerDataDb(data)
    self._CurRoundId = data.RoundId
    self._BasePlayerData = data.RaceDataDb
    self.ActivityId = data.RaceDataDb.ActivityId
end

function XRaceModel:NotifyRaceRoundConfig(data)
    ---@type table<number,RaceRoundEtcdConfig>
    self._EtcdRoundConfigs = data.RaceRoundConfigDict --如果此数据没发 表示活动没开启
end

function XRaceModel:NotifyRaceRoundStart(data)
    self._CurRoundId = data.RoundId
end

function XRaceModel:UpdateBasePlayerData(data, roundId)
    self._BasePlayerData = data
    self._CurRoundId = roundId
end

function XRaceModel:UpdateAllRoundResult(data)
    self._CurRoundId = data.CurRoundId
    self._BaseRoundDict = data.Results
    
    self._CurTrackInfo = data.CurEnterRaceCharacterIds
    if not XTool.IsTableEmpty(self._CurTrackInfo) then
        table.sort(self._CurTrackInfo, function(a, b)
            return a.RaceId < b.RaceId
        end)
    end
end

function XRaceModel:UpdateBaseRoundGuess(guessId, characterId, guessOpt)
    local raceRoundInfo = self._BasePlayerData.RoundGuessDict[self._CurRoundId]
    if not raceRoundInfo then
        raceRoundInfo = {}
        raceRoundInfo.RaceRoundGuessInfoDict = {}
        self._BasePlayerData.RoundGuessDict[self._CurRoundId] = raceRoundInfo
    end
    local info = raceRoundInfo.RaceRoundGuessInfoDict[guessId]
    if not info then
        info = {}
        raceRoundInfo.RaceRoundGuessInfoDict[guessId] = info
    end
    info.CharacterId = characterId
    info.OptionId = guessOpt
end

function XRaceModel:UpdateBaseMatchGuess(guessId, characterId, guessOpt)
    local info = self._BasePlayerData.GlobalGuessDict[guessId]
    if not info then
        info = {}
        self._BasePlayerData.GlobalGuessDict[guessId] = info
    end
    info.CharacterId = characterId
    info.OptionId = guessOpt
end

function XRaceModel:UpdateBaseRoundResult(roundId, results)
    self._BaseRoundGuessResult[roundId] = results
    -- 更新竞猜状态
    local info = self._BasePlayerData.RoundGuessDict[roundId]
    for _, result in pairs(results) do
        local guessId = result.GuessId
        local data = info and info.RaceRoundGuessInfoDict[guessId]
        self:UpdateBaseGuessInfo(data, result.PlayerGuessInfo)
    end
end

function XRaceModel:UpdateBaseMatchResult(results)
    self._BasePlayerData.IsSeeGlobal = true
    self._BaseMatchGuessResult = results
    -- 更新竞猜状态
    for _, result in pairs(results) do
        local guessId = result.GuessId
        local data = self._BasePlayerData.GlobalGuessDict[guessId]
        self:UpdateBaseGuessInfo(data, result.PlayerGuessInfo)
    end
end

-- 结算数据XRaceRoundGuessInfo继承自RaceRoundGuessInfo，所以不能直接覆盖
function XRaceModel:UpdateBaseGuessInfo(baseData, resultData)
    if not baseData or not resultData then
        return
    end
    baseData.GuessState = resultData.GuessState
    baseData.IsGain = resultData.IsGain
end

function XRaceModel:UpdateMatchRewardGain()
    if self._BasePlayerData.GlobalGuessDict then
        for _, v in pairs(self._BasePlayerData.GlobalGuessDict) do
            v.IsGain = true
        end
    end
    if self._BaseMatchGuessResult then
        for _, baseGuess in pairs(self._BaseMatchGuessResult) do
            local info = baseGuess.PlayerGuessInfo
            if info then
                info.IsGain = true
            end
        end
    end
end

function XRaceModel:UpdateRoundRewardGain(roundId)
    local baseGuesses = self._BaseRoundGuessResult[roundId]
    if baseGuesses then
        for _, baseGuess in pairs(baseGuesses) do
            if baseGuess.PlayerGuessInfo then
                baseGuess.PlayerGuessInfo.IsGain = true
            end
        end
    end
end

function XRaceModel:SetRoundResultCheck(roundId)
    local raceRoundInfo = self._BasePlayerData.RoundGuessDict[roundId]
    if raceRoundInfo then
        raceRoundInfo.IsSee = true
    end
end

function XRaceModel:IsRoundResultCheck(roundId)
    local raceRoundInfo = self._BasePlayerData.RoundGuessDict[roundId]
    return raceRoundInfo and raceRoundInfo.IsSee
end

function XRaceModel:UpdateRoundSupport(roundId, supportInfos)
    local datas = {}
    if not XTool.IsTableEmpty(supportInfos) then
        for _, supportInfo in pairs(supportInfos) do
            datas[supportInfo.GuessId] = self:AnalysisBaseSupport(supportInfo)
        end
    end
    self._RoundSupportDict[roundId] = datas
end

function XRaceModel:UpdateMatchSupport(supportInfos)
    self._MatchSupportDict = {}
    if not XTool.IsTableEmpty(supportInfos) then
        for _, supportInfo in pairs(supportInfos) do
            self._MatchSupportDict[supportInfo.GuessId] = self:AnalysisBaseSupport(supportInfo)
        end
    end
end

---解析一个竞猜项的数据
function XRaceModel:AnalysisBaseSupport(supportInfo)
    local data = {}
    for roleId, info in pairs(supportInfo.CharacterSupportDict) do
        if roleId == 0 then
            for optionIdx, rate in pairs(info.Option2SupportRateDict) do
                data[optionIdx] = rate
            end
        else
            data[roleId] = info.SupportRate
        end
    end
    return data
end

---是否存在etcd数据
function XRaceModel:IsExistEtcdConfig()
    return not XTool.IsTableEmpty(self._EtcdRoundConfigs)
end

function XRaceModel:GetEtcdRoundConfig(roundId)
    if not self._EtcdRoundConfigs then return end
    return self._EtcdRoundConfigs[roundId]
end

function XRaceModel:GetEtcdRoundConfigs()
    return self._EtcdRoundConfigs
end

function XRaceModel:GetResultOptionIdx(guessId, value)
    local options = self:GetRaceGuessById(guessId).GuessOptions
    for i, optionId in ipairs(options) do
        local option = self:GetRaceGuessParamsById(optionId)
        if option.MinValue <= value and option.MaxValue >= value then
            return i
        end
    end
    XLog.Error(string.format("guessId=%s里找不到值为%s的选项", guessId, value))
    return 1
end

---@return RaceRoundResult[]
function XRaceModel:GetRoundDict()
    return self._BaseRoundDict
end

function XRaceModel:GetBasePlayerData()
    return self._BasePlayerData
end

function XRaceModel:GetBaseRoundGuessResult()
    return self._BaseRoundGuessResult
end

function XRaceModel:GetBaseMatchGuessResult()
    return self._BaseMatchGuessResult
end

function XRaceModel:SetGainSkinReward()
    self._BasePlayerData.IsGainSkinReward = true
end

function XRaceModel:IsGainSkinReward()
    return self._BasePlayerData.IsGainSkinReward
end

function XRaceModel:IsSkinRewardGain()
    return self._BasePlayerData.IsGainSkinReward
end

function XRaceModel:GetMaxCharacterGrade()
    if not self._MaxCharacterGrade then
        self._MaxCharacterGrade = 0
        for _, v in pairs(self:GetRaceCharacterGradeConfigs()) do
            if v.MaxValue > self._MaxCharacterGrade then
                self._MaxCharacterGrade = v.MaxValue
            end
        end
    end
    return self._MaxCharacterGrade
end

function XRaceModel:GetCharacterGrade(value)
    for _, v in pairs(self:GetRaceCharacterGradeConfigs()) do
        if v.MaxValue >= value and v.MinValue <= value then
            return v
        end
    end
    XLog.Error(string.format("角色评分超出范围：%s", value))
    return nil
end

function XRaceModel:SetRoleRandomSite(sites)
    self._RoleRandomSite = sites
end

function XRaceModel:GetRoleRandomSite()
    return self._RoleRandomSite
end

function XRaceModel:GetEliminatorOpenTime()
    if not self._EliminatorOpenTime then
        for _, data in pairs(self._EtcdRoundConfigs) do
            local time = data.StartTimeLong
            if data.TypeId == XEnumConst.Race.Format.Eliminator then
                if not self._EliminatorOpenTime or self._EliminatorOpenTime > time then
                    self._EliminatorOpenTime = time
                end
            end
        end
    end
    return self._EliminatorOpenTime
end

function XRaceModel:ParseToTimestamp(timeStr)
    if not self._TimeStrToNumber then
        self._TimeStrToNumber = {}
    end
    local time = self._TimeStrToNumber[timeStr]
    if not time then
        time = XTime.ParseToTimestamp(timeStr)
        self._TimeStrToNumber[timeStr] = time
    end
    return time
end

function XRaceModel:GetSortRoundId()
    if not self._SortRoundId then
        self._SortRoundId = {}
        for _, data in pairs(self._EtcdRoundConfigs) do
            table.insert(self._SortRoundId, data.Id)
        end
        table.sort(self._SortRoundId, function(aId, bId)
            local aTime = self._EtcdRoundConfigs[aId].StartTimeLong
            local bTime = self._EtcdRoundConfigs[bId].StartTimeLong
            if aTime ~= bTime then
                return aTime < bTime
            end
            return aId < bId
        end)
    end
    return self._SortRoundId
end

function XRaceModel:GetSortBroadcasts(uiType)
    if not self._SortBroadcasts then
        ---@type table<number,XTableRaceBroadcast[]>
        self._SortBroadcasts = {}
        for _, cfg in pairs(self:GetRaceBroadcastConfigs()) do
            if not self._SortBroadcasts[cfg.Type] then
                self._SortBroadcasts[cfg.Type] = {}
            end
            table.insert(self._SortBroadcasts[cfg.Type], cfg)
        end
        for _, cfgs in pairs(self._SortBroadcasts) do
            table.sort(cfgs, function(a, b)
                if a.BeforeTime ~= b.BeforeTime then
                    return a.BeforeTime < b.BeforeTime
                end
                return a.Id < b.Id
            end)
        end
    end
    return self._SortBroadcasts[uiType]
end

function XRaceModel:IsTipHasShow(uiType, id)
    if not self._CurRoundId or self._CurRoundId == -1 then
        return false
    end
    local key = self._CurRoundId * 10000 + uiType * 1000 + id
    return self._TipShowDict and self._TipShowDict[key]
end

function XRaceModel:SetTipShow(uiType, id)
    if not self._CurRoundId or self._CurRoundId == -1 then
        return
    end
    local key = self._CurRoundId * 10000 + uiType * 1000 + id
    if not self._TipShowDict then
        self._TipShowDict = {}
    end
    self._TipShowDict[key] = true
end

function XRaceModel:GetMainRightMidShowTime()
    if not self._MainRIghtMidShowTime then
        local cfg = self:GetClintConfigById("MainRightMidShowTime")
        self._MainRIghtMidShowTime = tonumber(cfg.Values[1])
    end
    return self._MainRIghtMidShowTime
end

function XRaceModel:SetSettleParam(param)
    self._SettleParam = param
end

function XRaceModel:GetSettleParam()
    return self._SettleParam
end

return XRaceModel

--region 服务端数据结构

---@class RaceRoundResultInfo
---@field Results RaceRoundResult[]
---@field CurEnterRaceCharacterIds number[] 进入当前比赛的角色顺序
---@field CurRoundId number 当前比赛Id

---@class RaceRoundResult
---@field RoundId number 比赛轮次
---@field RankResult table<number,number[]> 比赛排名结果（已排序）[1]=排名 [2]=角色Id [3]=通关时长（毫秒）[4]=积分（积分赛才有）
---@field Time number 比赛总时长（毫秒）
---@field EnterRaceCharacterIds RaceCharacterTrackInfo[] 进入比赛的角色顺序
---@field PromotionCharacterIds number[] 晋级名单
---@field LoseCharacterIds number[] 淘汰名单

---@class RaceCharacterTrackInfo
---@field CharacterId number
---@field RaceId number 赛道Id

---@class RaceRoundEtcdConfig
---@field Id number
---@field TypeId number
---@field StartTimeId number
---@field CharacterGroupId number
---@field PromotionNum number
---@field FromRoundIds number[]
---@field Guess number[]
---@field PointGroupId number
---@field Seed number
---@field MapId number
---@field StartTimeLong number

--endregion