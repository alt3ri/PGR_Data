--- Agency的组件，封装进入战斗相关的接口
---@class XTheatre5BattleAgencyCom
---@field private _OwnerAgency XTheatre5Agency
---@field private _Model XTheatre5Model
local XTheatre5BattleAgencyCom = XClass(nil, 'XTheatre5BattleAgencyCom')

local DlcWorldAttribMultyBase = 1000 -- 基础属性配置值乘法基数

function XTheatre5BattleAgencyCom:Init(ownerAgency, model)
    self._OwnerAgency = ownerAgency
    self._Model = model
    self:_InitSimpleSettleContent()
    self._RankDataCache = {}
    self._RankDataLastReqTime = {}
end

function XTheatre5BattleAgencyCom:Release()
    self._OwnerAgency = nil
    self._Model = nil
    self._AdvanceSettleContent = nil
    self._RankDataCache = nil
    self._RankDataLastReqTime = nil
end

--region 模拟构造战斗数据

--- 初始化战斗数据通用部分的结构
function XTheatre5BattleAgencyCom:_InitSimpleSettleContent()
    --- 非正常结束战斗的结算数据，因为兼容性而存在多层嵌套，因此复用
    self._SimpleSttleContent = {
        DlcReportWorldResult = {
            DlcFightSettleData = {
                SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.None,
                WorldData = {
                    WorldId = nil,
                    Players = {
                        [1] = {
                            Id = nil
                        }
                    }
                },
                PlayerData = nil
            }
        }
    }
end

--- 局外构造战斗数据用于提前结算
function XTheatre5BattleAgencyCom:_GetSimpleSettleContentForAdvance()
    local worldData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.WorldData
    local dlcFightSettleData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData

    worldData.WorldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())
    worldData.Players[1].Id = XPlayer.Id
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.IsPlayerWin = false
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.AdvanceExit

    dlcFightSettleData.PlayerData = {
        [XPlayer.Id] = {
            PlayerId = XPlayer.Id
        }
    }

    XMessagePack.MarkAsTable(dlcFightSettleData.PlayerData)

    return self._SimpleSttleContent
end

--- 局外构造战斗数据用于放弃战斗
function XTheatre5BattleAgencyCom:_GetSimpleSettleContentForGiveUp()
    local worldData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.WorldData
    local dlcFightSettleData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData

    worldData.WorldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())
    worldData.Players[1].Id = XPlayer.Id
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.IsPlayerWin = false
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.None

    dlcFightSettleData.PlayerData = {
        [XPlayer.Id] = {
            PlayerId = XPlayer.Id
        }
    }

    XMessagePack.MarkAsTable(dlcFightSettleData.PlayerData)

    return self._SimpleSttleContent
end

--- 局外构造战斗数据用于战斗中断时的回合结算
function XTheatre5BattleAgencyCom:_GetSimpleSettleContentForBattleInterrupt()
    local worldData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.WorldData
    local dlcFightSettleData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData

    worldData.WorldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())
    worldData.Players[1].Id = XPlayer.Id
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.IsPlayerWin = false
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.PlayerOffline

    dlcFightSettleData.PlayerData = {
        [XPlayer.Id] = {
            PlayerId = XPlayer.Id
        }
    }

    XMessagePack.MarkAsTable(dlcFightSettleData.PlayerData)

    return self._SimpleSttleContent
end
--endregion

--region Network
--- 请求游戏提前结算
function XTheatre5BattleAgencyCom:RequestTheatre5AdvanceSettle(cb)
    local content = self:_GetSimpleSettleContentForAdvance()

    XNetwork.Call("DlcSingleFightSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult

            if not XTool.IsTableEmpty(autoChessResult.CommonFightCnt) then
                self._Model:SetCharacterWinGameCountData(autoChessResult.CommonFightCnt)
            end

            self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)
            if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
                self._Model.PVEAdventureData:UpdateTempChapterData()
                self._Model.PVEAdventureData:UpdatePVEChapterData(autoChessResult.PveChapterData)
                self._Model.PVERougeData:UpdatePveStoryLine(autoChessResult.PveStoryLineData)
            end

            self._Model.CurAdventureData:HandleAutoChessGameplayResult(autoChessResult)
        end

        if cb then
            cb(true, res)
        end

        XLuaUiManager.Open('UiTheatre5Settlement', res.DlcFightSettleData)
    end)
end

--- 请求游戏结算-放弃战斗
function XTheatre5BattleAgencyCom:RequestTheatre5GiveUpSettle(cb)
    local content = self:_GetSimpleSettleContentForGiveUp()

    XNetwork.Call("DlcSingleFightSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateCurPlayStatus(XMVCA.XTheatre5.EnumConst.PlayStatus.BattleFinish)

        local isFinish = false

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)

            if autoChessResult.IsFinish then
                if self._Model.CurAdventureData then
                    self._Model.CurAdventureData:ClearData()
                end
                isFinish = true
            end
            if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
                self._Model.PVEAdventureData:UpdateTempChapterData()
                self._Model.PVEAdventureData:UpdatePVEChapterData(autoChessResult.PveChapterData)
                self._Model.PVERougeData:UpdatePveStoryLine(autoChessResult.PveStoryLineData)
            end
            self._Model.CurAdventureData:HandleAutoChessGameplayResult(autoChessResult)
        end

        if cb then
            cb(true, isFinish)
        end
    end)
end

--- 请求游戏结算-掉线等中断战斗的情况
function XTheatre5BattleAgencyCom:RequestTheatre5InterruptBattle(cb)
    local content = self:_GetSimpleSettleContentForBattleInterrupt()

    XNetwork.Call("DlcSingleFightSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end
        local curPlayMode = self._Model:GetCurPlayingMode()
        local status = XMVCA.XTheatre5.EnumConst.PlayStatus.Matching
        if curPlayMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
            status = XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping
        end

        self._Model.CurAdventureData:UpdateCurPlayStatus(status)

        local isFinish = false

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)

            if autoChessResult.IsFinish then
                if curPlayMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
                    self._Model.PVEAdventureData:UpdateTempChapterData()
                    self._Model.PVEAdventureData:UpdatePVEChapterData(autoChessResult.PveChapterData)
                    self._Model.PVERougeData:UpdatePveStoryLine(autoChessResult.PveStoryLineData)
                end
                isFinish = true
            end
            self._Model.CurAdventureData:HandleAutoChessGameplayResult(autoChessResult)
        end

        if cb then
            cb(true, isFinish)
        end

        if isFinish then
            XLuaUiManager.Open('UiTheatre5Settlement', res.DlcFightSettleData)
        end
    end)
end

--- 请求游戏正常结算
function XTheatre5BattleAgencyCom:RequestTheatre5NormalSettle(result, summaryData, cb)
    if self:_CheckPVPTimeEndInSettle() then
        return
    end

    local contentBytes = result:GetFightsResultsBytes()

    XNetwork.Call("DlcSingleFightSettleRequest", contentBytes, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:_CheckPVPTimeEndInSettle()
            if cb then
                cb(false)
            end

            return
        end

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            self._Model.CurAdventureData:UpdateHealth(autoChessResult.Health)
            self._Model.CurAdventureData:UpdateRoundNum(autoChessResult.RoundNum)

            if not XTool.IsTableEmpty(autoChessResult.CommonFightCnt) then
                self._Model:SetCharacterWinGameCountData(autoChessResult.CommonFightCnt)
            end

            if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
                self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)
            else
                if not autoChessResult.PveChapterData then
                    --章节结算
                    local isWin = res.DlcFightSettleData and res.DlcFightSettleData.ResultData and res.DlcFightSettleData.ResultData.IsPlayerWin
                    self._Model.PVEAdventureData:UpdateTempChapterData(isWin)
                end
                self._Model.PVEAdventureData:UpdatePVEChapterData(autoChessResult.PveChapterData) --关卡更新(胜利或失败)
                self._Model.PVERougeData:UpdatePveStoryLine(autoChessResult.PveStoryLineData)     --章节结束
            end
            self._Model.CurAdventureData:HandleAutoChessGameplayResult(autoChessResult)

            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_BATTLE_RESULT, res.DlcFightSettleData)

            -- 战斗校验结果
            if XTool.IsNumberValid(autoChessResult.CheckFailTimes) and autoChessResult.CheckFailTimes > self._Model.CurAdventureData:GetCheckFailTimes() then
                local limit = self._Model:GetTheatre5ConfigValByKey('BattleCheckFailTimesLimit')

                if autoChessResult.CheckFailTimes >= limit then
                    local finalSettleFunc = function()
                        -- 达到校验上限后服务端已做提前结算处理，直接显示结果
                        CS.StatusSyncFight.XFightClient.RequestExitFight()
                        XLuaUiManager.Open('UiTheatre5Settlement', res.DlcFightSettleData)
                    end

                    self._OwnerAgency:TryPopupDialogWithOneBtn(XUiHelper.GetText("TipTitle"),
                            self._Model:GetTheatre5ClientConfigText('BattleCheckFailEndGameTips'),
                            nil, finalSettleFunc, nil, nil, true)
                else
                    local restartFunc = function()
                        if self:_CheckPVPTimeEndInSettle() then
                            return
                        end

                        self:RequestDlcSingleEnterFight(0)
                    end

                    local finalSettleFunc = function()
                        if self:_CheckPVPTimeEndInSettle() then
                            return
                        end

                        -- 未达校验上限时需要手动请求提前结算
                        self:RequestTheatre5AdvanceSettle(function(success, advanceSettleRes)
                            if success then
                                CS.StatusSyncFight.XFightClient.RequestExitFight()

                                if advanceSettleRes then
                                    XLuaUiManager.Open('UiTheatre5Settlement', advanceSettleRes.DlcFightSettleData)
                                end
                            end
                        end)
                    end

                    self._OwnerAgency:TryPopupDialog(XUiHelper.GetText("TipTitle"),
                            self._Model:GetTheatre5ClientConfigText('BattleCheckFailRestartTips'),
                            nil, restartFunc, finalSettleFunc, nil, nil, true)
                end

                -- 校验失败

                -- 缓存
                self._Model.CurAdventureData:UpdateCheckFailTimes(autoChessResult.CheckFailTimes)
            else
                XLuaUiManager.Open('UiTheatre5RoundSettlement', res.DlcFightSettleData, summaryData)
            end
        end
        local battleStatus = XMVCA.XTheatre5.EnumConst.PlayStatus.BattleFinish
        if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
            if res.DlcFightSettleData and res.DlcFightSettleData.ResultData and res.DlcFightSettleData.ResultData.IsPlayerWin then
                battleStatus = XMVCA.XTheatre5.EnumConst.PlayStatus.PveEveHandle
            end
        end
        self._Model.CurAdventureData:UpdateCurPlayStatus(battleStatus)

        if cb then
            cb(true)
        end
    end, true)
end

--- 请求匹配
function XTheatre5BattleAgencyCom:RequestTheatre5Match(cb)
    XNetwork.Call("Theatre5MatchRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateMatchEnemyData(res.EnemyData)
        self._Model.CurAdventureData:UpdateLeaveShopCnt(res.LeaveShopCnt)

        if cb then
            cb(true, res.EnemyData)
        end
    end)
end

--- 打开匹配-加载界面
function XTheatre5BattleAgencyCom:OpenMatchLoadingUi(...)
    -- 打开前先锁定栈
    CsXUiManager.Instance:SetRevertAllLock(true)

    XLuaUiManager.Open("UiTheatre5Loading", ...)
end

--- 请求进入战斗
function XTheatre5BattleAgencyCom:RequestDlcSingleEnterFight(levelId, enterCb, successCb, delayEnterTime, errorCb)
    -- 获取当前活动的worldId
    local worldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())

    self._OwnerAgency:RequestDlcSingleEnterFight(worldId, levelId, function(success, worldData)
        if success then
            if worldData and worldData.AutoChessGameplayData then
                self._Model.CurAdventureData:UpdateCurPlayStatus(XMVCA.XTheatre5.EnumConst.PlayStatus.Battling)

                if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
                    self._Model.PVEAdventureData:UpdateEnemyData(worldData.AutoChessGameplayData.EnemyData.AutoChessData)
                end

                if worldData.AutoChessGameplayData.EnemyData then
                    self:_CalNpcAttribsAfterEnterFightRequest(worldData.AutoChessGameplayData.EnemyData.AutoChessData)
                end

                if worldData.AutoChessGameplayData.SelfData then
                    local isSelfData = true
                    self:_CalNpcAttribsAfterEnterFightRequest(worldData.AutoChessGameplayData.SelfData.AutoChessData, isSelfData)
                end

                if successCb then
                    successCb(worldData)
                end

                local enterFunc = function()
                    CsXBehaviorManager.Instance:Clear()
                    XTableManager.ReleaseAll(true)
                    CS.BinaryManager.ReleaseAllCache()
                    collectgarbage("collect")

                    CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal, CS.XUiSceneManager.Clear)
                    CsXUiManager.Instance:SetRevertAndReleaseLock(false)

                    local args = self:_GetXFightClientArgs()

                    local csWorldData = self:_GetXWorldData(worldData, levelId)
                    CS.StatusSyncFight.XFight.Init()

                    CS.StatusSyncFight.XFightClient.EnterFight(csWorldData, XPlayer.Id, args)

                    if enterCb then
                        enterCb(worldData)
                    end
                end

                if not XTool.IsNumberValid(delayEnterTime) then
                    delayEnterTime = 0
                end
                if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
                    CS.StatusSyncFight.XFightClient.RequestExitFight()
                    --todo: 目前战斗结束是异步逻辑，且暂未支持回调，先手动延迟
                    delayEnterTime = delayEnterTime + XScheduleManager.SECOND * 2
                end

                XScheduleManager.ScheduleOnce(function()
                    enterFunc()
                end, delayEnterTime)
            end
        else
            CsXUiManager.Instance:SetRevertAllLock(false)
            self:_CheckPVPTimeEndInSettle(false)
            if errorCb then
                errorCb()
            end
        end
    end)
end
--endregion

--region 战斗数据C#对象构造
function XTheatre5BattleAgencyCom:_GetXWorldData(worldData, levelId)
    local csWorldData = CS.XWorldData()

    csWorldData.Online = worldData.Online
    csWorldData.RoomId = worldData.RoomId
    csWorldData.WorldId = worldData.WorldId
    csWorldData.LevelId = worldData.LevelId
    csWorldData.MissionId = worldData.MissionId
    csWorldData.RebootId = worldData.RebootId
    csWorldData.IsTeaching = worldData.IsTeaching
    csWorldData.IsLocalDebug = worldData.IsLocalDebug
    csWorldData.WorldType = worldData.WorldType
    csWorldData.ServerControllerSeed = worldData.ServerControllerSeed
    csWorldData.IsSingleOnline = worldData.IsSingleOnline
    csWorldData.AutoChessGameplayData = CS.XAutoChessGameplayData()

    local autoChessGameplayData = csWorldData.AutoChessGameplayData
    local autoChessGameplayDataServer = worldData.AutoChessGameplayData

    autoChessGameplayData.SelfData = self:_GetXAutoChessNpcData(autoChessGameplayDataServer.SelfData)
    autoChessGameplayData.EnemyData = self:_GetXAutoChessNpcData(autoChessGameplayDataServer.EnemyData)

    --pve给敌人上buff
    if XTool.IsNumberValid(levelId) and autoChessGameplayData.EnemyData and autoChessGameplayData.EnemyData.AutoChessData then
        local magicDict = self._Model.PVEAdventureData:GetLevelEnemyMagicDict(levelId)
        if not XTool.IsTableEmpty(magicDict) then
            autoChessGameplayData.EnemyData.AutoChessData.MagicIds = magicDict
        end
    end

    if not XTool.IsTableEmpty(worldData.Players) then
        for i, v in ipairs(worldData.Players) do
            csWorldData.Players:Add(self:_GetXWorldPlayerData(v))
        end
    end

    return csWorldData
end

function XTheatre5BattleAgencyCom:_GetXAutoChessNpcData(autoChessNpcDataServer)
    local autoChessNpcData = CS.XAutoChessNpcData()

    autoChessNpcData.TemplateId = autoChessNpcDataServer.TemplateId
    autoChessNpcData.Name = autoChessNpcDataServer.Name
    autoChessNpcData.HeadFrameId = autoChessNpcDataServer.HeadFrameId
    autoChessNpcData.AutoChessData = self:_GetXAutoChessData(autoChessNpcDataServer.AutoChessData)

    return autoChessNpcData
end

---@param noLoop@防止因为配置错误导致的死循环
function XTheatre5BattleAgencyCom:CheckCondition(conditionId, autoChessDataServer, noLoop)
    local template = XConditionManager.GetConditionTemplate(conditionId)
    -- 这是测试代码, 这部分逻辑应该写在服务端上
    if template.Type == 17850 then
        local tag = template.Params[1]
        local color = template.Params[2]
        local amount = template.Params[3]
        -- 统计数量
        local count = 0
        for _, rune in ipairs(autoChessDataServer.RuneEvolves) do
            local runeId = rune.RuneId
            local runeConfig = self._Model:GetTheatre5ItemCfgById(runeId)
            if runeConfig then
                if runeConfig.Quality == color then
                    if tag == 0 then
                        count = count + 1
                    else
                        for i, runeTag in ipairs(runeConfig.Tags) do
                            if runeTag == tag then
                                count = count + 1
                                break
                            end
                        end
                    end
                end
            end
        end
        return count >= amount
    end
    if not string.IsNilOrEmpty(template.Formula) and not noLoop then
        --template.Formula格式是这样的, 1050291&1050292
        -- 遍历formula中的每个元素
        for id in string.gmatch(template.Formula, "%d+") do
            local numericId = tonumber(id)
            if not self:CheckCondition(numericId, autoChessDataServer, true) then
                return false
            end
        end
        return true -- 所有条件都满足才返回true
    end
    -- 其他condition放他过
    return true
end

function XTheatre5BattleAgencyCom:_GetXAutoChessData(autoChessDataServer, isDebug)
    local autoChessData = CS.XAutoChessData()

    autoChessData.CharacterId = autoChessDataServer.CharacterId
    autoChessData.FashionId = autoChessDataServer.FashionId
    -- 3.8新增武器id
    if autoChessData.FashionId ~= 0 then
        local fashionCfg = self._Model:GetTheatre5CharacterFashionCfgById(autoChessData.FashionId)
        if fashionCfg then
            -- 部分角色具有多个武器
            autoChessData.WeaponIds = fashionCfg.DlcWeaponId
        end
    end

    for k, v in pairs(autoChessDataServer.Attribs) do
        autoChessData.Attribs:Add(k, v)
    end

    for i, v in ipairs(autoChessDataServer.Skills) do
        autoChessData.Skills:Add(v)
    end

    -- v4.0新增可强化的符文
    if autoChessDataServer.RuneEvolves then
        for i, v in ipairs(autoChessDataServer.RuneEvolves) do
            autoChessData.RuneEvolves:Add(v)
        end
    end

    -- v4.0新增遗物
    if autoChessDataServer.Relics then
        for i, v in ipairs(autoChessDataServer.Relics) do
            autoChessData.Relics:Add(v)
        end

        -- 正常流程下，Relic（饰品/遗物）的magicId,是服务端下发的,但是在测试流程下，需要客户端自己来
        if isDebug then
            local baseAttr = {}
            for k, v in pairs(autoChessDataServer.Attribs) do
                baseAttr[k] = v
            end

            for i, v in ipairs(autoChessDataServer.Relics) do
                local relicId = v
                ---@type XTableTheatre5RelicEffect
                local effectConfigs = self._Model:GetRelicEffectConfigs(relicId)
                if effectConfigs then
                    for i = 1, #effectConfigs do
                        local effectConfig = effectConfigs[i].EffectConfig
                        local conditionId = effectConfigs[i].Condition
                        local isValid = true
                        if conditionId and conditionId ~= 0 then
                            if not self:CheckCondition(conditionId, autoChessDataServer) then
                                isValid = false
                            end
                        end
                        if isValid then
                            if effectConfig.Type == XMVCA.XTheatre5.EnumConst.Theatre5EffectType.AddBuff then
                                autoChessData.MagicIds:Add(effectConfig.Param[1])

                            elseif effectConfig.Type == XMVCA.XTheatre5.EnumConst.Theatre5EffectType.AddAttr then
                                local attrType = effectConfig.Param[1]
                                local baseAttrValue = baseAttr[attrType] or 0

                                --属性类型	固定值数值	万分比数值	特定变量	比例（万分比）
                                local fixVal = effectConfig.Param[2]
                                local rateVal = effectConfig.Param[3]
                                local specificVal = effectConfig.Param[4]
                                local specificRateVal = effectConfig.Param[5]

                                --属性改变=固定值+基础值*万分比+特定变量*比例 (基础值=角色基础属性+等级属性+符纹属性)
                                local changeValue = fixVal + baseAttrValue * rateVal / 10000 + specificVal * specificRateVal / 10000
                                if autoChessData.Attribs:ContainsKey(attrType) then
                                    autoChessData.Attribs[attrType] = autoChessData.Attribs[attrType] + changeValue
                            else
                                autoChessData.Attribs:Add(attrType, changeValue)
                            end
                            end
                        end
                    end
                end
            end
        end
    end

    if autoChessDataServer.MagicIds then
        for i, v in pairs(autoChessDataServer.MagicIds) do
            autoChessData.MagicIds[i] = v
        end
    end

    if autoChessDataServer.CharacterLevel then
        autoChessData.CharacterLevel = autoChessDataServer.CharacterLevel
    end

    return autoChessData
end

function XTheatre5BattleAgencyCom:_GetXWorldPlayerData(playerDataServer)
    local worldPlayerData = CS.XWorldPlayerData()

    worldPlayerData.Id = playerDataServer.Id
    worldPlayerData.Name = playerDataServer.Name

    return worldPlayerData
end

function XTheatre5BattleAgencyCom:_CalNpcAttribsAfterEnterFightRequest(autoChessData, isSelfData)
    if XTool.IsTableEmpty(autoChessData) then
        return
    end

    -- 角色基础属性
    if XTool.IsNumberValid(autoChessData.CharacterId) then
        ---@type XTableTheatre5Character
        local charaCfg = self._Model:GetTheatre5CharacterCfgById(autoChessData.CharacterId)

        if charaCfg then
            ---@type XTableAttribBase
            local attrCfg = XMVCA.XDlcWorld:GetAttributeConfigById(charaCfg.AttrId)

            if attrCfg then
                for k, v in pairs(attrCfg) do
                    local attribType = XDlcNpcAttribType[k]
                    if type(attribType) == 'number' and type(v) == 'number' then
                        if XMVCA.XTheatre5.EnumConst.EnlargedAttribs[attribType] then
                            autoChessData.Attribs[XDlcNpcAttribType[k]] = XMath.ToMinInt(v * DlcWorldAttribMultyBase)
                        else
                            autoChessData.Attribs[XDlcNpcAttribType[k]] = v
                        end
                    end
                end
            end
        end
    end

    -- 计算符文加成
    if not XTool.IsTableEmpty(autoChessData.RuneEvolves) then
        for i, runeEvolve in pairs(autoChessData.RuneEvolves) do
            local runeId = runeEvolve.RuneId

            ---@type XTableTheatre5ItemRune
            local runeCfg = self._Model:GetTheatre5RuneCfgById(runeId)

            if runeCfg and XTool.IsNumberValid(runeCfg.RuneAttrId) then
                ---@type XTableTheatre5ItemRuneAttr
                local runeAttrCfg
                if runeEvolve.IsStrengthen and XTool.IsNumberValid(runeCfg.EvolveAttrId) then
                    runeAttrCfg = self._Model:GetTheatre5ItemRuneAttrCfgById(runeCfg.EvolveAttrId)
                else
                    runeAttrCfg = self._Model:GetTheatre5ItemRuneAttrCfgById(runeCfg.RuneAttrId)
                end

                if runeAttrCfg then
                    for index, attr in ipairs(runeAttrCfg.AttrTypes) do
                        if XTool.IsNumberValid(runeAttrCfg.AttrValues[index]) then
                            autoChessData.Attribs[XDlcNpcAttribType[attr]] = autoChessData.Attribs[XDlcNpcAttribType[attr]] and (autoChessData.Attribs[XDlcNpcAttribType[attr]] + runeAttrCfg.AttrValues[index]) or runeAttrCfg.AttrValues[index]
                        end
                    end
                end
            end
        end
    end

    -- 等级属性
    local level = autoChessData.CharacterLevel
    if level then
        self._Model:GetCharacterLevelAttr(autoChessData.CharacterId, level, autoChessData.Attribs)
    end

    -- 玩家专属属性
    if isSelfData then
        -- v4.0新增Event带来的临时属性加成
        -- 基础属性，计算用
        local baseAttrs = {}
        -- 属性结算结果
        local resultAttrs = {}
        for k, v in pairs(autoChessData.Attribs) do
            baseAttrs[k] = v
            resultAttrs[k] = v
        end

        local adventureData = self._Model.CurAdventureData
        if adventureData then
            ---@type XTheatre5AddAttrResult[]
            local tempAttrList = adventureData:GetTempAttrList()
            if tempAttrList then
                for i = 1, #tempAttrList do
                    local tempAttr = tempAttrList[i]
                    local attrType = tempAttr.AttrType
                    local baseAttrValue = baseAttrs[attrType]
                    --属性改变=固定值+基础值*万分比+特定变量*比例 (基础值=角色基础属性+等级属性+符纹属性)
                    local changeValue = tempAttr.FixVal + baseAttrValue * tempAttr.RateVal / 10000 + tempAttr.SpecificVal * tempAttr.SpecificRateVal / 10000
                    --XLog.Error("通过饰品获得了属性:".. tostring(attrType) .. ":", changeValue)
                    resultAttrs[attrType] = math.floor(resultAttrs[attrType] + changeValue)
                end
            else
                XLog.Warning('XTheatre5BattleAgencyCom:GetXFightClientArgs() 临时属性列表为空')
            end

            -- 添加临时magicId
            local buffList = adventureData:GetTempBuffList()
            if buffList then
                local buffLevel = 1
                for i = 1, #buffList do
                    local buffId = buffList[i]
                    autoChessData.MagicIds[buffId] = buffLevel
                end
            else
                XLog.Warning('XTheatre5BattleAgencyCom:GetXFightClientArgs() 临时buff列表为空')
            end
        end

        for k, v in pairs(resultAttrs) do
            autoChessData.Attribs[k] = v
        end
    end
end

function XTheatre5BattleAgencyCom:_GetXFightClientArgs()
    local args = CS.StatusSyncFight.XFightClientArgs()

    args.CloseLoadingUiCb = function()
        self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FIGHT_ENTER_FINISHED)
    end

    args.SettleCb = function(result, summary)
        self:RequestTheatre5NormalSettle(result, summary)
    end

    args.InterruptFightCb = function(result, summary)
        self:RequestTheatre5NormalSettle(result, summary)
    end

    return args
end
--endregion

--- 用于控制台测试
function XTheatre5BattleAgencyCom:TestCalNpcAttribsAndBackXAutoChessData(autoChessData)
    self:_CalNpcAttribsAfterEnterFightRequest(autoChessData)

    local isDebug = true
    return self:_GetXAutoChessData(autoChessData, isDebug)
end

--- 用于结算检查是否活动结束
function XTheatre5BattleAgencyCom:_CheckPVPTimeEndInSettle(inBattle)
    if not (XMVCA.XTheatre5:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP) then
        return false
    end

    if not XMVCA.XTheatre5:CheckInPVPActivityTime() then
        CS.StatusSyncFight.XFightClient.RequestExitFight()
        XUiManager.TipText('ActivityMainLineEnd')
        return true
    end

    return false
end

return XTheatre5BattleAgencyCom