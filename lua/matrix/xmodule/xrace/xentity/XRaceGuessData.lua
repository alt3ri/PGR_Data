---@class XRaceGuessData : XEntity 竞猜
---@field _OwnControl XRaceControl
---@field _Model XRaceModel
local XRaceGuessData = XClass(XEntity, "XRaceGuessData")

local PropertyType = XEnumConst.Race.PropertyType

function XRaceGuessData:OnInit()
    ---@type table<number,GuessInfo>
    self._GuessInfoDict = {}
    self._Unclaimeds = {}
    self._GuessState = {}
end

function XRaceGuessData:InitRound(roundId)
    self._RoundId = roundId
    -- 预测项目状态
    self._GuessStateDict = {}
    
    self:UpdateRoundGuess()
    self:UpdateRoundResult()
end

function XRaceGuessData:InitMatch()
    self:UpdateMatchGuess()
    self:UpdateMatchResult()
end

function XRaceGuessData:SetPlayerGuess(guessId, roleId, optionIndex)
    local info = self._GuessInfoDict[guessId]
    if not info then
        info = {}
        info.GuessId = guessId
        self._GuessInfoDict[guessId] = info
    end

    info.GuessRoleId = roleId
    info.GuessOptionIndex = optionIndex
end

function XRaceGuessData:SetResultData(guessId, baseGuessData, baseResultDatas)
    local info = self._GuessInfoDict[guessId]
    if not info then
        info = {}
        info.GuessId = guessId
        self._GuessInfoDict[guessId] = info
    end

    -- 名次/次数/时间/速度
    local baseResultData = baseResultDatas[1]
    local property = self._OwnControl:GetGuessProperty(guessId)
    if property == PropertyType.Rank then
        info.ResultPropertyValue = baseResultData.RankParam
        info.GuessPropertyValue = baseGuessData and baseGuessData.RankParam
    elseif property == PropertyType.Speed then
        info.ResultPropertyValue = baseResultData.SpeedParam
        info.GuessPropertyValue = baseGuessData and baseGuessData.SpeedParam
    elseif property == PropertyType.Time then
        info.ResultPropertyValue = baseResultData.TimeParam
        info.GuessPropertyValue = baseGuessData and baseGuessData.TimeParam
    elseif property == PropertyType.Times then
        info.ResultPropertyValue = baseResultData.TimesParam
        info.GuessPropertyValue = baseGuessData and baseGuessData.TimesParam
    else
        XLog.Error(string.format("未知类型:%s", info.ResultPropertyValue))
    end

    info.ResultRoleIds = {} --可能出现第一名有多个的情况
    for _, data in pairs(baseResultDatas) do
        table.insert(info.ResultRoleIds, data.CharacterId)
    end

    -- 如果预测的是选项，则实际结果需要自己计算得出
    if info.GuessOptionIndex then
        info.ResultOptionIndex = baseResultData.OptionId
    end
end

---更新单场竞猜数据
function XRaceGuessData:UpdateRoundGuess(guessId)
    local basePlayerData = self._Model:GetBasePlayerData()
    local roundGuess = basePlayerData and basePlayerData.RoundGuessDict[self._RoundId]
    if XTool.IsTableEmpty(roundGuess) then
        return
    end

    if guessId then
        local baseInfo = roundGuess.RaceRoundGuessInfoDict[guessId]
        if baseInfo then
            self:SetPlayerGuess(guessId, baseInfo.CharacterId, baseInfo.OptionId)
        end
    else
        for id, baseInfo in pairs(roundGuess.RaceRoundGuessInfoDict) do
            self:SetPlayerGuess(id, baseInfo.CharacterId, baseInfo.OptionId)
        end
    end
end

---更新单场竞猜结果
function XRaceGuessData:UpdateRoundResult()
    self._Unclaimeds = {}
    self._GuessState = {}

    local baseDatas = self._Model:GetBaseRoundGuessResult()
    local baseGuesses = baseDatas and baseDatas[self._RoundId]
    if XTool.IsTableEmpty(baseGuesses) then
        return
    end

    for _, baseGuess in pairs(baseGuesses) do
        if XTool.IsTableEmpty(baseGuess.ResultGuessResults) then
            --预测没有结果
            goto continue
        end
        local guessId = baseGuess.GuessId
        local info = baseGuess.PlayerGuessInfo
        if info then
            self:SetResultData(guessId, info.RaceGuessFinalResult, baseGuess.ResultGuessResults)
            if info.GuessState == XEnumConst.Race.GuessState.GuessSuccess and not info.IsGain then
                -- 未领取奖励的预测项目
                self._Unclaimeds[guessId] = true
            end
            self._GuessState[guessId] = info.GuessState
        else
            self:SetResultData(guessId, nil, baseGuess.ResultGuessResults)
            self._GuessState[guessId] = XEnumConst.Race.GuessState.GuessFail
        end
        :: continue ::
    end
end

---更新赛事竞猜数据
function XRaceGuessData:UpdateMatchGuess()
    local basePlayerData = self._Model:GetBasePlayerData()
    local matchGuess = basePlayerData and basePlayerData.GlobalGuessDict
    if XTool.IsTableEmpty(matchGuess) then
        return
    end

    for guessId, baseInfo in pairs(matchGuess) do
        self:SetPlayerGuess(guessId, baseInfo.CharacterId, baseInfo.OptionId)
    end
end

---更新赛事竞猜结果
function XRaceGuessData:UpdateMatchResult()
    self._Unclaimeds = {}
    self._GuessState = {}

    local baseGuesses = self._Model:GetBaseMatchGuessResult()
    if XTool.IsTableEmpty(baseGuesses) then
        --服务端在登录协议里有下发IsGain
        local basePlayerData = self._Model:GetBasePlayerData()
        local matchGuess = basePlayerData and basePlayerData.GlobalGuessDict
        if not XTool.IsTableEmpty(matchGuess) then
            for guessId, info in pairs(matchGuess) do
                if info.GuessState == XEnumConst.Race.GuessState.GuessSuccess and not info.IsGain then
                    -- 未领取奖励的预测项目
                    self._Unclaimeds[guessId] = true
                end
            end
        end
        return
    end

    for _, baseGuess in pairs(baseGuesses) do
        if XTool.IsTableEmpty(baseGuess.ResultGuessResults) then
            --预测没有结果（赛事预测不会 做个保底）
            goto continue
        end
        local guessId = baseGuess.GuessId
        self:SetResultData(guessId, baseGuess.PlayerGuessInfo and baseGuess.PlayerGuessInfo.RaceGuessFinalResult, baseGuess.ResultGuessResults)
        local info = baseGuess.PlayerGuessInfo
        if info then
            if info.GuessState == XEnumConst.Race.GuessState.GuessSuccess and not info.IsGain then
                -- 未领取奖励的预测项目
                self._Unclaimeds[guessId] = true
            end
            self._GuessState[guessId] = info.GuessState
        end
        :: continue ::
    end
end

---是否预测
function XRaceGuessData:IsPredict(guessId)
    local info = self:GetInfo(guessId)
    if not info then
        return false
    end
    return XTool.IsNumberValid(info.GuessRoleId) or XTool.IsNumberValid(info.GuessOptionIndex)
end

---预测是否产生了结果
function XRaceGuessData:HasResult(guessId)
    return self._GuessState[guessId] ~= nil
end

---是否预测成功
function XRaceGuessData:IsPredictSuccess(guessId)
    return self._GuessState[guessId] == XEnumConst.Race.GuessState.GuessSuccess
end

---是否未开奖
function XRaceGuessData:IsWaitOpen(guessId)
    if not self._OwnControl:IsAllMatchFinish() then
        return true --比赛还未结束
    end
    return self._GuessState[guessId] == XEnumConst.Race.GuessState.WaitOpen
end

---是否全部奖励已经领取
function XRaceGuessData:IsAllRewardGain()
    return XTool.IsTableEmpty(self._Unclaimeds)
end

---是否奖励未领取
function XRaceGuessData:IsRewardGain(guessId)
    return not self._Unclaimeds[guessId]
end

---@return GuessInfo
function XRaceGuessData:GetInfo(guessId)
    return self._GuessInfoDict[guessId]
end

---@return table<number,GuessInfo>
function XRaceGuessData:GetInfoDict()
    return self._GuessInfoDict
end

return XRaceGuessData

---@class GuessInfo
---@field GuessId number
---@field GuessRoleId number 预测角色Id
---@field GuessOptionIndex number 预测选项索引
---@field ResultRoleIds number[] 实际角色Id（可能有多个）
---@field ResultOptionIndex number 实际选项索引
---@field GuessPropertyValue number 预测对象属性值
---@field ResultPropertyValue number 实际结果属性值