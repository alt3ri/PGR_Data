--- 回合结算
---@class XUiTheatre5RoundSettlement: XLuaUi
---@field private _Control XTheatre5Control
---@field BtnEnd XUiComponent.XUiButton
local XUiTheatre5RoundSettlement = XLuaUiManager.Register(XLuaUi, 'UiTheatre5RoundSettlement')
local XUiPanelTheatre5SettleTopInfo = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiPanelTheatre5SettleTopInfo')
local XUiPanelTheatre5SettleSummary = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiPanelTheatre5SettleSummary')
local XUiPanelTheatre5MissionMiniDetail = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiPanelTheatre5MissionMiniDetail')
local XUiGridTheatre5Relic = require("XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Relic")

function XUiTheatre5RoundSettlement:OnAwake()
    self._RelicGrids = {}
    self.BtnShop:AddEventListener(handler(self, self.OnBtnShopClickEvent))
    self.BtnEnd:AddEventListener(handler(self, self.OnBtnEndClickEvent))
    self.BtnOvertime:AddEventListener(handler(self, self.OnBtnOvertimeClickEvent))
end

---@param resultData XDlcFightSettleData
function XUiTheatre5RoundSettlement:OnStart(resultData, summaryData)

    XMVCA.XTheatre5:SaveData({
        ResultData = resultData,
        SummaryData = summaryData
    })

    self.SummaryData = summaryData
    self.ResultData = resultData
    ---@type XUiPanelTheatre5SettleTopInfo
    self.PanelTop = XUiPanelTheatre5SettleTopInfo.New(self.PanelTop, self)
    self.PanelTop:ShowBattleResult(self.ResultData.ResultData.IsPlayerWin)
    self.PanelTop:RefreshAll()

    self:RefreshBtn(resultData.XAutoChessGameplayResult)

    ---@type XUiPanelTheatre5SettleSummary
    self.PanelSummary = XUiPanelTheatre5SettleSummary.New(self.PanelLeft, self, resultData, self.SummaryData)
    self.PanelSummary:RefreshAllShow()

    if self.UiTheatre5GridTaskDetail then
        self.UiTheatre5GridTaskDetail.gameObject:SetActiveEx(false)
        ---@type XUiPanelTheatre5MissionMiniDetail
        self.TaskDetail = XUiPanelTheatre5MissionMiniDetail.New(self.UiTheatre5GridTaskDetail, self)
    end

    if self.BtnReward then
        self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClickEvent))
    end

    self:UpdateCharacterLevel()
end

--region 事件回调

function XUiTheatre5RoundSettlement:OnBtnShopClickEvent()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        if self:CheckBeforeEnterShop() then
            XMVCA.XTheatre5:RequestTheatre5EnterShop(function(success)
                if success then
                    CsXUiManager.Instance:SetRevertAndReleaseLock(true)
                    XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
                        CS.StatusSyncFight.XFightClient.RequestExitFight()
                        XLuaUiManager.OpenWithCallback('UiTheatre5BattleShop', function()
                            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
                        end)
                    end)
                else
                    self:CheckBeforeEnterShop()
                end
            end)
        end
    else
        CsXUiManager.Instance:SetRevertAndReleaseLock(true)
        XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
            CS.StatusSyncFight.XFightClient.RequestExitFight()
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_BATTLE_RESULT_EXIT, self.ResultData)
        end)
    end
end

function XUiTheatre5RoundSettlement:OnBtnEndClickEvent()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        -- 检查pvp是否能正常结算
        if not self:CheckBeforeEnterSettlement() then
            return
        end
        -- 检查是否有额外选择
        ---@type XAutoChessGameplayResult
        local autoChessResult = self.ResultData.XAutoChessGameplayResult
        if not autoChessResult.IsFinish and autoChessResult.IsPvpExtraChoice then
            XMVCA.XTheatre5.BattleCom:RequestTheatre5SettleExtraChoice(false, function(success, res)
                if success then
                    self.ResultData.RewardGoodsList = res.RewardGoodsList
                    self.ResultData.XAutoChessGameplayResult = res.SettleResult
                    self:_OpenSettlement()
                end
            end)
            return
        end
    end

    self:_OpenSettlement()
end

function XUiTheatre5RoundSettlement:_OpenSettlement()
    CsXUiManager.Instance:SetRevertAndReleaseLock(true)
    XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
        CS.StatusSyncFight.XFightClient.RequestExitFight()
        XLuaUiManager.OpenWithCallback('UiTheatre5Settlement', function()
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
        end, self.ResultData)
    end)
end

function XUiTheatre5RoundSettlement:OnBtnOvertimeClickEvent()
    ---@type XAutoChessGameplayResult
    local autoChessResult = self.ResultData.XAutoChessGameplayResult
    if not autoChessResult.IsPvpExtraChoice then
        return
    end

    self._Control.PVPControl:ShowPvpExtraSecondConfirm(function()
        self:OnBtnEndClickEvent()
    end, function()
        XMVCA.XTheatre5.BattleCom:RequestTheatre5SettleExtraChoice(true, function(success)
            if success then
                self:OnBtnShopClickEvent()
            end
        end)
    end)
end

function XUiTheatre5RoundSettlement:OnBtnRewardClickEvent()
    if XTool.IsNumberValidEx(self.MissionRelicId) then
        if self.TaskDetail then
            if self.TaskDetail:IsNodeShow() then
                self.TaskDetail:CloseWithAnimation()
            else
                self.TaskDetail:Open()

                local isMaxLevel = false

                if XTool.IsNumberValidEx(self.MissionId) then
                    local bountyId = self._Control.MissionControl:GetTheatre5MissionBountyId(self.MissionId)

                    if XTool.IsNumberValidEx(bountyId) then
                        isMaxLevel = self._Control.MissionControl:CheckMissionIsMaxLevel(bountyId, self.MissionLevel)
                    end
                end

                self.TaskDetail:RefreshDetail(self.MissionRelicId, self.MissionLevel, isMaxLevel)
            end
        end
    end
end
--endregion

--region 任务饰品展示

function XUiTheatre5RoundSettlement:UpdateRelics(data, isSelf)
    if self.RelicContainer then
        -- pve模式不显示敌人饰品
        local showRelicContainer = self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVE or isSelf
        self.RelicContainer.transform.parent.parent.gameObject:SetActiveEx(showRelicContainer)

        -- 显示自己拥有的饰品/敌人的饰品
        local relics = self._Control:GetUiDataRelicsByData(data.AutoChessData.Relics)
        XTool.UpdateDynamicItem(self._RelicGrids, relics, self.RelicContainer, XUiGridTheatre5Relic, self)

        -- pve没有任务
        if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
            self.BtnReward.gameObject:SetActiveEx(false)
            return
        end

        --4.2 按照任务奖励的形式显示饰品
        local missionRelicId = 0
        local missionLevel = 0
        local missionId = 0

        if isSelf then
            missionId, missionLevel, missionRelicId = self:_GetSelfMissionIdAndRelicId()
        else
            missionId, missionLevel, missionRelicId = self:_GetEnemyMissionIdAndRelicId()
        end

        if self.BtnReward then
            if XTool.IsNumberValidEx(missionRelicId) and XTool.IsNumberValidEx(missionId) then
                self.BtnReward:SetButtonState(CS.UiButtonState.Normal)
                -- itemId = 6 * 10000 + bounty * 10 + level
                local bounty = self._Control.MissionControl:GetTheatre5MissionBountyId(missionId)
                local itemCfg = self._Control:GetTheatre5ItemCfgById(missionRelicId)

                if itemCfg then
                    self.BtnReward:SetRawImage(itemCfg.IconRes)

                    local levelLabel = XUiHelper.FormatText(self._Control.MissionControl:GetMissionGridLevelShow(bounty, missionLevel))
                    self.BtnReward:SetNameByGroup(0, levelLabel)
                    self.BtnReward:SetNameByGroup(1, itemCfg.Name)
                end
            else
                self.BtnReward:SetButtonState(CS.UiButtonState.Disable)

                local desc = self._Control.MissionControl:GetClientConfigMissionStateLabelInRoundSettle(XTool.IsNumberValidEx(missionId))

                self.BtnReward:SetNameByGroup(2, desc)
            end
        end

        self.MissionRelicId = missionRelicId
        self.MissionLevel = missionLevel
        self.MissionId = missionId
    end
end

function XUiTheatre5RoundSettlement:_GetSelfMissionIdAndRelicId()
    local missionRelicId = 0
    local missionLevel = 0
    local missionId = 0

    missionRelicId = self._Control.MissionControl:CheckMissionIsGotReward() and self._Control.MissionControl:GetCurMissionItemId() or 0

    local mission = self._Control.MissionControl:GetCurMission()

    if mission then
        missionId = mission.MissionId
        missionLevel = mission.MissionBounty.BountyLevel
    end

    return missionId, missionLevel, missionRelicId
end

function XUiTheatre5RoundSettlement:_GetEnemyMissionIdAndRelicId()
    return self._Control.MissionControl:GetMatchEnemyMissionData()
end

--endregion

---@param autoChessResult XAutoChessGameplayResult
function XUiTheatre5RoundSettlement:RefreshBtn(autoChessResult)
    self.BtnEnd:ShowTag(false)
    self.BtnOvertime:ShowTag(false)

    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        local isFinish = autoChessResult.IsFinish
        local hasExtraChoice = not isFinish and autoChessResult.IsPvpExtraChoice

        self.BtnShop.gameObject:SetActiveEx(not isFinish and not hasExtraChoice)
        self.BtnEnd.gameObject:SetActiveEx(isFinish or hasExtraChoice)
        self.BtnOvertime.gameObject:SetActiveEx(hasExtraChoice)

        if hasExtraChoice then
            self:RefreshBtnEndTab(autoChessResult.NormalOriginRating)
            self:RefreshBtnOvertimeTag(autoChessResult.NormalOriginRating)
        end
    else
        self.BtnShop.gameObject:SetActiveEx(not autoChessResult.IsFinish)
        self.BtnEnd.gameObject:SetActiveEx(autoChessResult.IsFinish)
        self.BtnOvertime.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre5RoundSettlement:RefreshBtnEndTab(normalOriginRating)
    local originRating = normalOriginRating or 0
    local tagText = self._Control.PVPControl:GetPvpRoundEndTips()
    self.BtnEnd:SetNameByGroup(1, XUiHelper.FormatTextEx(tagText, originRating))
    self.BtnEnd:ShowTag(true)
end

function XUiTheatre5RoundSettlement:RefreshBtnOvertimeTag(normalOriginRating)
    local originRating = normalOriginRating or 0
    local tagText = self._Control.PVPControl:GetPvpExtraRoundTips()
    local minRating, maxRating = self._Control.PVPControl:GetPvpExMinAndMaxRating()
    self.BtnOvertime:SetNameByGroup(1, XUiHelper.FormatTextEx(tagText, originRating + minRating, originRating + maxRating))
    self.BtnOvertime:ShowTag(true)
end

function XUiTheatre5RoundSettlement:UpdateCharacterLevel()
    if self.Role then
        local charactrerLevel = self._Control.CharacterControl:GetCharacterLevel()
        self.TxtNum.text = charactrerLevel
        local icon = self._Control:GetCharacterIcon()
        self.Role:SetRawImage(icon)
    end
end

--- 进入商店前检查是否ok
function XUiTheatre5RoundSettlement:CheckBeforeEnterShop()
    if not self._Control.PVPControl:CheckPVPInTime() then
        XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
            CS.StatusSyncFight.XFightClient.RequestExitFight()
            XScheduleManager.ScheduleNextFrame(function()
                XLuaUiManager.CloseAllUpperUiWithCallback('UiTheatre5Main')
                XUiManager.TipText('ActivityMainLineEnd')
            end)
        end)

        return false
    end

    return true
end

function XUiTheatre5RoundSettlement:CheckBeforeEnterSettlement()
    -- 进入最终结算的判断和进入商店暂时没区别，直接调用
    return self:CheckBeforeEnterShop()
end

return XUiTheatre5RoundSettlement
