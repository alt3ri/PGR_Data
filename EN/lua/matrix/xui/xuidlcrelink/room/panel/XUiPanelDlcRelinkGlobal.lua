---@class XUiPanelDlcRelinkGlobal : XUiNode
---@field private _Control XDlcRelinkControl
local XUiPanelDlcRelinkGlobal = XClass(XUiNode, "XUiPanelDlcRelinkGlobal")

function XUiPanelDlcRelinkGlobal:OnStart()
    self.BtnGou:AddEventListener(handler(self, self.OnBtnGouClick))
    self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))
end

function XUiPanelDlcRelinkGlobal:Refresh()
    self:RefreshBtnGou()
    local matchRewardTimes = self._Control:GetGlobalMatchRewardTimes()
    local totalRewardTimes = self._Control:GetTotalGlobalMatchRewardTimes()
    local canGetReward = matchRewardTimes < totalRewardTimes
    self.TxtReward.text = string.format(self._Control:GetClientConfig("GlobalMatchRewardDesc", canGetReward and 1 or 2), matchRewardTimes, totalRewardTimes)
end

function XUiPanelDlcRelinkGlobal:RefreshBtnGou()
    local isEnabled = self._Control:IsGlobalMatchEnabled()
    self.BtnGou:SetButtonState(isEnabled and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.ImgBlackMask.gameObject:SetActiveEx(not isEnabled)
end

function XUiPanelDlcRelinkGlobal:OnBtnGouClick()
    if XMVCA.XDlcRoom:IsMatching() then
        self:RefreshBtnGou()
        self._Control:OpenCommonTipCode(XCode.MatchPlayerIsMatching)
        return
    end
    local isEnabled = self._Control:IsGlobalMatchEnabled()
    self._Control:RequestSwitchGlobalMatchFlag(not isEnabled, function()
        self:RefreshBtnGou()
    end)
end

function XUiPanelDlcRelinkGlobal:OnBtnDetailClick()
    local title = self._Control:GetClientConfig("TipTitle")
    local content = self._Control:GetClientConfig("GlobalMatchDetailTipContent")
    content = XUiHelper.ConvertLineBreakSymbol(content)
    self._Control:OpenCommonTipDialog(title, content)
end

return XUiPanelDlcRelinkGlobal
