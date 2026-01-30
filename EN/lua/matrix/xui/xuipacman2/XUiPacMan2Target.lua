---@class XUiPacMan2Target : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2Target = XClass(XUiNode, "XUiPacMan2Target")

function XUiPacMan2Target:OnStart()
    self.Grid256New.gameObject:SetActiveEx(false)
end

---@param data XUiPacMan2TargetData
function XUiPacMan2Target:Update(data)
    -- 判断是否需要显示 PanelReceived：本次达到或历史上已达到的都显示
    local shouldShowReceived = data.IsOn or (data.IsHistoryOn == true)

    if data.IsOn then
        self.TxtTargetOn.text = XUiHelper.GetText("PacMan2StarTarget", data.Score)
        self.TargetOn.gameObject:SetActiveEx(true)
        self.TargetOff.gameObject:SetActiveEx(false)
    else
        self.TxtTargetOff.text = XUiHelper.GetText("PacMan2StarTarget", data.Score)
        self.TargetOn.gameObject:SetActiveEx(false)
        self.TargetOff.gameObject:SetActiveEx(true)
    end

    -- PanelReceived 显示：本次达到或历史上已达到（已领取过奖励）的都显示
    if self.PanelReceived then
        self.PanelReceived.gameObject:SetActiveEx(shouldShowReceived)
    end

    self._GridRewards = self._GridRewards or {}
    local rewardId = data.RewardId
    if rewardId and rewardId ~= 0 then
        local rewardGoodList = XRewardManager.GetRewardList(data.RewardId)
        XTool.UpdateDynamicGridCommon(self._GridRewards, rewardGoodList, self.Grid256New)
    else
        for i = 1, #self._GridRewards do
            self._GridRewards[i]:Close()
        end
    end
end

return XUiPacMan2Target
