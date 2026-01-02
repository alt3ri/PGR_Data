
---@class XUiGridBWBranchResult : XUiNode
---@field _Control XBigWorldQuestControl
---@field Parent XUiBigWorldTaskMainInvitation
local XUiGridBWBranchResult = XClass(XUiNode, "XUiGridBWBranchResult")

function XUiGridBWBranchResult:OnStart()
    self._GridCommon = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem").New(self.UiBigWorldItemGrid, self)
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridBWBranchResult:Refresh(questId, resultId, index)
    self._QuestId = questId
    self._ResultId = resultId
    self._Index = index
    local isFinish = XMVCA.XBigWorldQuest:CheckInviteResultFinish(resultId)
    self._IsFinish = isFinish
    self.BtnClick.gameObject:SetActiveEx(isFinish)
    self.TxtName.gameObject:SetActiveEx(isFinish)
    self.RImgEnding.gameObject:SetActiveEx(isFinish)
    self.PanelLock.gameObject:SetActiveEx(not isFinish)
    if not isFinish then
        self:RefreshReward(self._Control:GetInviteQuestResultRewardId(resultId))
    else
        self._GridCommon:Close()
        self.TxtName.text = self._Control:GetInviteQuestResultName(resultId)
        self.RImgEnding:SetRawImage(self._Control:GetInviteQuestResultBanner(resultId))
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
        else
            self._GridCommon:Close()
        end
    else
        self._GridCommon:Close()
    end
end

return XUiGridBWBranchResult