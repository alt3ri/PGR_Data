local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelTransfiniteTowerRank = require("XUi/XUiTransfiniteTower/Panel/XUiPanelTransfiniteTowerRank")

---@class XUiTransfiniteTowerRank : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field BtnTimeInfo XUiComponent.XUiButton
---@field PanelBubbleTip UnityEngine.GameObject
---@field BtnDetailClose XUiComponent.XUiButton
---@field TxtDesc UnityEngine.UI.Text
local XUiTransfiniteTowerRank = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerRank")

function XUiTransfiniteTowerRank:OnAwake()
    self:_InitTopControl()
    self:_InitRewardGrid()
    self:_InitPanelRank()
    self:RegisterButtonEvent()
    local endTime = self._Control:GetTowerUnlockEndTime(self._Control:GetRankChapterId())
    if endTime > 0 then
        self:SetAutoCloseInfo(endTime, handler(self, self.OnTowerClosed))
    end
end

function XUiTransfiniteTowerRank:OnTowerClosed(isClose)
    if not isClose then
        return
    end
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerTowerClosed"))
    self:Close()
end

function XUiTransfiniteTowerRank:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_TOWER_RANK_UPDATE, self.OnRankUpdate, self)
    self:RenderRankCache()
    self._Control:RefreshRankCache()
    self:StartRemainTimeTimer()
end

function XUiTransfiniteTowerRank:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_TOWER_RANK_UPDATE, self.OnRankUpdate, self)
    self:StopRemainTimeTimer()
end

function XUiTransfiniteTowerRank:OnDestroy()
    self:StopRemainTimeTimer()
end

--region 初始化

function XUiTransfiniteTowerRank:_InitTopControl()
    self._TopControl = XUiHelper.NewPanelTopControl(self, self.TopControl)
end

function XUiTransfiniteTowerRank:_InitRewardGrid()
    self._RewardGrid = XUiGridCommon.New(self, self.Grid256New)
end

function XUiTransfiniteTowerRank:_InitPanelRank()
    self._PanelRank = XUiPanelTransfiniteTowerRank.New(self.PanelSelfRank, self)
end

function XUiTransfiniteTowerRank:RegisterButtonEvent()
    self.BtnTimeInfo:AddEventListener(handler(self, self.OnBtnTimeInfoClick))
    self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnDetailCloseClick))
    self.PanelBubbleTip.gameObject:SetActiveEx(false)
end

--endregion

--region 气泡

function XUiTransfiniteTowerRank:OnBtnTimeInfoClick()
    local spendTime = self._LastRankTotalSpendTime or 0
    if spendTime > 0 then
        self.TxtDesc.text = XUiHelper.GetText("TransfiniteTowerRankTime",
            XUiHelper.GetTime(spendTime, XUiHelper.TimeFormatType.MINUTE_SECOND))
    else
        self.TxtDesc.text = XUiHelper.GetText("TransfiniteTowerRankNoTime")
    end
    self.PanelBubbleTip.gameObject:SetActiveEx(true)
end

function XUiTransfiniteTowerRank:OnBtnDetailCloseClick()
    self.PanelBubbleTip.gameObject:SetActiveEx(false)
end

--endregion

--region 刷新

function XUiTransfiniteTowerRank:OnRankUpdate()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:RenderRankCache()
end

function XUiTransfiniteTowerRank:RenderRankCache()
    local data = self._Control:GetRankCacheData()
    if not data then
        return
    end
    self._LastRankTotalSpendTime = data.lastRankTotalSpendTime or 0
    self:RefreshReward(data.reward)
    self._PanelRank:Refresh(data.rankList, data.myRankData)
    self:UpdateRemainTime()
end

function XUiTransfiniteTowerRank:RefreshReward(rewardData)
    local hasReward = rewardData ~= nil
    self.Grid256New.gameObject:SetActiveEx(hasReward)
    if hasReward then
        self._RewardGrid:Refresh(rewardData)
    end
end

function XUiTransfiniteTowerRank:StartRemainTimeTimer()
    self:StopRemainTimeTimer()
    self._RemainTimeTimer = XScheduleManager.ScheduleForever(handler(self, self.UpdateRemainTime), XScheduleManager.SECOND)
end

function XUiTransfiniteTowerRank:StopRemainTimeTimer()
    if self._RemainTimeTimer then
        XScheduleManager.UnSchedule(self._RemainTimeTimer)
        self._RemainTimeTimer = nil
    end
end

function XUiTransfiniteTowerRank:UpdateRemainTime()
    local remainTime = self._Control:GetRankRemainTime()
    if remainTime <= 0 then
        self.TxtTime.text = ""
        self:StopRemainTimeTimer()
        return
    end
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end

--endregion

return XUiTransfiniteTowerRank
