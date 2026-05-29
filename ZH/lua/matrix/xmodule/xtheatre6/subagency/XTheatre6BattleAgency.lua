---@class XTheatre6BattleAgency : XAgency
---@field private _Model XTheatre6Model
---@field _MainAgency XTheatre6Agency
local XTheatre6BattleAgency = XClass(XAgency, "XTheatre6BattleAgency")

---需要乘基数的属性枚举
local EnlargedAttribs = {
    [XDlcNpcAttribType.Speed] = true,
    [XDlcNpcAttribType.JumpSpeed] = true,
    [XDlcNpcAttribType.RunSpeed] = true,
    [XDlcNpcAttribType.RunSpeedCOE] = true,
    [XDlcNpcAttribType.JumpSpeedCOE] = true,
    [XDlcNpcAttribType.IdleJumpSpeedCOE] = true,
    [XDlcNpcAttribType.WalkJumpSpeedCOE] = true,
    [XDlcNpcAttribType.SprintJumpSpeedCOE] = true,
    [XDlcNpcAttribType.RunStartJumpSpeedCOE] = true,
    [XDlcNpcAttribType.SprintStartJumpSpeedCOE] = true,
    [XDlcNpcAttribType.RotationSpeed] = true,
    [XDlcNpcAttribType.WalkSpeed] = true,
    [XDlcNpcAttribType.WalkSpeedCOE] = true,
    [XDlcNpcAttribType.SprintSpeed] = true,
    [XDlcNpcAttribType.SprintSpeedCOE] = true,
}

---活动特殊属性
local ActivitySpecialAttribs = {
    Stamina = 0, --体力
    WrestlePoint = 1, --拼刀点数
    OverClock = 2, --超算
    OverClockEfficiency = 3, --超算效率
}

local AttrType = XEnumConst.Theatre6.AttrType

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
    self:_CalNpcAttribsAfterEnterFightRequest(autoChessData)
    return self:_GetXAutoChessData(autoChessData, true)
end

---@param autoChessData XTheatre6NpcData
function XTheatre6BattleAgency:_CalNpcAttribsAfterEnterFightRequest(autoChessData, isSelfData)
    if XTool.IsTableEmpty(autoChessData) then
        return
    end
    self:_AddCharacterBaseAttr(autoChessData)
end

---@param autoChessData XTheatre6NpcData
function XTheatre6BattleAgency:_AddFightAttribute(characterId, autoChessData, attrId, attrValue)
    local characterCfg = self._Model:GetCharacterConfig(characterId)
    local dlcAttrGroupCfg = XMVCA.XDlcWorld:GetAttributeConfigById(characterCfg.DlcAttrGroup)
    local attrCfg = self._Model:GetAttrConfig(attrId)
    local attrKey = attrCfg.AttrKey

    if attrCfg.AttrType == AttrType.Dlc then
        local dlcAttrValue = dlcAttrGroupCfg[attrKey]
        local attrId = XDlcNpcAttribType[attrKey]
        local initValue = autoChessData.Attribs[attrId] or 0
        if EnlargedAttribs[attrKey] then
            autoChessData.Attribs[attrId] = initValue + attrValue + XMath.ToMinInt(dlcAttrValue * self._DlcWorldAttribMultyBase)
        else
            autoChessData.Attribs[attrId] = initValue + attrValue + dlcAttrValue
        end
    elseif attrCfg.AttrType == AttrType.Activity then
        local activityAttrId = ActivitySpecialAttribs[attrKey]
        if not activityAttrId then
            XLog.Error(string.format("Gameplay属性未定义：%s", attrKey))
        else
            local initValue = autoChessData.GameplayAttribs[activityAttrId] or 0
            autoChessData.GameplayAttribs[activityAttrId] = initValue + attrValue
        end
    end
end

---角色基础属性
---@param autoChessData XTheatre6NpcData
function XTheatre6BattleAgency:_AddCharacterBaseAttr(autoChessData)
    if not XTool.IsNumberValid(autoChessData.CharacterId) then
        return
    end

    local characterCfg = self._Model:GetCharacterConfig(autoChessData.CharacterId)
    if not characterCfg then
        return
    end

    for attrId, attrValue in ipairs(characterCfg.AttrValue) do
        self:_AddFightAttribute(autoChessData.CharacterId, autoChessData, attrId, attrValue)
    end
end

---@param autoChessDataServer XTheatre6NpcData
function XTheatre6BattleAgency:_GetXAutoChessData(autoChessDataServer, isDebug)
    local autoChessData = CS.XTheatre6NpcData()
    autoChessData.CharacterId = autoChessDataServer.CharacterId
    autoChessData.FashionId = autoChessDataServer.FashionId

    for i, v in ipairs(autoChessDataServer.Skills) do
        autoChessData.Skills:Add(v)
    end

    if autoChessDataServer.Relics then
        for i, v in ipairs(autoChessDataServer.Relics) do
            autoChessData.Relics:Add(v)
        end

        if isDebug then
            self:_DebugAddRelicsEffect(autoChessDataServer, autoChessData)
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

---正常流程下，Relic（饰品/遗物）的magicId,是服务端下发的,但是在测试流程下，需要客户端自己来
---@param autoChessDataServer XTheatre6NpcData
function XTheatre6BattleAgency:_DebugAddRelicsEffect(autoChessDataServer, autoChessData)
    for i, id in ipairs(autoChessDataServer.Relics) do
        local cfg = self._Model:GetAttrPackConfig(id)
        for _, buffId in ipairs(cfg.BuffIds) do
            autoChessData.MagicIds:Add(buffId)
        end

        for i, attrId in ipairs(cfg.AttrTypes) do
            local attrNum = cfg.AttrNums[i]
            self:_AddFightAttribute(autoChessDataServer.CharacterId, autoChessDataServer, attrId, attrNum)
        end
    end
end

--endregion

--region 正式战斗

function XTheatre6BattleAgency:RequestDlcSingleEnterFight(levelId, successCb, errorCb)
    local worldId = self._Model:GetWorldId()
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

        local worldData = res.WorldData
        local args = self:_GetXFightClientArgs()
        local csWorldData = self:_GetXWorldData(worldData)

        XLuaUiManager.Remove("UiDialog")
        self._MainAgency:ClearPendingSettleData()

        CS.StatusSyncFight.XFightClient.RequestExitFight()
        CS.StatusSyncFight.XFight.Init()
        CS.StatusSyncFight.XFightClient.EnterFight(csWorldData, XPlayer.Id, args)

        if successCb then
            successCb(worldData)
        end
    end)
end

function XTheatre6BattleAgency:_GetXFightClientArgs()
    local args = CS.StatusSyncFight.XFightClientArgs()
    --加载进度回调
    args.LoadProgressCb = function(process)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS, XPlayer.Id, process)
    end
    --关闭 loading ui
    args.CloseLoadingUiCb = function()
        XLuaUiManager.SafeClose("UiTheatre6Loading")
    end
    --结算
    args.SettleCb = function(result, summary)
        self:RequestNormalSettle(result, summary)
    end
    --客户端本地中断游戏
    args.InterruptFightCb = function(result, summary)
        self:RequestNormalSettle(result, summary)
    end
    return args
end

function XTheatre6BattleAgency:_GetXWorldData(worldData)
    local csWorldData = CS.XWorldData()
    csWorldData.WorldId = worldData.WorldId
    csWorldData.LevelId = worldData.LevelId
    csWorldData.WorldType = worldData.WorldType

    csWorldData.Theatre6GameplayData = CS.XTheatre6GameplayData()
    csWorldData.Theatre6GameplayData.SelfData = self:_GetXWorldGameplayData(worldData.Theatre6GameplayData.SelfData)
    csWorldData.Theatre6GameplayData.EnemyData = self:_GetXWorldGameplayData(worldData.Theatre6GameplayData.EnemyData)

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

    local totalScore = modelData.ScoreTotal
    local monsterId = roomData.SelectedMonsterId --战斗房间后是新楼层，PlayModeData和RoomData变成了下一层的数据
    local isChooseRoom = roomData.RoomType == XEnumConst.Theatre6.RoomType.ChooseOption
    
    self._Model:ClearRoomFightInfo()

    XNetwork.CallWithAutoHandleErrorCode("DlcSingleFightSettleRequest", contentBytes, function(res)
        XLuaUiManager.Open("UiTheatre6RoundSettlement", res.DlcFightSettleData, monsterId, totalScore, isChooseRoom)
    end, true)
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