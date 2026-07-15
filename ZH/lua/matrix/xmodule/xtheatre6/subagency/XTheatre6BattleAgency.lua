---@class XTheatre6BattleAgency : XAgency
---@field private _Model XTheatre6Model
---@field _MainAgency XTheatre6Agency
local XTheatre6BattleAgency = XClass(XAgency, "XTheatre6BattleAgency")

local SettlementStatus = XEnumConst.Theatre6.Settlement

function XTheatre6BattleAgency:OnInit()
    self._DlcWorldAttribMultyBase = 1000 --基础属性配置值乘法基数
end

function XTheatre6BattleAgency:InitRpc()

end

function XTheatre6BattleAgency:InitEvent()

end

function XTheatre6BattleAgency:OnRelease()

end

--region 黑幕进战斗

---用于控制台测试
---@param autoChessData XTheatre6NpcData
function XTheatre6BattleAgency:TestCalNpcAttribsAndBackXAutoChessData(autoChessData)
    return self:_GetXAutoChessData(autoChessData)
end

---@param autoChessDataServer XTheatre6NpcData
function XTheatre6BattleAgency:_GetXAutoChessData(autoChessDataServer)
    local autoChessData = CS.XTheatre6NpcData()
    autoChessData.CharacterId = autoChessDataServer.CharacterId
    autoChessData.FashionId = autoChessDataServer.FashionId
    if XTool.IsNumberValid(autoChessDataServer.FashionId) then
        autoChessData.WeaponIds = self._Model:GetFashionConfig(autoChessDataServer.FashionId).DlcWeaponIds
    end

    for i, v in ipairs(autoChessDataServer.Skills) do
        autoChessData.Skills:Add(v)
    end

    if autoChessDataServer.Relics then
        for i, v in ipairs(autoChessDataServer.Relics) do
            autoChessData.Relics:Add(v)
        end
    end

    if autoChessDataServer.MagicIds then
        for i, v in pairs(autoChessDataServer.MagicIds) do
            autoChessData.MagicIds[i] = v
        end
    end

    for k, v in pairs(autoChessDataServer.Attribs) do
        autoChessData.Attribs:Add(k, v)
    end

    for k, v in pairs(autoChessDataServer.GameplayAttribs) do
        autoChessData.GameplayAttribs:Add(k, v)
    end

    return autoChessData
end

--endregion

--region 正式战斗

function XTheatre6BattleAgency:RequestDlcSingleEnterFight(worldId, levelId, isPvp, isContinue, errorCb)
    XNetwork.Call("DlcSingleEnterFightRequest", { WorldId = worldId, LevelId = levelId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if errorCb then
                errorCb()
            end
            return
        end

        if XFightUtil.IsFighting() then
            XLog.Error("请求肉鸽6单机战斗失败：处于其他战斗中...")
            return
        end

        if not isPvp or not isContinue then
            self._Model.Pvp:InitBattleResults()
        end

        local worldData = res.WorldData
        local args = self:_GetXFightClientArgs(isPvp)
        local csWorldData = self:_GetXWorldData(worldData, isPvp)

        XLuaUiManager.Remove("UiDialog")
        self._MainAgency:ClearPendingSettleData()
        self._Model.Pvp:InitSummaryData()

        CS.StatusSyncFight.XFightClient.RequestExitFight()
        CS.StatusSyncFight.XFight.Init()
        CS.StatusSyncFight.XFightClient.EnterFight(csWorldData, XPlayer.Id, args)
    end)
end

function XTheatre6BattleAgency:_GetXFightClientArgs(isPvp)
    local args = CS.StatusSyncFight.XFightClientArgs()

    local function CheckPvpActivityTime()
        if not isPvp or self._MainAgency:IsPvpInActivityTime() then
            return true
        end

        self._MainAgency:HandlePvpActivityEnd()
        return false
    end

    --加载进度回调
    args.LoadProgressCb = function(process)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS, XPlayer.Id, process)
    end
    --关闭 loading ui
    args.CloseLoadingUiCb = function()
        XLuaUiManager.SafeClose("UiTheatre6Loading")
        XLuaUiManager.SafeClose("UiTheatre6PVPLoading")
        XLuaUiManager.SafeClose("UiBlackScreen")
    end
    --结算
    args.SettleCb = function(result, summary)
        if not CheckPvpActivityTime() then
            return
        end

        self:RequestNormalSettle(result, summary)
    end
    --客户端本地中断游戏
    args.InterruptFightCb = function(result, summary)
        if not CheckPvpActivityTime() then
            return
        end

        if isPvp then
            self:RequestPvpGiveUpFight(summary)
        else
            self:RequestNormalSettle(result, summary)
        end
    end
    return args
end

function XTheatre6BattleAgency:_GetXWorldData(worldData, isPvp)
    local csWorldData = CS.XWorldData()
    csWorldData.WorldId = worldData.WorldId
    csWorldData.LevelId = worldData.LevelId
    csWorldData.WorldType = worldData.WorldType

    csWorldData.Theatre6GameplayData = CS.XTheatre6GameplayData()
    csWorldData.Theatre6GameplayData.SelfData = self:_GetXWorldGameplayData(worldData.Theatre6GameplayData.SelfData)
    csWorldData.Theatre6GameplayData.EnemyData = self:_GetXWorldGameplayData(worldData.Theatre6GameplayData.EnemyData)

    if isPvp then
        csWorldData.Theatre6GameplayData.RoundNum = worldData.Theatre6GameplayData.RoundNum
        csWorldData.Theatre6GameplayData.RoundResults = self._Model.Pvp:GetBattleResults() or table.empty
    end

    if not XTool.IsTableEmpty(worldData.PlayerSeeds) then
        for k, v in pairs(worldData.PlayerSeeds) do
            csWorldData.PlayerSeeds:Add(k, v)
        end
    end

    if not XTool.IsTableEmpty(worldData.Players) then
        for i, v in ipairs(worldData.Players) do
            csWorldData.Players:Add(self:_GetXWorldPlayerData(v))
        end
    end

    return csWorldData
end

function XTheatre6BattleAgency:_GetXWorldGameplayData(npcDataServer)
    local npcData = CS.XTheatre6NpcData()
    npcData.TemplateId = npcDataServer.TemplateId
    npcData.Name = npcDataServer.Name
    npcData.HeadFrameId = npcDataServer.HeadFrameId
    npcData.CharacterId = npcDataServer.CharacterId
    npcData.CharacterLevel = npcDataServer.CharacterLevel
    npcData.FashionId = npcDataServer.FashionId
    npcData.PvpEnvMagicId = npcDataServer.PvpEnvMagicId

    if not XTool.IsTableEmpty(npcDataServer.Attribs) then
        for k, v in pairs(npcDataServer.Attribs) do
            npcData.Attribs:Add(k, v)
        end
    end

    if not XTool.IsTableEmpty(npcDataServer.GameplayAttribs) then
        for k, v in pairs(npcDataServer.GameplayAttribs) do
            npcData.GameplayAttribs:Add(k, v)
        end
    end

    if not XTool.IsTableEmpty(npcDataServer.Skills) then
        for _, v in ipairs(npcDataServer.Skills) do
            npcData.Skills:Add(v)
        end
    end

    if not XTool.IsTableEmpty(npcDataServer.MagicIds) then
        for k, v in pairs(npcDataServer.MagicIds) do
            npcData.MagicIds:Add(k, v)
        end
    end

    if not XTool.IsTableEmpty(npcDataServer.WeaponIds) then
        npcData.WeaponIds = npcDataServer.WeaponIds
    end

    if not XTool.IsTableEmpty(npcDataServer.Relics) then
        for _, v in ipairs(npcDataServer.Relics) do
            npcData.Relics:Add(v)
        end
    end

    if not XTool.IsTableEmpty(npcDataServer.MagicIdsWithoutLevel) then
        for _, v in ipairs(npcDataServer.MagicIdsWithoutLevel) do
            npcData.MagicIdsWithoutLevel:Add(v)
        end
    end

    if not XTool.IsTableEmpty(npcDataServer.PvpBuffActionRecord) then
        for k, v in pairs(npcDataServer.PvpBuffActionRecord) do
            npcData.PvpBuffActionRecord:Add(k, v)
        end
    end

    return npcData
end

function XTheatre6BattleAgency:_GetXWorldPlayerData(playerDataServer)
    local worldPlayerData = CS.XWorldPlayerData()
    worldPlayerData.Id = playerDataServer.Id
    worldPlayerData.Name = playerDataServer.Name
    return worldPlayerData
end

---请求游戏正常结算
function XTheatre6BattleAgency:RequestNormalSettle(result, summaryData)
    local contentBytes = result:GetFightsResultsBytes()
    local roomData = self._Model:GetCurRoomData()
    local modelData = self._Model:GetCurPlayModeData()

    local totalScore = modelData and modelData.ScoreTotal
    local monsterId = roomData and roomData.SelectedMonsterId --战斗房间后是新楼层，PlayModeData和RoomData变成了下一层的数据
    local status = (roomData and roomData.RoomType == XEnumConst.Theatre6.RoomType.ChooseOption) and SettlementStatus.ChooseRoom or SettlementStatus.Normal

    self._Model:ClearRoomFightInfo()
    self._MainAgency:ClearGainTipsParams()

    XNetwork.CallWithAutoHandleErrorCode("DlcSingleFightSettleRequest", contentBytes, function(res)
        local settleData = res.DlcFightSettleData
        local pvpFightResult = settleData and settleData.Theatre6PvpFightResult
        local curPvpRound = pvpFightResult and #pvpFightResult.RoundResults or 0
        if pvpFightResult then
            status = SettlementStatus.Pvp
            self._Model.Pvp:UpdateBattleResultData(curPvpRound, pvpFightResult, summaryData)
        end
        if self:_IsPvpUnfinished(settleData) then
            -- 等待播放完胜利/失败动效后才发起下一场战斗
            local delayTime = self._Model:GetIntPvpClientConfigValue("NextPvpFightDelayTime")
            XScheduleManager.ScheduleOnce(function()
                if not XFightUtil.IsFighting() then
                    return
                end
                self:_SoftReenterPvpFight(settleData)
            end, delayTime)
            return
        end
        if status == SettlementStatus.Pvp then
            if not self._Model.Pvp:IsSummaryDataComplete(curPvpRound) then
                --战斗记录不完整（中途断线），直接进入段位结算界面
                XLuaUiManager.Open("UiTheatre6PVPSettlement", pvpFightResult)
                return
            end
        end
        XLuaUiManager.Open("UiTheatre6RoundSettlement", settleData, monsterId, totalScore, status)
    end, true)
end

---PVP是否未完成（3局2胜制）
---@return boolean
function XTheatre6BattleAgency:_IsPvpUnfinished(settleData)
    if not settleData or not settleData.Theatre6PvpFightResult then
        return false
    end

    -- List<bool> RoundResults; 3 局结果（按局序，true=胜）
    local roundResults = settleData.Theatre6PvpFightResult.RoundResults
    local roundCount = roundResults and #roundResults or 0
    local loseCount = 0
    for i = 1, roundCount do
        if not roundResults[i] then
            loseCount = loseCount + 1
        end
    end
    -- 3局2胜，如果前两场都失败了，就不需要进行第三场了，否则需要完成三场
    local isPvpFinished = (roundCount == 2 and loseCount == 2) or roundCount >= 3
    return not isPvpFinished
end

---进入下一局PVP战斗
function XTheatre6BattleAgency:_SoftReenterPvpFight(settleData)
    if not settleData or not settleData.ResultData or not settleData.ResultData.WorldData then
        return
    end
    XLuaUiManager.Open("UiBlackScreen", nil, nil, nil, nil, 1)
    local worldId = settleData.ResultData.WorldData.WorldId
    local levelId = settleData.ResultData.WorldData.LevelId
    XNetwork.Call("DlcSingleEnterFightRequest", { WorldId = worldId, LevelId = levelId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local worldData = res.WorldData
        local csWorldData = self:_GetXWorldData(worldData, true)
        CS.StatusSyncFight.XFightClient.SoftReenterFight(csWorldData)
    end)
end

---玩家主动放弃Pvp战斗
function XTheatre6BattleAgency:RequestPvpGiveUpFight(summaryData)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpGiveUpFightRequest", nil, function(res)
        local pvpFightResult = res.FightResult
        local curPvpRound = #pvpFightResult.RoundResults
        self._Model.Pvp:UpdateBattleResultData(curPvpRound, pvpFightResult, summaryData)
        self:OpenPvpSettlement(pvpFightResult)
    end)
end

---打开Pvp结算界面。如果战斗记录不完整（中途断线），直接进入段位结算界面
function XTheatre6BattleAgency:OpenPvpSettlement(pvpFightResult)
    local totalPvpRound = #pvpFightResult.RoundResults
    if self._Model.Pvp:IsSummaryDataComplete(totalPvpRound) then
        XLuaUiManager.Open("UiTheatre6RoundSettlement", { Theatre6PvpFightResult = pvpFightResult }, nil, nil, SettlementStatus.Pvp)
    else
        XLuaUiManager.Open("UiTheatre6PVPSettlement", pvpFightResult)
    end
end

--endregion

return XTheatre6BattleAgency

---@class XTheatre6NpcData
---@field TemplateId number 玩家id或者npcId
---@field Name string 玩家名字
---@field HeadFrameId string 玩家头像
---@field CharacterId number
---@field CharacterLevel number
---@field Attribs table<number,number>
---@field GameplayAttribs table<number,number>
---@field Skills number[]
---@field MagicIds table<number,number>
---@field FashionId number
---@field WeaponIds number[]
---@field Relics number[]
---@field PvpEnvMagicId number
---@field PvpBuffActionRecord table<number,number>
