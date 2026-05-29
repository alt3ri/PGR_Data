---@class XUiGridBWBranchResult : XUiNode
---@field _GridCommon XUiGridBWItem
local XUiGridBWBranchResult = XClass(XUiNode, "XUiGridBWBranchResult")

function XUiGridBWBranchResult:OnStart()
    self._GridCommon = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem").New(self.UiBigWorldItemGrid, self)
    --self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
    self.BtnClick.gameObject:SetActiveEx(false)
    self.Big = self.Big or self.Transform:Find("Animation/Big")
    self.Small = self.Small or self.Transform:Find("Animation/Small")
    self.BigHold = self.BigHold or self.Transform:Find("Animation/BigHold")
    self.SmallHold = self.SmallHold or self.Transform:Find("Animation/SmallHold")
end

function XUiGridBWBranchResult:OnDisable()
    self:StopExpandTimer()
    self:StopCollapseTimer()
end

function XUiGridBWBranchResult:Refresh(data)
    if not data then
        return
    end

    self._QuestId = data.QuestId
    self._ResultId = data.ResultId
    self._IsFinish = XMVCA.XBigWorldQuest:CheckInviteResultFinish(self._ResultId)

    local resultIds = self._Control:GetInviteQuestResultIds(self._QuestId)
    self.Panel.gameObject:SetActiveEx(XTool.IsTableEmpty(resultIds) or #resultIds <= 1)

    --self.BtnClick.gameObject:SetActiveEx(self._IsFinish)
    self.TxtName.gameObject:SetActiveEx(self._IsFinish)
    self.RImgEnding.gameObject:SetActiveEx(self._IsFinish)
    self.RImgEnding2.gameObject:SetActiveEx(self._IsFinish)
    self.PanelLock.gameObject:SetActiveEx(not self._IsFinish)
    self.Locked.gameObject:SetActiveEx(not self._IsFinish)
    self.Receive.gameObject:SetActiveEx(XMVCA.XBigWorldQuest:CheckInviteResultFinish(self._ResultId))

    local rewardId = self._Control:GetInviteQuestResultRewardId(self._ResultId)
    local name = self._Control:GetInviteQuestResultName(self._ResultId)
    local banner = self._Control:GetInviteQuestResultBanner(self._ResultId)

    self:RefreshReward(rewardId)

    if self._IsFinish then
        self.TxtName.text = name
        self.RImgEnding:SetRawImage(banner)
        self.RImgEnding2:SetRawImage(banner)
    end
end

function XUiGridBWBranchResult:OnBtnClick()
    if not self._IsFinish then
        return
    end
    XMVCA.XBigWorldQuest:OpenInvitationDetail(self._QuestId, self._ResultId)
end

function XUiGridBWBranchResult:RefreshReward(rewardId)
    if rewardId and rewardId > 0 then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if not XTool.IsTableEmpty(rewardList) then
            self._GridCommon:Update(rewardList[1])
            self._GridCommon:RefreshReceive(XMVCA.XBigWorldQuest:CheckInviteResultFinish(self._ResultId))
        else
            self._GridCommon:Close()
        end
    else
        self._GridCommon:Close()
    end
end

-- 播放展开动画
function XUiGridBWBranchResult:PlayExpandAnim(isAnim)
    self:StopExpandTimer()
    if isAnim then
        self.ExpandTimer = XScheduleManager.ScheduleOnce(function()
            self.Small:StopTimelineAnimation(true, false)
            self:Expand(isAnim)
            self.Big:PlayTimelineAnimation()
            self.ExpandTimer = nil
        end, 1)
    else
        if self.SmallHold then
            self.SmallHold:StopTimelineAnimation(true, false)
        end
        self.Big:StopTimelineAnimation(true, false)
        self.Small:StopTimelineAnimation(true, false)
        if self.BigHold then
            self.BigHold:PlayTimelineAnimation()
        end
        self:Expand(isAnim)
    end
end

-- 播放收起动画
function XUiGridBWBranchResult:PlayCollapseAnim(isAnim)
    self:StopCollapseTimer()
    if isAnim then
        self.CollapseTimer = XScheduleManager.ScheduleOnce(function()
            self.Big:StopTimelineAnimation(true, false)
            self.Small:PlayTimelineAnimation(function() 
                self:Collapse(isAnim)
                self.CollapseTimer = nil
            end)
        end, 1)
    else
        if self.BigHold then
            self.BigHold:StopTimelineAnimation(true, false)
        end
        self.Big:StopTimelineAnimation(true, false)
        self.Small:StopTimelineAnimation(true, false)
        if self.SmallHold then
            self.SmallHold:PlayTimelineAnimation()
        end
        self:Collapse(isAnim)
    end
end

function XUiGridBWBranchResult:Expand(isAnim)
    if not isAnim then --不播放动画时，代码控制显隐
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.Selected.gameObject:SetActiveEx(false)
    end
    
    self.PanelReward.gameObject:SetActiveEx(true)
    self.PanelLock.gameObject:SetActiveEx(not self._IsFinish)
    
    self._GridCommon:Open()
end

function XUiGridBWBranchResult:Collapse(isAnim)
    if not isAnim then --不播放动画时，代码控制显隐
        self.Selected.gameObject:SetActiveEx(true)
        self.PanelNormal.gameObject:SetActiveEx(false)
    end 
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
    self._GridCommon:Close()
end

function XUiGridBWBranchResult:StopExpandTimer()
    if not self.ExpandTimer then
        return
    end
    XScheduleManager.UnSchedule(self.ExpandTimer)
    self.ExpandTimer = nil
end

function XUiGridBWBranchResult:StopCollapseTimer()
    if not self.CollapseTimer then
        return
    end
    XScheduleManager.UnSchedule(self.CollapseTimer)
    self.CollapseTimer = nil
end

return XUiGridBWBranchResult