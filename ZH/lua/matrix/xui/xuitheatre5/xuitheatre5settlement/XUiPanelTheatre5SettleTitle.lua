--- 最终结算的标题界面，不展示具体的角色信息
---@class XUiPanelTheatre5SettleTitle: XUiNode
---@field protected _Control XTheatre5Control
local XUiPanelTheatre5SettleTitle = XClass(XUiNode, 'XUiPanelTheatre5SettleTitle')

---@param resultData XDlcFightSettleData
function XUiPanelTheatre5SettleTitle:OnStart(resultData)
    self.ResultData = resultData

    self:RefreshShow()
end

function XUiPanelTheatre5SettleTitle:RefreshShow()
    local isWin
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        local cupsNum = self.ResultData.XAutoChessGameplayResult.TrophyNum
        local targetCount = self._Control.PVPControl:GetPVPTargetCountFromConfig()
        local isPvpExtra = self.ResultData.XAutoChessGameplayResult.IsPvpExtra
        if isPvpExtra then
            targetCount = self._Control.PVPControl:GetPvpExtraTargetCountFromConfig()
        end
        isWin = cupsNum >= targetCount
    else
        isWin = self.ResultData.ResultData.IsPlayerWin
    end
    -- 胜利情况
    self.TxtWin.gameObject:SetActiveEx(isWin)
    self.TxtEnd.gameObject:SetActiveEx(not isWin)
end

return XUiPanelTheatre5SettleTitle
