--- 分部类，主要是处理战斗相关重写接口
---@type XPBRGameAgency
local XPBRGameAgency = XClassPartial("XPBRGameAgency")

function XPBRGameAgency:FightPartialInit()
    
end

function XPBRGameAgency:FightPartialInitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self._OnFightSettle, self)
end

function XPBRGameAgency:FightPartialRelease()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self._OnFightSettle, self)
end

function XPBRGameAgency:FightPartialReset()
    
end

--region override

--- 请求进战斗协议前的数据构造
function XPBRGameAgency:PreFight(stage, teamId, isAssist, challengeCount)
    local preFight = {}
    preFight.StageId = stage.StageId
    preFight.CardIds = {
        self._Model:GetCurSelectCharId()
    }

    -- 进战斗前清理一下结算相关缓存
    self._Model:SetFightExitType(nil)

    return preFight
end

function XPBRGameAgency:OpenFightLoading(stageId)
    -- 如果是在战斗内重进战斗的不需要打开loading界面
    if XFightUtil.IsFighting() then
        -- do nothing
    else
        XMVCA.XFuben:OpenFightLoading(stageId)
    end
end

--- 检查是否自动退出战斗（参考 XTransfiniteManager.CheckAutoExitFight，对应 ProcessFunc.CheckAutoExitFight）
--- 进入战斗前作为回调初始化时执行一次
---@param stageId number 关卡ID
---@return boolean 是否自动退出
function XPBRGameAgency:CheckAutoExitFight(stageId)
    -- 不需要自动退出战斗
    return false
end

--- 最后调用战斗的进入战斗接口时调用
function XPBRGameAgency:CustomOnCallFight(fightData, args)
    if XFightUtil.IsFighting() then
        XMVCA.XFuben:ResetSettle()
        CS.XFight.Restart(fightData, args)
    else
        CS.XFight.Enter(fightData, args)
    end
end

--- 战斗结束结算前的处理，默认流程为请求结算协议
--- -> CallFinishFight
---@param result XFightResult
function XPBRGameAgency:SettleFight(result)
    result:GetFightResult()
    
    --- 如果是暂停界面退出的，走特殊逻辑
    local fightExitType = self._Model:GetFightExitType()

    if fightExitType == XMVCA.XPBRGame.EnumConst.FightExitType.Settle then
        -- 手动结算，即放弃当前波次, 需要业务对结算结果进行调整
        -- 若当前波次超出预定波次（即无限关模式），则胜利，否则失败
        local stageId = result.Data.StageId
        local wave = self._Model:GetWaveInSegmentSettleData()

        local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)

        if stageCfg then
            if stageCfg.StageType == XMVCA.XPBRGame.EnumConst.StageCustomType.Challenge and wave > stageCfg.FinishWaves then
                result.Data.IsWin = true
            else
                result.Data.IsWin = false
            end
        end

        result.Data.IsFightSegmentSettle = false

        -- 走原逻辑
        XMVCA.XFuben:SettleFight(result)
        return
    elseif fightExitType == XMVCA.XPBRGame.EnumConst.FightExitType.GiveUp then
        return
    end

    -- 如果是胜利，且是挑战关，当前波次到达预定波次，则标记为通关
    if result.Data.IsWin then
        local stageId = result.Data.StageId
        local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)
        if stageCfg and stageCfg.StageType == XMVCA.XPBRGame.EnumConst.StageCustomType.Challenge then
            local wave = self._Model:GetWaveInSegmentSettleData()
            if wave >= stageCfg.FinishWaves then

                if wave == stageCfg.FinishWaves then
                    -- 弹窗告知已经通关，且可开启无尽关
                    XLuaUiManager.Open('UiPBRPopupEndless', result)
                    return
                elseif wave < stageCfg.MaxWaves then
                    -- 已经是无尽关波次了，不需要再弹窗, 只需要修改为部分结算
                    result.Data.IsFightSegmentSettle = true
                end
            end
        end
    end

    -- 走原逻辑
    XMVCA.XFuben:SettleFight(result)
end

--- 战斗退出后调用，若强制退出则与SettleFight异步执行，否则等待SettleFight请求完成后调用
--- -> FinishFight
function XPBRGameAgency:CallFinishFight()
    local fightExitType = self._Model:GetFightExitType()
    
    local hasValidResult = XMVCA.XFuben:CheckValidSettleFight()

    if not hasValidResult or fightExitType == XMVCA.XPBRGame.EnumConst.FightExitType.GiveUp then
        -- 不请求结算，只退出
        XMVCA.XFuben:ResetSettle()

        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
        -- 恢复回系统音声设置 避免战斗里将BGM音量设置为0导致结算后没有声音
        XLuaAudioManager.ResetSystemAudioVolume()
        XLuaAudioManager.StopAudioByType(XLuaAudioManager.SoundType.SFX | XLuaAudioManager.SoundType.Voice | XLuaAudioManager.SoundType.Music)

        XLuaUiManager.CloseAllUpperUi('UiPBRMain')
    else
        -- 正常流程
        XMVCA.XFuben:CallFinishFight()
    end
end

function XPBRGameAgency:FinishFight(settleData)
    if not self:CheckAutoExitFight(settleData.StageId) then
        -- 如果不自动退出战斗，表示战斗结束后的相关界面处理有特殊需求，这里直接返回
        return
    end
    
    -- 弹出结算
    self:_ShowWinSettle(settleData)
end

function XPBRGameAgency:OnReconnectFailExit()
    --- 断线退出什么窗口都不打开
    return
end

--endregion

--- 退出战斗（参考 XTransfiniteManager.ExitFight）
function XPBRGameAgency:ExitFightByHand()
    CS.XFight.ExitForClient(true)
end

--- 检查强制退出（参考 XTransfiniteManager.CheckForceExit）
---@param isResult boolean 是否在结算界面
---@return boolean 是否已强制退出
function XPBRGameAgency:DoSafeFightExit()
    if XFightUtil.IsFighting() then
        self:ExitFightByHand()
        return true
    end
    
    return false
end

function XPBRGameAgency:_OnFightSettle(settleData, res)
    if not res then
        return
    end
    
    if res.Code ~= XCode.Success then
        -- 校验失败默认游戏失败
        if settleData then
            settleData.IsWin = false
        end
    end
    
    self:_ShowWinSettle(settleData)
end

function XPBRGameAgency:_ShowWinSettle(settleData)
    if not settleData then
        self:DoSafeFightExit()
        return
    end
    
    local stageId = settleData.StageId
    local stageType = XDataCenter.FubenManager.GetStageType(stageId)

    if stageType ~= XEnumConst.FuBen.StageType.PBRGame then
        return
    end
    
    ---@type PbrFightSettleShowData
    local pbrSettleData = settleData.PbrFightSettleShowData

    if pbrSettleData then
        if pbrSettleData.IsFightSegmentSettle then
            -- 商店数据在结算界面里，需要存一下
            local SegmentSettleData = pbrSettleData.SegmentSettleData

            self._Model:UpdateFullSegmentSettleData(SegmentSettleData)

            XLuaUiManager.Open('UiPBRShopNew', stageId)
        else
            -- 清空商店弹窗屏蔽缓存
            self._Model:SetShopSelectGiveupIgnorePopup(nil)
            -- 通关数据本地缓存
            self._Model:UpdateStageRecordByStageId(stageId, pbrSettleData.FinalSettleShowData.PbrStageRecord)
            -- 记录通关角色
            if settleData.IsWin and XTool.IsNumberValidEx(pbrSettleData.FinalSettleShowData.CharacterId) then
                self._Model:SetLastPassStageCharId(pbrSettleData.FinalSettleShowData.CharacterId)
            end

            self:DoSafeFightExit()

            XLuaUiManager.Open('UiPBRSettlement', stageId, pbrSettleData.FinalSettleShowData, settleData.IsWin)
        end

        if not XTool.IsTableEmpty(settleData.RewardGoodsList) then
            XUiManager.OpenUiTipReward(settleData.RewardGoodsList)
        end
    end
end

--region CsCallLua特供

--- 获取当前偏移值（ms）
function XPBRGameAgency:GetBgmBeatOffsetMs()
    return self._Model:GetBeatOffset()
end

function XPBRGameAgency:GetBgmIdByStageId(stageId)
    -- 先读缓存
    local bgmId = self._Model:GetSelectedBgmId(stageId)

    if XTool.IsNumberValidEx(bgmId) then
        return bgmId
    end
    
    -- 再读配置
    local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)

    if stageCfg then
        return stageCfg.BgmIds and stageCfg.BgmIds[1] or 0
    end
    
    return 0
end

function XPBRGameAgency:GetConfigPBRNumber(key)
    return self._Model:GetConfigPBRNumber(key)
end

function XPBRGameAgency:GetClientPBRText(key)
    return self._Model:GetClientPBRText(key)
end
--endregion