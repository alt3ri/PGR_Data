local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiTheatre6PVPMain : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PVPMain = XLuaUiManager.Register(XLuaUi, "UiTheatre6PVPMain")

local XUiGridTheatre6PvpEnemy = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpEnemy")
local XUiPanelTheatre6PvpPlayerInfo = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpPlayerInfo")
local XUiPanelTheatre6PvpEnergy = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpEnergy")

function XUiTheatre6PVPMain:OnAwake()
    self:InitButtonEvents()
    self.GridEnemy.gameObject:SetActiveEx(false)
    self.PanelTitleChallenge.gameObject:SetActiveEx(false)
end

function XUiTheatre6PVPMain:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetPvpActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XTheatre6:HandlePvpActivityEnd()
        else
            if self._PanelPlayerInfo then
                self._PanelPlayerInfo:RefreshTips()
            end
        end
    end)

    ---@type XUiGridTheatre6PvpEnemy[]
    self._EnemyGrids = {}
    if not self._HasEnteredFunction then
        XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Theatre6Pvp)
        self._HasEnteredFunction = true
    end
    self._Control:RequestPvpGetBattleRecords()
end

function XUiTheatre6PVPMain:OnEnable()
    self._Control:TryPopupRankReward()
    self:Refresh()
end

function XUiTheatre6PVPMain:OnDisable()
    self:StopRefreshCdTimer()
end

function XUiTheatre6PVPMain:OnDestroy()
    if self._HasEnteredFunction then
        XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Theatre6Pvp)
        self._HasEnteredFunction = false
    end
end

--region 初始化
function XUiTheatre6PVPMain:InitButtonEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainClick))
    self.BtnRefresh:AddEventListener(handler(self, self.OnBtnRefreshClick), true, true, 1.5)
end
--endregion

--region 刷新
function XUiTheatre6PVPMain:Refresh()
    self:RefreshState()
    self:RefreshEnemyList()
    self:RefreshPlayerInfo()
    self:RefreshRefreshCd()
end

---根据是否进阶挑战切换显示
function XUiTheatre6PVPMain:RefreshState()
    local isChallenge = self._Control:IsPVPChallengeState()
    self.PanelTitleChallenge.gameObject:SetActiveEx(isChallenge)
    if isChallenge then
        --进阶挑战时不显示体力
        self:ClosePVPEnergyPanel()
        self.TxtTitle.text = self._Control:GetPvpClientConfigValue("PvpTitleChallenge")
        self.TxtDesc.text = self._Control:GetPvpClientConfigValue("PvpDescChallenge")
        self:RefreshRewardPanel()
    else
        self:RefreshEnergyPanel()
    end
end

function XUiTheatre6PVPMain:RefreshEnemyList()
    local enemies = self._Control:GetPvpSearchEnemies()
    local hasEnemy = not XTool.IsTableEmpty(enemies)
    self.ListEnemy.gameObject:SetActiveEx(hasEnemy)
    if hasEnemy then
        table.sort(enemies, function(a, b)
            return a.BattleData.Score > b.BattleData.Score
        end)
    end
    XTool.UpdateDynamicItem(self._EnemyGrids, enemies, self.GridEnemy, XUiGridTheatre6PvpEnemy, self)
end

function XUiTheatre6PVPMain:RefreshPlayerInfo()
    if not self._PanelPlayerInfo then
        ---@type XUiPanelTheatre6PvpPlayerInfo
        self._PanelPlayerInfo = XUiPanelTheatre6PvpPlayerInfo.New(self.PanelPlayerInfo, self)
    end
    self._PanelPlayerInfo:Open()
    self._PanelPlayerInfo:Refresh()
end

function XUiTheatre6PVPMain:RefreshEnergyPanel()
    if not self._PanelEnergy then
        ---@type XUiPanelTheatre6PvpEnergy
        self._PanelEnergy = XUiPanelTheatre6PvpEnergy.New(self.PanelPVPEnergy, self)
    end
    self._PanelEnergy:Open()
    self._PanelEnergy:Refresh()
end

function XUiTheatre6PVPMain:ClosePVPEnergyPanel()
    if self._PanelEnergy then
        self._PanelEnergy:Close()
    else
        self.PanelPVPEnergy.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre6PVPMain:RefreshRewardPanel()
    local rewardIds = self._Control:GetPvpRankRewardIds()
    local hasReward = not XTool.IsTableEmpty(rewardIds)
    self.PanelReward.gameObject:SetActiveEx(hasReward)
    if not hasReward then
        return
    end

    local rewardItems = {}
    for _, rewardId in ipairs(rewardIds) do
        local rewards = XRewardManager.GetRewardList(rewardId)
        if not XTool.IsTableEmpty(rewards) then
            for _, reward in ipairs(rewards) do
                rewardItems[#rewardItems + 1] = reward
            end
        end
    end
    rewardItems = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)

    ---@type XUiGridCommon[]
    self._RewardGrids = self._RewardGrids or {}
    local rewardsNum = #rewardItems
    for i = 1, rewardsNum do
        local grid = self._RewardGrids[i]
        if not grid then
            local go = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelReward)
            grid = XUiGridCommon.New(self, go)
            self._RewardGrids[i] = grid
        end
        grid:Refresh(rewardItems[i])
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiTheatre6PopupRewardDetail", rewardItems[i])
        end)
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self._RewardGrids do
        self._RewardGrids[i].GameObject:SetActiveEx(false)
    end
end
--endregion

--region 按钮事件
function XUiTheatre6PVPMain:OnBtnBackClick()
    self:Close()
end

function XUiTheatre6PVPMain:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre6PVPMain:OnBtnRefreshClick()
    self._Control:RequestPvpRefreshMatch(function()
        self:RefreshEnemyList()
        self:StartRefreshCd()
    end)
end
--endregion

--region 刷新冷却
function XUiTheatre6PVPMain:RefreshRefreshCd()
    local remainCd = self._Control:GetPvpRefreshMatchRemainCd()
    if remainCd > 0 then
        self:StartRefreshCd(remainCd)
    else
        self:ResetRefreshCd()
    end
end

function XUiTheatre6PVPMain:ResetRefreshCd()
    self:StopRefreshCdTimer()
    self.ImgMask.fillAmount = 0
    self.BtnRefresh:SetDisable(false)
end

function XUiTheatre6PVPMain:StartRefreshCd(remainCd)
    local refreshMatchCd = self._Control:GetPvpRefreshRemainSeconds()
    remainCd = remainCd or refreshMatchCd
    if remainCd <= 0 then
        return
    end
    self:StopRefreshCdTimer()
    self.BtnRefresh:SetDisable(true, false)
    local delayTime = remainCd * XScheduleManager.SECOND
    self._RefreshCdTimerId = XScheduleManager.ScheduleOnce(function()
        self._RefreshCdTimerId = nil
        if not XTool.UObjIsNil(self.GameObject) then
            self.BtnRefresh:SetDisable(false)
        end
    end, delayTime)
    self.ImgMask.fillAmount = refreshMatchCd > 0 and remainCd / refreshMatchCd or 1
    XUiHelper.TweenFillAmount(self, self.ImgMask, 0, remainCd)
end

function XUiTheatre6PVPMain:StopRefreshCdTimer()
    if self._RefreshCdTimerId then
        XScheduleManager.UnSchedule(self._RefreshCdTimerId)
        self._RefreshCdTimerId = nil
    end
end
--endregion

return XUiTheatre6PVPMain
