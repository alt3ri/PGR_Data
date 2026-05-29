---@class XGameCollectionControl : XControl
---@field private _Model XGameCollectionModel
local XGameCollectionControl = XClass(XControl, "XGameCollectionControl")

local UiNameGame2048 = "UiGame2048Game"

local function GetGameType(gameCfg)
    if XTool.IsTableEmpty(gameCfg) then
        return 0
    end

    return gameCfg.GameType or gameCfg.Id or 0
end


function XGameCollectionControl:OnInit()

end

function XGameCollectionControl:AddAgencyEvent()
end

function XGameCollectionControl:RemoveAgencyEvent()
end

function XGameCollectionControl:OnRelease()

end

function XGameCollectionControl:GetGameCollectionConfig(key, index)
    local config = self._Model:GetGameCollectionConfig(key)
    if config then
        if not XTool.IsNumberValid(index) then
            return config.Values[1]
        end
        return config.Values[index]
    end
    return nil
end

function XGameCollectionControl:GetShowTaskDataList()
    local taskTimeLimitIds = self._Model:GetGameCollectionTaskCfgs()
    if XTool.IsTableEmpty(taskTimeLimitIds) then
        return
    end
    local taskDatas = {}
    for _, taskTimeLimitId in pairs(taskTimeLimitIds) do
        local timeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
        if not timeLimitCfg or not XFunctionManager.CheckInTimeByTimeId(timeLimitCfg.TimeId) then
            goto continue
        end
        local tasks = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimeLimitId)
        if tasks then
            for _, taskData in pairs(tasks) do
                table.insert(taskDatas, taskData)
            end
        end
        ::continue::
    end
    return taskDatas
end

function XGameCollectionControl:GetActivityCfgs()
    return self._Model:GetGameCollectionCfgs() or {}
end

function XGameCollectionControl:GetSelectedGameType()
    return self._Model:GetSelectedGameType()
end

function XGameCollectionControl:SetSelectedGameType(gameType)
    self._Model:SetSelectedGameType(gameType)
end

function XGameCollectionControl:GetGameCfg(gameType)
    gameType = self:_ResolveGameType(gameType)
    if not XTool.IsNumberValid(gameType) then
        return
    end

    local activityCfgs = self:GetActivityCfgs()
    for _, gameCfg in pairs(activityCfgs) do
        if GetGameType(gameCfg) == gameType then
            return gameCfg
        end
    end
end

function XGameCollectionControl:GetActivityEndTime()
    local activityId = self._Model:GetActivityId()
    local timeId = activityId and self._Model:GetGameCollectionActivityCfgById(activityId).TimeId or 0
    return XFunctionManager.GetEndTimeByTimeId(timeId) or 0
end

function XGameCollectionControl:GetCollectionMaxScore(gameType)
    return self._Model:GetMaxScore(gameType)
end

function XGameCollectionControl:GetOtherCanGiveUpGameTypes(targetGameType)
    targetGameType = self:_ResolveGameType(targetGameType)
    local result = {}
    local existMap = {}
    local activityCfgs = self:GetActivityCfgs()
    if XTool.IsTableEmpty(activityCfgs) then
        return result
    end

    for _, gameCfg in ipairs(activityCfgs) do
        local gameType = GetGameType(gameCfg)
        if gameType ~= targetGameType and not existMap[gameType] and self:IsCanGiveUp(gameType) then
            table.insert(result, gameType)
            existMap[gameType] = true
        end
    end

    return result
end

function XGameCollectionControl:GiveUpGames(gameTypes, cb)
    if XTool.IsTableEmpty(gameTypes) then
        if cb then
            cb()
        end
        return
    end

    local filteredGameTypes = {}
    local existMap = {}
    for _, gameType in ipairs(gameTypes) do
        local resolvedGameType = self:_ResolveGameType(gameType)
        if XTool.IsNumberValid(resolvedGameType) and not existMap[resolvedGameType] and self:IsCanGiveUp(resolvedGameType) then
            table.insert(filteredGameTypes, resolvedGameType)
            existMap[resolvedGameType] = true
        end
    end

    if XTool.IsTableEmpty(filteredGameTypes) then
        if cb then
            cb()
        end
        return
    end

    local function DoGiveUp(index)
        if index > #filteredGameTypes then
            if cb then
                cb()
            end
            return
        end

        self:GiveUpGame(filteredGameTypes[index], function()
            DoGiveUp(index + 1)
        end)
    end

    DoGiveUp(1)
end

function XGameCollectionControl:RequestEnterGame(gameType)
    gameType = self:_ResolveGameType(gameType)
    if not XTool.IsNumberValid(gameType) then
        return
    end
    local gameCfg = self:GetGameCfg(gameType)
    if XTool.IsTableEmpty(gameCfg) then
        return
    end

    -- self:_StartLaunchSession(gameType, gameCfg.StageId)
    -- self:EnterChildGame(gameType)
    local req = {
        GameType = gameType,
        StageId = gameCfg.StageId,
        -- CharacterId = XMVCA.XGoldenMiner:GetUseCharacterId(), --todo
    }
    XNetwork.Call("GameCollectionEnterGameRequest", req, function(res)
        if res.Code ~= XCode.Success then
            return
        end
        self:_StartLaunchSession(gameType, gameCfg.StageId, self:_BuildEnterScoreSnapshot(gameType))
        self:EnterChildGame(gameType)
    end)
end

function XGameCollectionControl:EnterChildGame(gameType)
    self:SetSelectedGameType(gameType)

    local gameCfg = self:GetGameCfg(gameType)
    if gameType == XEnumConst.GameCollection.GameType.GoldenMiner then
        self:_RequestEnterGoldenMiner(gameCfg)
    elseif gameType == XEnumConst.GameCollection.GameType.Game2048 then
        self:_RequestEnterGame2048(gameCfg)
    elseif gameType == XEnumConst.GameCollection.GameType.FangKong then
        self:_RequestEnterFangKuai(gameCfg)
    end
end

function XGameCollectionControl:ContinueGame(gameType)
    gameType = self:_ResolveGameType(gameType)
    if not XTool.IsNumberValid(gameType) then
        return
    end

    self:SetSelectedGameType(gameType)
    local gameCfg = self:GetGameCfg(gameType)
    if XTool.IsTableEmpty(gameCfg) then
        return
    end

    if gameType == XEnumConst.GameCollection.GameType.GoldenMiner then
        self:_ContinueGoldenMiner(gameCfg)
    elseif gameType == XEnumConst.GameCollection.GameType.Game2048 then
        self:_ContinueGame2048(gameCfg)
    elseif gameType == XEnumConst.GameCollection.GameType.FangKong then
        self:_ContinueFangKuai(gameCfg)
    end
end

function XGameCollectionControl:GiveUpGame(gameType, cb)
    gameType = self:_ResolveGameType(gameType)
    if not XTool.IsNumberValid(gameType) then
        if cb then
            cb()
        end
        return
    end

    self:SetSelectedGameType(gameType)
    local gameCfg = self:GetGameCfg(gameType)
    if XTool.IsTableEmpty(gameCfg) then
        if cb then
            cb()
        end
        return
    end

    if gameType == XEnumConst.GameCollection.GameType.GoldenMiner then
        self:_GiveUpGoldenMiner(gameCfg, cb)
    elseif gameType == XEnumConst.GameCollection.GameType.Game2048 then
        self:_GiveUpGame2048(gameCfg, cb)
    elseif gameType == XEnumConst.GameCollection.GameType.FangKong then
        self:_GiveUpFangKuai(gameCfg, cb)
    elseif cb then
        cb()
    end
end

function XGameCollectionControl:IsGamePlaying(gameType)
    gameType = self:_ResolveGameType(gameType)
    if not XTool.IsNumberValid(gameType) then
        return false
    end

    if gameType == XEnumConst.GameCollection.GameType.GoldenMiner then
        return XMVCA.XGoldenMiner:CheckIsHaveGameStage()
    end

    if gameType == XEnumConst.GameCollection.GameType.Game2048 then
        return not XTool.IsTableEmpty(XMVCA.XGame2048:GetCurStageData())
    end

    if gameType == XEnumConst.GameCollection.GameType.FangKong then
        local gameCfg = self:GetGameCfg(gameType)
        return XTool.IsNumberValid(self:_GetFangKuaiPlayingStageId(gameCfg))
    end

    return false
end

function XGameCollectionControl:IsCanGiveUp(gameType)
    return self:IsGamePlaying(gameType)
end

function XGameCollectionControl:TryOpenExitRecord()
    local record = self._Model:PopPendingExitRecord()
    if XTool.IsTableEmpty(record) then
        return
    end

    XLuaUiManager.Open("UiMiniGamesCollectionBreakTheRecord", record.GameName, record.NewScore)
end

function XGameCollectionControl:_ResolveGameType(gameType)
    if XTool.IsNumberValid(gameType) then
        return gameType
    end

    local selectedGameType = self:GetSelectedGameType()
    if XTool.IsNumberValid(selectedGameType) then
        return selectedGameType
    end

    local launchContext = XMVCA.XGameCollection:GetLaunchContext()
    if not XTool.IsTableEmpty(launchContext) then
        return launchContext.GameType
    end

    local activityCfgs = self:GetActivityCfgs()
    if not XTool.IsTableEmpty(activityCfgs) then
        return GetGameType(activityCfgs[1])
    end
end

function XGameCollectionControl:_StartLaunchSession(gameType, stageId, snapshot)
    XMVCA.XGameCollection:SetLaunchContext(gameType, stageId)
    self._Model:SetGameSnapshot(gameType, snapshot)
end

function XGameCollectionControl:_ClearLaunchSession(gameType)
    local launchContext = XMVCA.XGameCollection:GetLaunchContext()
    if XTool.IsTableEmpty(launchContext) then
        return
    end

    if XTool.IsNumberValid(gameType) and launchContext.GameType ~= gameType then
        return
    end

    XMVCA.XGameCollection:ClearLaunchContext()
    self._Model:ClearGameSnapshot(launchContext.GameType)
end

function XGameCollectionControl:_CreateGame2048Snapshot(stageId)
    return {
        StageId = stageId,
        EnterMaxScore = XMVCA.XGame2048:GetStageMaxScoreById(stageId) or 0,
    }
end

function XGameCollectionControl:_BuildEnterScoreSnapshot(gameType)
    return {
        EnterMaxScore = self._Model:GetMaxScore(gameType) or 0,
    }
end

function XGameCollectionControl:_GetFangKuaiPlayingStageId(gameCfg)
    local stageId = gameCfg and gameCfg.StageId or 0
    if not XTool.IsNumberValid(stageId) then
        return 0
    end

    local chapterId = XMVCA.XFangKuai:GetChapterIdByStage(stageId)
    if not XTool.IsNumberValid(chapterId) then
        return 0
    end

    return XMVCA.XFangKuai:GetCurStageId(chapterId)
end

function XGameCollectionControl:_RequestEnterGoldenMiner(gameCfg)
    local gameType = GetGameType(gameCfg)
    local useCharacterId = XMVCA.XGoldenMiner:GetUseCharacterId()
    XMVCA.XGoldenMiner:RequestGoldenMinerEnterGame(useCharacterId, function()
        self:_StartLaunchSession(gameType, gameCfg.StageId, self:_BuildEnterScoreSnapshot(gameType))
        XMVCA.XGoldenMiner:OpenGameUi()
    end)
end

function XGameCollectionControl:_ContinueGoldenMiner(gameCfg)
    local gameType = GetGameType(gameCfg)
    self:_StartLaunchSession(gameType, gameCfg.StageId, self:_BuildEnterScoreSnapshot(gameType))
    XMVCA.XGoldenMiner:ContinueGame()
end

function XGameCollectionControl:_GiveUpGoldenMiner(gameCfg, cb)
    if not XMVCA.XGoldenMiner:CheckIsHaveGameStage() then
        if cb then
            cb()
        end
        return
    end

    local gameType = GetGameType(gameCfg)
    local enterMaxScore = self._Model:GetMaxScore(gameType) or 0
    local stageScores = XMVCA.XGoldenMiner:GetStageScores()
    XMVCA.XGoldenMiner:RequestGoldenMinerExitGame(0, function()
        XMVCA.XGameCollection:RecordExitForGame(gameType, {
            Score = stageScores or 0,
            EnterMaxScore = enterMaxScore,
            IsSettled = true,
        })
        self:_ClearLaunchSession(gameType)
        if cb then
            cb()
        end
    end, nil, stageScores, stageScores)
end

function XGameCollectionControl:_RequestEnterGame2048(gameCfg)
    local gameType = GetGameType(gameCfg)
    local stageId = gameCfg.StageId
    if not XTool.IsNumberValid(stageId) then
        XMVCA.XGame2048:ExOpenMainUi()
        return
    end

    local snapshot = self:_CreateGame2048Snapshot(stageId)
    local stageData = XMVCA.XGame2048:GetCurStageData()
    if not XTool.IsTableEmpty(stageData) then
        if stageData.StageId == stageId then
            XMVCA.XGame2048:SetCurStageId(stageId)
            self:_StartLaunchSession(gameType, stageId, snapshot)
            XLuaUiManager.Open(UiNameGame2048, stageData)
            return
        end

        XMVCA.XGame2048:RequestGame2048GiveUp(function()
            XMVCA.XGame2048:RequestGame2048EnterStage(stageId, function(res)
                XMVCA.XGame2048:SetCurStageId(stageId)
                self:_StartLaunchSession(gameType, stageId, snapshot)
                XLuaUiManager.Open(UiNameGame2048, res.StageContext)
            end)
        end)
        return
    end

    XMVCA.XGame2048:RequestGame2048EnterStage(stageId, function(res)
        XMVCA.XGame2048:SetCurStageId(stageId)
        self:_StartLaunchSession(gameType, stageId, snapshot)
        XLuaUiManager.Open(UiNameGame2048, res.StageContext)
    end)
end

function XGameCollectionControl:_ContinueGame2048(gameCfg)
    local stageData = XMVCA.XGame2048:GetCurStageData()
    if XTool.IsTableEmpty(stageData) then
        return
    end

    XMVCA.XGame2048:SetCurStageId(stageData.StageId)
    self:_StartLaunchSession(GetGameType(gameCfg), stageData.StageId, self:_CreateGame2048Snapshot(stageData.StageId))
    XLuaUiManager.Open(UiNameGame2048, stageData)
end

function XGameCollectionControl:_GiveUpGame2048(gameCfg, cb)
    local stageData = XMVCA.XGame2048:GetCurStageData()
    if XTool.IsTableEmpty(stageData) then
        if cb then
            cb()
        end
        return
    end

    local gameType = GetGameType(gameCfg)
    local stageId = stageData.StageId
    local enterMaxScore = self._Model:GetMaxScore(gameType) or 0
    XMVCA.XGame2048:RequestGame2048Settle(XMVCA.XGame2048.EnumConst.SettleType.ByHand,function()
        XMVCA.XGameCollection:RecordExitForGame(gameType, {
            Score = XMVCA.XGame2048:GetStageMaxScoreById(stageId) or 0,
            EnterMaxScore = enterMaxScore,
            IsSettled = true,
        })
        self:_ClearLaunchSession(gameType)
        if cb then
            cb()
        end
    end)
end

function XGameCollectionControl:_RequestEnterFangKuai(gameCfg)
    local gameType = GetGameType(gameCfg)
    local targetStageId = gameCfg.StageId
    if not XTool.IsNumberValid(targetStageId) then
        XMVCA.XFangKuai:ExOpenMainUi()
        return
    end

    XMVCA.XFangKuai:OpenStageFromCollection(targetStageId, function(stageId)
        self:_StartLaunchSession(gameType, stageId or targetStageId, self:_BuildEnterScoreSnapshot(gameType))
    end)
end

function XGameCollectionControl:_ContinueFangKuai(gameCfg)
    local gameType = GetGameType(gameCfg)
    local currentStageId = self:_GetFangKuaiPlayingStageId(gameCfg)
    if not XTool.IsNumberValid(currentStageId) then
        return
    end

    XMVCA.XFangKuai:OpenStageFromCollection(currentStageId, function(stageId)
        self:_StartLaunchSession(gameType, stageId or currentStageId, self:_BuildEnterScoreSnapshot(gameType))
    end)
end

function XGameCollectionControl:_GiveUpFangKuai(gameCfg, cb)
    local currentStageId = self:_GetFangKuaiPlayingStageId(gameCfg)
    if not XTool.IsNumberValid(currentStageId) then
        if cb then
            cb()
        end
        return
    end

    local gameType = GetGameType(gameCfg)
    local enterMaxScore = self._Model:GetMaxScore(gameType) or 0
    XMVCA.XFangKuai:GiveUpStageFromCollection(currentStageId, function()
        local settleData = XMVCA.XFangKuai:GetCurStageSettleData()
        XMVCA.XGameCollection:RecordExitForGame(gameType, {
            Score = settleData and settleData.Point or 0,
            EnterMaxScore = enterMaxScore,
            IsSettled = true,
        })
        self:_ClearLaunchSession(gameType)
        if cb then
            cb()
        end
    end)
end

function XGameCollectionControl:OpenDialog(title,context,surecb)
    XLuaUiManager.Open("UiGoldenMinerGiveUp",title,context,surecb) 

end

return XGameCollectionControl
