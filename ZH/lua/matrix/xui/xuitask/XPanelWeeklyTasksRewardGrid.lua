---@class XPanelWeeklyTasksRewardGrid : XUiNode

local XPanelWeeklyTasksRewardGrid =
    XClass(XUiNode, "XPanelWeeklyTasksRewardGrid")

function XPanelWeeklyTasksRewardGrid:OnStart()
    self.BtnActive.CallBack = function() self:OnBtnActiveClick() end
end

XPanelWeeklyTasksRewardGrid.ButtonStates = {
    Inactive = 0,   -- 尚不能领取
    Active = 1,     -- 等待领取
    Got = 2,        -- 已领取
}

function XPanelWeeklyTasksRewardGrid:SetData(args)
    local targetActiveness = args.TargetActiveness
    local orgPos = self.Transform.anchoredPosition3D

    self.Transform.anchoredPosition3D = CS.UnityEngine.Vector3(
        args.PositionX, orgPos.y, orgPos.z)

    self.targetActiveness = targetActiveness
    self.rewardId = args.RewardId
    self.GetReward = args.OnGetReward
    self.TxtValue.text = tostring(targetActiveness)

    if XDataCenter.TaskManager.WeeklyActivenessProgressRewardGot(targetActiveness) then
        self:SetButtonState(
            XPanelWeeklyTasksRewardGrid.ButtonStates.Got)
    elseif args.Activeness >= targetActiveness then
        self:SetButtonState(
            XPanelWeeklyTasksRewardGrid.ButtonStates.Active)
    else
        self:SetButtonState(
            XPanelWeeklyTasksRewardGrid.ButtonStates.Inactive)
    end
end

function XPanelWeeklyTasksRewardGrid:SetButtonState(state)
    self.ButtonState = state

    if state == XPanelWeeklyTasksRewardGrid.ButtonStates.Inactive then
        self.PanelEffect.gameObject:SetActive(false)
        self.ImgRe.gameObject:SetActive(false)
    elseif state == XPanelWeeklyTasksRewardGrid.ButtonStates.Active then
        self.PanelEffect.gameObject:SetActive(true)
        self.ImgRe.gameObject:SetActive(false)
    elseif state == XPanelWeeklyTasksRewardGrid.ButtonStates.Got then
        self.PanelEffect.gameObject:SetActive(false)
        self.ImgRe.gameObject:SetActive(true)
    else
        XLog.Error("XPanelTasksFinishedCountArrivedGrid:SetButtonState: " ..
            "invalid state: " .. tostring(state))
    end
end

function XPanelWeeklyTasksRewardGrid:OnBtnActiveClick()
    if self.ButtonState ~= XPanelWeeklyTasksRewardGrid.ButtonStates.Active then
        local rewardList = XRewardManager.GetRewardList(self.rewardId)
        XUiManager.OpenUiTipReward(
            rewardList,
            CS.XTextManager.GetText("WeeklyActiveRewardTitle"))
    else
        self.GetReward()
    end
end

return XPanelWeeklyTasksRewardGrid
