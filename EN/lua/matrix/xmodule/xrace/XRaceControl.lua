---@class XRaceControl : XEntityControl
---@field private _Model XRaceModel
local XRaceControl = XClass(XEntityControl, "XRaceControl")

local EmptyReq = {}

function XRaceControl:OnInit()
    ---@type table<number,XRaceGuessData> 单场竞猜 key=RoundId
    self._RoundGuessDict = {}
    ---@type XRaceGuessData 赛事竞猜
    self._MatchGuess = nil
    ----@type table<number,XRacePointsRaceData> 积分赛 key=PointGroupId
    self._PointsRaceDataDict = {}
    ---@type table<number,XRaceEliminatorData> 淘汰赛 key=RoundId
    self._EliminatorDataDict = {}
    self._RaceRoadName = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
    }
    self._RaceEnterCountKey = XPlayer.Id.. "_RaceEnterCountKey"
end

function XRaceControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_RACE_GAME_START, self.StartGame, self)
    XEventManager.AddEventListener(XEventId.EVENT_RACE_GAME_END, self.EndGame, self)
end

function XRaceControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_RACE_GAME_START, self.StartGame, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RACE_GAME_END, self.EndGame, self)
end

function XRaceControl:OnRelease()
    self._RacePowerData = nil
end

--region 活动

---@return XTableRaceActivity
function XRaceControl:GetCurrentConfig()
    if not self._Model.ActivityId then
        return nil
    end
    return self._Model:GetActivityById(self._Model.ActivityId)
end

function XRaceControl:GetTime()
    local activity = self:GetCurrentConfig()
    if activity then
        return XFunctionManager.GetEndTimeByTimeId(activity.TimeId)
    end
    return 0
end

---@return string[]
function XRaceControl:GetClientConfigs(id)
    local cfg = self._Model:GetClintConfigById(id)
    if cfg then
        return cfg.Values
    end
    return nil
end

---@return string
function XRaceControl:GetClientConfig(id, index)
    index = index or 1
    local values = self:GetClientConfigs(id)
    if not values then return nil end
    return values[index]
end

---@return number
function XRaceControl:GetIntClientConfig(id)
    local strValue = self:GetClientConfig(id)
    if string.IsNilOrEmpty(strValue) then
        return 0
    end
    return tonumber(strValue)
end

---皮肤奖励是否已领取
function XRaceControl:IsSkinRewardGain()
    return self._Model:IsSkinRewardGain()
end

function XRaceControl:GetRaceHomeNewsConfigs()
    return self._Model:GetRaceHomeNewsConfigs()
end

---01:50.10（分:秒.毫秒）
---毫秒只保留十位和百位，eg：2600=00:02.60,2060=00:02.06,2006=00:02.00
---@param ms number 毫秒
function XRaceControl:GetPassTimeStr(ms)
    if not ms or ms < 0 then
        return nil
    end
    local totalSeconds = math.floor(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local hundredths = math.floor((ms % 1000) / 10)  -- 毫秒的十分位、百分位
    return string.format("%02d:%02d.%02d", minutes, seconds, hundredths)
end

function XRaceControl:GetFinalRoundId()
    local sortRoundIds = self._Model:GetSortRoundId()
    return sortRoundIds[#sortRoundIds]
end

function XRaceControl:GetEliminatorOpenTime()
    return self._Model:GetEliminatorOpenTime()
end

---时间字符串转数字（带池管理）
---@return number
function XRaceControl:ParseToTimestamp(timeStr)
    return self._Model:ParseToTimestamp(timeStr)
end

---获取上一轮有预测的比赛Id
function XRaceControl:GetLastGuessRoundId()
    local sortRoundId = self._Model:GetSortRoundId()
    local curRoundId = self:GetCurRound()
    if self:IsAllMatchFinish() then
        local idx = #sortRoundId
        for i = idx, 1, -1 do
            local roundId = sortRoundId[i]
            local info = self._Model._BasePlayerData.RoundGuessDict[roundId]
            if info then
                return roundId
            end
        end
    else
        local idx = table.indexof(sortRoundId, curRoundId)
        if idx > 1 then
            for i = idx - 1, 1, -1 do
                local roundId = sortRoundId[i]
                local info = self._Model._BasePlayerData.RoundGuessDict[roundId]
                if info and not XTool.IsTableEmpty(info.RaceRoundGuessInfoDict) then
                    return roundId
                end
            end
        end
    end
    return nil
end

function XRaceControl:IsGainSkinReward()
    return self._Model:IsGainSkinReward()
end

--endregion

--region 赛程

---@return XTableRaceRoundClient
function XRaceControl:GetRaceRoundById(id)
    return self._Model:GetRaceRoundById(id)
end

---@return RaceRoundEtcdConfig
function XRaceControl:GetEtcdRoundConfig(id)
    return self._Model:GetEtcdRoundConfig(id)
end

---@return RaceRoundEtcdConfig[]
function XRaceControl:GetEtcdRoundConfigs()
    return self._Model:GetEtcdRoundConfigs()
end

function XRaceControl:GetRaceRoundConfigs()
    return self._Model:GetRaceRoundConfigs()
end

function XRaceControl:GetRaceRoundPointGroupAutoConfigs()
    return self._Model:GetRaceRoundPointGroupAutoConfigs()
end

function XRaceControl:GetRaceRoundPointGroupAutoById(id)
    return self._Model:GetRaceRoundPointGroupAutoById(id)
end

function XRaceControl:GetCurRound()
    return self._Model:GetCurRound()
end

---是否所有比赛结束（服务端发-1）
function XRaceControl:IsAllMatchFinish()
    return self:GetCurRound() == -1
end

---淘汰赛是否已开启
function XRaceControl:IsEliminatorOpen()
    local openTime = self:GetEliminatorOpenTime()
    return XTime.GetServerNowTimestamp() >= openTime
end

---获取当前正在进行或者将要进行的赛程
---@return RaceRoundInfo
function XRaceControl:GetCurRoundInfo()
    ---@type RaceRoundInfo
    local info = {}
    if self:IsAllMatchFinish() then
        info.State = XEnumConst.Race.RoundState.End
        return info
    end

    local roundId = self:GetCurRound()
    local etcd = self:GetEtcdRoundConfig(roundId)
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = etcd.StartTimeLong
    if startTime >= nowTime then
        -- 竞猜中
        info.LeftTime = startTime - nowTime
        info.State = XEnumConst.Race.RoundState.Guess
    --elseif startTime >= nowTime then
    --    -- 等待开始
    --    info.LeftTime = startTime - nowTime
    --    info.State = XEnumConst.Race.RoundState.WaitStart
    else
        -- 比赛进行中
        info.State = XEnumConst.Race.RoundState.InProgress
    end

    info.Etcd = etcd
    info.Round = self._Model:GetRaceRoundById(roundId)
    return info
end

function XRaceControl:UpdateRaceData()
    for roundId, data in pairs(self._Model:GetRoundDict()) do
        local etcd = self:GetEtcdRoundConfig(roundId)
        if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
            local round = self._PointsRaceDataDict[etcd.PointGroupId]
            if round then
                round:UpdateRoundData(roundId, data)
            end
        else
            local round = self._EliminatorDataDict[roundId]
            if round then
                round:UpdateRoundData(data)
            end
        end
    end
end

---@return XRacePointsRaceData
function XRaceControl:GetPointsRaceData(pointGroupId)
    local round = self._PointsRaceDataDict[pointGroupId]
    if not round then
        round = self:AddEntity(require("XModule/XRace/XEntity/XRacePointsRaceData"))
        round:InitData(pointGroupId)
        self._PointsRaceDataDict[pointGroupId] = round
    end
    return round
end

---@return XRaceEliminatorData
function XRaceControl:GetEliminatorData(roundId)
    local round = self._EliminatorDataDict[roundId]
    if not round then
        round = self:AddEntity(require("XModule/XRace/XEntity/XRaceEliminatorData"))
        round:InitData(roundId)
        self._PointsRaceDataDict[roundId] = round
    end
    return round
end

---进入比赛（直播/回放）
---@param mode number XEnumConst.Race.GameMode
function XRaceControl:EnterGame(roundId, mode)
    local etcd = self:GetEtcdRoundConfig(roundId)
    local roleIds = {}
    if mode == XEnumConst.Race.GameMode.LiveStream then
        for _, v in ipairs(self._Model._CurTrackInfo) do
            table.insert(roleIds, v.CharacterId)
        end
    else
        if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
            local data = self:GetPointsRaceData(etcd.PointGroupId)
            roleIds = data:GetShowRoleIds()
        else
            local data = self:GetEliminatorData(roundId)
            roleIds = data:GetShowRoleIds()
        end
    end
    XMVCA.XRace:EnterMatchScene(roundId, etcd.MapId, roleIds, mode)
end

function XRaceControl:IsRoundResultCheck(roundId)
    return self._Model:IsRoundResultCheck(roundId)
end

function XRaceControl:IsMatchResultCheck()
    return self._Model._BasePlayerData.IsSeeGlobal
end

--endregion

--region 预测

---@return XTableRaceGuess
function XRaceControl:GetRaceGuessById(id)
    return self._Model:GetRaceGuessById(id)
end

---@return XTableRaceGuessOption
function XRaceControl:GetRaceGuessParamsById(id)
    return self._Model:GetRaceGuessParamsById(id)
end

function XRaceControl:GetGuessParamDesc(id)
    local cfg = self:GetRaceGuessParamsById(id)
    if string.IsNilOrEmpty(cfg.Desc) then
        XLog.Error(string.format("竞猜选项描述没有配置 Id:%s", id))
        return ""
    end
    return string.format(cfg.Desc, cfg.MaxValue, cfg.MinValue)
end

function XRaceControl:GetGuessProperty(guessId)
    local guessCfg = self._Model:GetRaceGuessById(guessId)
    local guessTypeCfg = self._Model:GetRaceGuessTypeById(guessCfg.GuessType)
    return guessTypeCfg.PropertyType
end

---玩家是否进行过预测
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:HasJoinGuess(roundId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    return not XTool.IsTableEmpty(data:GetInfoDict())
end

---预测全部奖励是否已领取
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:IsAllGuessRewardGain(roundId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    return data:IsAllRewardGain()
end

---预测奖励是否已领取
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:IsGuessRewardGain(roundId, guessId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    return data:IsRewardGain(guessId)
end

---预测项目是否已预测
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:IsPredict(roundId, guessId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    return data:IsPredict(guessId)
end

---预测项目是否预测成功
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:IsPredictSuccess(roundId, guessId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    return data:IsPredictSuccess(guessId)
end

---预测项目是否有结果（保底）
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:IsPredictHasResult(roundId, guessId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    return data:HasResult(guessId)
end

---获取【参与预测且还没查看过】or【有预测奖励没领】的比赛
function XRaceControl:GetDontViewedRoundId()
    local lastRoundId = self:GetLastGuessRoundId()
    if XTool.IsNumberValid(lastRoundId) then
        local data = self:GetRoundGuessData(lastRoundId)
        if not self:IsRoundResultCheck(lastRoundId) or not data:IsAllRewardGain() then
            return lastRoundId
        end
    end
    return nil
end

---获取当前比赛预测状态（已预测数量、总预测数量）
---@return number,number
function XRaceControl:GetCurRoundGuessProgress()
    local roundId = self:GetCurRound()
    local data = self:GetRoundGuessData(roundId)
    local totalGuess = self:GetEtcdRoundConfig(roundId).Guess
    return XTool.GetTableCount(data:GetInfoDict()), #totalGuess
end

---预测项目选择结果（角色Id/选项Id）
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:GetGuessProjectOption(roundId, guessId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    local info = data:GetInfo(guessId)
    if info then
        return XTool.IsNumberValid(info.GuessRoleId) and info.GuessRoleId or info.GuessOptionIndex
    end
    return nil
end

---预测项目最终结果（角色Id/选项Id）
---预测角色的项目可能有多个结果，如果玩家预测成功，则显示玩家预测的角色；如果玩家预测失败，则显示第一个角色
---@param roundId number 传nil表示赛事预测，否则表示单场预测
function XRaceControl:GetGuessProjectResult(roundId, guessId)
    local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
    local info = data:GetInfo(guessId)
    if info then
        if self:IsGuessNeedCharacter(guessId) then
            if data:IsPredictSuccess(guessId) then
                return info.GuessRoleId
            else
                return info.ResultRoleIds and info.ResultRoleIds[1] --如果实际结果有多个角色，玩家预测错误则显示第一个；如果预测正确则显示玩家预测的那个
            end
        else
            return info.ResultOptionIndex
        end
    end
    return nil
end

function XRaceControl:IsGuessProjectMultiRole(roundId, guessId)
    if self:IsGuessNeedCharacter(guessId) then
        local data = roundId == nil and self:GetMatchGuessData() or self:GetRoundGuessData(roundId)
        local info = data:GetInfo(guessId)
        if info and info.ResultRoleIds then
            return #info.ResultRoleIds > 1
        end
    end
    return false
end

---角色/选项投票率
---@param roundId number 传nil表示赛事预测，否则表示单场预测
---@param id number 角色Id/选项Id（GuessOptionId）
function XRaceControl:GetVotingRate(roundId, guessId, id)
    if roundId then
        if self._Model._RoundSupportDict then
            if self._Model._RoundSupportDict[roundId] then
                if self._Model._RoundSupportDict[roundId][guessId] then
                    return self._Model._RoundSupportDict[roundId][guessId][id] or 0
                end
            end
        end
    else
        if self._Model._MatchSupportDict then
            if self._Model._MatchSupportDict[guessId] then
                return self._Model._MatchSupportDict[guessId][id] or 0
            end
        end
    end
    return 0
end

function XRaceControl:UpdateRoundGuessData(guessId)
    local info = self._RoundGuessDict[self:GetCurRound()]
    if info then
        info:UpdateRoundGuess(guessId)
    end
end

function XRaceControl:UpdateMatchGuessData()
    if self._MatchGuess then
        self._MatchGuess:UpdateMatchGuess()
    end
end

function XRaceControl:UpdateRoundResultData(roundId)
    local info = self._RoundGuessDict[roundId]
    if info then
        info:UpdateRoundResult()
    end
end

function XRaceControl:UpdateMatchResultData()
    if self._MatchGuess then
        self._MatchGuess:UpdateMatchResult()
    end
end

---设置单场竞猜结果已查看
function XRaceControl:SetRoundResultCheck(roundId)
    self._Model:SetRoundResultCheck(roundId)
end

---获取个人竞猜数据
---@return XRaceGuessData
function XRaceControl:GetRoundGuessData(roundId)
    local info = self._RoundGuessDict[roundId]
    if not info then
        info = self:AddEntity(require("XModule/XRace/XEntity/XRaceGuessData"))
        info:InitRound(roundId)
        self._RoundGuessDict[roundId] = info
    end
    return info
end

---获取赛事竞猜数据
---@return XRaceGuessData
function XRaceControl:GetMatchGuessData()
    if not self._MatchGuess then
        self._MatchGuess = self:AddEntity(require("XModule/XRace/XEntity/XRaceGuessData"))
        self._MatchGuess:InitMatch()
    end
    return self._MatchGuess
end

function XRaceControl:GetPropertyDesc(guessId, value)
    if not value then
        --没有数据 显示【未达成】
        return XUiHelper.GetText("RaceNotAchieved")
    end

    local property = self:GetGuessProperty(guessId)
    if property == XEnumConst.Race.PropertyType.Times then
        --{0}次
        return XUiHelper.GetText("RaceGuessPropertyTimes", value)
    elseif property == XEnumConst.Race.PropertyType.Time then
        --01:50.10
        return self:GetPassTimeStr(value)
    elseif property == XEnumConst.Race.PropertyType.Rank then
        --第{0}名
        if XTool.IsNumberValid(value) then
            return XUiHelper.GetText("RaceGuessPropertyRank", value)
        end
        --未达成
        return XUiHelper.GetText("RaceNotAchieved")
    else
        return value
    end
end

function XRaceControl:GetPropertyName(guessId)
    local property = self:GetGuessProperty(guessId)
    return XUiHelper.GetText(string.format("RacePropertyName%s", property))
end

---是否需要预测红点
function XRaceControl:IsEnterGuessRed(roundId, guessId)
    local key = self:GetEnterGuessRedPointKey(roundId, guessId)
    return not XSaveTool.GetData(key)
end

---红点：没有预测且没有打开浏览过
function XRaceControl:SetEnterGuess(roundId, guessId)
    local key = self:GetEnterGuessRedPointKey(roundId, guessId)
    XSaveTool.SaveData(key, true)
end

function XRaceControl:GetEnterGuessRedPointKey(roundId, guessId)
    local id
    if roundId then
        id = roundId * 1000 + guessId
    else
        id = guessId
    end
    return string.format("RaceEnterGuess_%s_%s", XPlayer.Id, id)
end

function XRaceControl:IsExistGuessResultData(roundId)
    local resultData = self._Model:GetBaseRoundGuessResult()
    return resultData and not XTool.IsTableEmpty(resultData[roundId])
end

--endregion

--region 角色

---@return XTableRaceCharacter
function XRaceControl:GetRaceCharacterById(id)
    return self._Model:GetRaceCharacterById(id)
end

---@return XTableRaceCharacter[]
function XRaceControl:GetRaceCharacterConfigs()
    return self._Model:GetRaceCharacterConfigs()
end

---@return XTableRaceCharacterSkill
function XRaceControl:GetRaceCharacterSkillById(id)
    return self._Model:GetRaceCharacterSkillById(id)
end

---@return XTableRaceSignalBall
function XRaceControl:GetRaceSignalBallById(id)
    return self._Model:GetRaceSignalBallById(id)
end

---@return XTableRaceCharacterGroupAuto
function XRaceControl:GetRaceCharacterGroupById(id)
    return self._Model:GetRaceCharacterGroupById(id)
end

---@return XTableRaceMap
function XRaceControl:GetRaceMapById(id)
    return self._Model:GetRaceMapById(id)
end

function XRaceControl:GetRacePointById(rankIndex)
    local cfg = self._Model:GetRacePointById(rankIndex)
    return cfg and cfg.GetPoint or 0
end

---在某次比赛里，角色是否被淘汰
function XRaceControl:IsCharacterObsolete(roundId, roleId)
    local etcd = self:GetEtcdRoundConfig(roundId)
    if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
        local data = self:GetPointsRaceData(etcd.PointGroupId)
        return data:IsRoleDown(roleId)
    else
        local data = self:GetEliminatorData(roundId)
        return data:IsRoleDown(roleId)
    end
end

---直到现在的赛程，角色是否被淘汰
function XRaceControl:IsCharacterObsoleteNow(roleId)
    local baseDict = self._Model:GetRoundDict()
    local hasCheckPoint = {}
    for _, base in pairs(baseDict) do
        local roundId = base.RoundId
        local etcd = self:GetEtcdRoundConfig(roundId)
        if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
            local pointGroupId = etcd.PointGroupId
            if not hasCheckPoint[pointGroupId] then
                hasCheckPoint[pointGroupId] = true
                local data = self:GetPointsRaceData(pointGroupId)
                if data:IsRoleDown(roleId) then
                    return true
                end
            end
        else
            local data = self:GetEliminatorData(roundId)
            if data:IsRoleDown(roleId) then
                return true
            end
        end
    end
    return false
end

function XRaceControl:GetMaxCharacterGrade()
    return self._Model:GetMaxCharacterGrade()
end

function XRaceControl:GetCharacterGradeShowText(value)
    local cfg = self._Model:GetCharacterGrade(value)
    return cfg and cfg.ShowText or ""
end

function XRaceControl:GetCharacterGradeIcon(value)
    local cfg = self._Model:GetCharacterGrade(value)
    return cfg and cfg.Icon or ""
end

function XRaceControl:GetRoleIdsByRoundId(roundId)
    local roleIds = {}
    if roundId then
        local etcd = self:GetEtcdRoundConfig(roundId)
        if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
            local data = self:GetPointsRaceData(etcd.PointGroupId)
            roleIds = data:GetShowRoleIds()
        else
            local data = self:GetEliminatorData(roundId)
            roleIds = data:GetShowRoleIds()
        end
    else
        for _, data in pairs(self._Model._EtcdRoundConfigs) do
            local groupId = data.CharacterGroupId
            if XTool.IsNumberValid(groupId) then
                local cfg = self._Model:GetRaceCharacterGroupById(groupId)
                for _, roleId in ipairs(cfg.CharacterId) do
                    table.insert(roleIds, roleId)
                end
            end
        end
    end
    return roleIds
end

---预测对象是否是角色
function XRaceControl:IsGuessNeedCharacter(guessId)
    local guessType = self:GetRaceGuessById(guessId).GuessType
    return self._Model:GetRaceGuessTypeById(guessType).NeedCharacter
end

function XRaceControl:IsGuessHidePlayback(guessId)
    local guessType = self:GetRaceGuessById(guessId).GuessType
    return self._Model:GetRaceGuessTypeById(guessType).IsHidePlayback
end

function XRaceControl:IsGuessHideRank(guessId)
    local guessType = self:GetRaceGuessById(guessId).GuessType
    return self._Model:GetRaceGuessTypeById(guessType).IsHideRank
end

function XRaceControl:GetPlaybackRoundId(guessId)
    local guessType = self:GetRaceGuessById(guessId).GuessType
    return self._Model:GetRaceGuessTypeById(guessType).PlaybackRoundId
end

-- 获取能量图
function XRaceControl:GetRaceSignalBallIconById(id)
    if id == 0 then
        return self:GetClientConfig("ZeroBallIcon")
    end
    return self._Model:GetRaceSignalBallById(id).Icon
end

--endregion

--region 界面临时数据

function XRaceControl:GetRoadNameByIndex(index)
    return self._RaceRoadName[index]
end

function XRaceControl:GetEnterRaceCount()
    return XSaveTool.GetData(self._RaceEnterCountKey) or 1
end

function XRaceControl:SetEnterRaceCount(cnt)
    XSaveTool.SaveData(self._RaceEnterCountKey, cnt)
end

function XRaceControl:InitRacePowerData(raceCnt)
    self._RacePowerData = {}
    for i = 1, raceCnt do
        self._RacePowerData[i] = {}
    end
end

function XRaceControl:UpdateRacePowerData(actorIndex, powerIndex, powerCnt, isLog)
    if not self._RacePowerData then return end
    self._RacePowerData[actorIndex][powerIndex] = powerCnt
    -- if isLog then
    --     XLog.Debug("UpdateRacePowerData", self._RacePowerData)
    -- end
end

function XRaceControl:GetRacePowerCount(actorIndex, powerIndex)
    if not self._RacePowerData then return 0 end
    local racePower = self._RacePowerData[actorIndex]
    if not racePower then return 0 end
    return racePower[powerIndex] or 0
end

function XRaceControl:GetRacePowerList(actorIndex, powerIndex)
    if not self._RacePowerData then return end
    return self._RacePowerData[actorIndex]
end

function XRaceControl:GetSkillShowList(actorIndex, skillConfig)
    local hasShow = {}
    local singalBallCosts = skillConfig.SignalBallCosts
    local powerList = self:GetRacePowerList(actorIndex)
    if powerList then
        local allColorCnt = 0
        for i = 4, 1, -1 do
            local num = singalBallCosts[i] or 0
            if num > 0 then
                local hasCnt = powerList[i] or 0
                if hasCnt + allColorCnt >= num then
                    hasShow[i] = num
                    if i == 4 then
                        allColorCnt = hasCnt - num
                    else
                        if hasCnt >= num then
                            hasShow[0] = (hasShow[0] or 0) + hasCnt - num
                        else
                            allColorCnt = allColorCnt + hasCnt - num
                        end
                    end
                else
                    hasShow[i] = hasCnt + allColorCnt
                    allColorCnt = 0
                end
            else
                if i == 4 then
                    allColorCnt = allColorCnt + (powerList[i] or 0)
                else
                    hasShow[0] = (hasShow[0] or 0) + (powerList[i] or 0)
                end
            end
        end
    end
    return hasShow
end

--endregion

--region 界面

function XRaceControl:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
end

---领奖
function XRaceControl:OpenUiObtain(...)
    XLuaUiManager.Open("UiRaceObtain", ...)
end

---飘字
function XRaceControl:OpenTip(key, ...)
    if XLuaUiManager.IsUiLoad("UiRaceToastCommon") then
        return
    end
    XLuaUiManager.Open("UiRaceToastCommon", XUiHelper.GetText(key, ...))
end

---弹框
function XRaceControl:OpenPopup(titleKey, contentKey, closeCb, sureCb)
    XLuaUiManager.Open("UiRacePopupCommon", XUiHelper.GetText(titleKey), XUiHelper.GetText(contentKey), closeCb, sureCb)
end

---记录角色随机站位
function XRaceControl:SetRoleRandomSite(sites)
    self._Model:SetRoleRandomSite(sites)
end

function XRaceControl:GetRoleRandomSite()
    return self._Model:GetRoleRandomSite()
end

function XRaceControl:StartGame()
    if not self:CheckShowGameStart() then
        return
    end
    if not XLuaUiManager.IsUiLoad("UiRaceMain") then
        --游戏开始弹框只在活动内显示（主界面会出现赛马的横幅，control可能还没被销毁）
        return
    end
    if not XMVCA.XRace:IsEnterScene() then
        XLuaUiManager.Open("UiRacePopupGameStart")
    end
end

--局外用（协议在Agency里请求）
function XRaceControl:EndGame(roundId, finishCb)
    self:UpdateRaceData()
    self:SetSettleParam(true)
    XLuaUiManager.Open("UiRaceFightSettlement", roundId)
    if finishCb then
        finishCb()
    end
end

--局内用
function XRaceControl:OpenSettlePanel(targetRoundId, finishCb)
    local roundId = targetRoundId or self:GetCurRound()
    self:RequestAllRoundResult(function()
        self:SetSettleParam(true)
        XLuaUiManager.Open("UiRaceFightSettlement", roundId)
        if finishCb then
            finishCb()
        end
    end)
end

function XRaceControl:GetRankSprites(rank)
    local spList = {}
    if rank <= 9 then
        table.insert(spList, self:GetClientConfig("RankNumIcon", rank))
    else
        local n = rank
        local pow10 = 1
        while n >= 10 do
            n = math.floor(n / 10)
            pow10 = pow10 * 10
        end

        -- 从高位到低位依次取
        while pow10 > 0 do
            local digit = math.floor(rank / pow10) % 10
            if digit == 0 then
                table.insert(spList, self:GetClientConfig("RankWhiteZeroIcon"))
            elseif digit <= 3 then
                table.insert(spList, self:GetClientConfig("RankWhiteNumIcon", digit))
            else
                table.insert(spList, self:GetClientConfig("RankNumIcon", digit))
            end
            pow10 = math.floor(pow10 / 10)
        end
    end
    return spList
end

function XRaceControl:SetSettleParam(isFromRound)
    local param = {}
    param.IsFromRound = isFromRound
    self._Model:SetSettleParam(param)
end

function XRaceControl:ClearSettleParam()
    self._Model:SetSettleParam(nil)
end

function XRaceControl:GetSettleParam()
    return self._Model:GetSettleParam()
end

---对【玩家是否已完成引导】进行判定，若未完成则不跳该弹窗
function XRaceControl:CheckShowGameStart()
    if XLuaUiManager.IsUiShow("UiRacePopupSkin") or XLuaUiManager.IsUiPushing("UiRacePopupSkin") then
        return false
    end
    if XLuaUiManager.IsUiShow("UiRacePopupGameStart") then
        return false
    end
    local values = self:GetClientConfigs("GameStartCheckGuide")
    if not XTool.IsTableEmpty(values) then
        for _, v in pairs(values) do
            local guideId = tonumber(v)
            if XDataCenter.GuideManager.CheckIsGuide(guideId) then
                return true
            end
        end
        return false
    end
    return true
end

function XRaceControl:CheckShowSkinPopup()
    local values = self:GetClientConfigs("PopupSkinCheckGuide")
    if not XTool.IsTableEmpty(values) then
        for _, v in pairs(values) do
            local guideId = tonumber(v)
            if XDataCenter.GuideManager.CheckIsGuide(guideId) then
                return true
            end
        end
        return false
    end
    return true
end

--endregion

--region 协议

---获取比赛排名信息
function XRaceControl:RequestAllRoundResult(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceGetAllRoundResultRequest", EmptyReq, function(res)
        self._Model:UpdateAllRoundResult(res)
        self:UpdateRaceData()
        if cb then
            cb()
        end
    end)
end

---预测单场比赛
---@param guessId number 预测Id
---@param characterId number 预测角色，没有传0
---@param guessOpt number 预测选项，没有传0
function XRaceControl:RequestGuessSingleRound(guessId, characterId, guessOpt, cb)
    local req = {
        GuessId = guessId,
        CharacterId = characterId,
        GuessOpt = guessOpt,
    }
    XNetwork.CallWithAutoHandleErrorCode("RaceGuessSingleRoundRequest", req, function(res)
        self._Model:UpdateBaseRoundGuess(res.GuessId, res.CharacterId, res.GuessOpt)
        self:UpdateRoundGuessData(res.GuessId)
        if cb then
            cb()
        end
    end)
end

---单场比赛预测结果
function XRaceControl:RequestGuessSingleRoundResult(roundId, cb)
    local req = {
        RoundId = roundId,
    }
    XNetwork.CallWithAutoHandleErrorCode("RaceGuessSingleRoundResultRequest", req, function(res)
        self._Model:UpdateBaseRoundResult(roundId, res.Results)
        self:UpdateRoundResultData(roundId)
        if cb then
            cb()
        end
    end)
end

---单场比赛预测奖励领取
function XRaceControl:RequestSingleRoundGainReward(roundId, cb, errorCb)
    local req = {
        RoundId = roundId,
    }
    XNetwork.Call("RaceGuessSingleRoundGainRewardRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if errorCb then
                errorCb()
            end
            return
        end
        self._Model:UpdateRoundRewardGain(roundId)
        self:UpdateRoundResultData(roundId)
        if cb then
            cb(res.ItemCount)
        end
    end)
end

---全局预测比赛
---@param guessId number 预测Id
---@param characterId number 预测角色，没有传0
---@param guessOpt number 预测选项，没有传0
function XRaceControl:RequestGuessGlobal(guessId, characterId, guessOpt, cb)
    local req = {
        GuessId = guessId,
        CharacterId = characterId,
        GuessOpt = guessOpt,
    }
    XNetwork.CallWithAutoHandleErrorCode("RaceGuessGlobalRequest", req, function(res)
        self._Model:UpdateBaseMatchGuess(res.GuessId, res.CharacterId, res.GuessOpt)
        self:UpdateMatchGuessData()
        if cb then
            cb()
        end
    end)
end

---全场比赛预测+结果
function XRaceControl:RequestGuessGlobalResult(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceGuessGlobalResultRequest", EmptyReq, function(res)
        self._Model:UpdateBaseMatchResult(res.Results)
        self:UpdateMatchResultData()
        if cb then
            cb()
        end
    end)
end

---全场比赛预测领取
function XRaceControl:RequestGuessGlobalGainReward(cb, errorCb)
    XNetwork.Call("RaceGuessGlobalGainRewardRequest", EmptyReq, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if errorCb then
                errorCb()
            end
            return
        end
        self._Model:UpdateMatchRewardGain()
        self:UpdateMatchResultData()
        if cb then
            cb(res.ItemCount)
        end
    end)
end

---获取皮肤奖励
function XRaceControl:RequestGainSkinReward(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceGainSkinRewardRequest", EmptyReq, function(res)
        self._Model:SetGainSkinReward()
        self:OpenUiObtain(res.Results)
        if cb then
            cb()
        end
    end)
end

---查询排行榜
function XRaceControl:RequestRankQuery(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceRankQueryRequest", EmptyReq, function(res)
        cb(res)
    end)
end

---公会排行榜查询
function XRaceControl:RequestGuildRankQuery(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceGuildRankQueryRequest", EmptyReq, function(res)
        cb(res)
    end)
end

---获取当前期的支持率
function XRaceControl:RequestCurRoundSupportRate(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceCurRoundSupportRateRequest", EmptyReq, function(res)
        self._Model:UpdateRoundSupport(res.RoundId, res.RaceGuessSupportInfos)
        if cb then
            cb()
        end
    end)
end

---获取全局支持率
function XRaceControl:RequestGlobalRoundSupportRate(cb)
    XNetwork.CallWithAutoHandleErrorCode("RaceGlobalRoundSupportRateRequest", EmptyReq, function(res)
        self._Model:UpdateMatchSupport(res.RaceGuessSupportInfos)
        if cb then
            cb()
        end
    end)
end

--endregion

return XRaceControl

---@class RaceRoundInfo
---@field Round XTableRaceRoundClient
---@field Etcd RaceRoundEtcdConfig
---@field LeftTime number
---@field State number