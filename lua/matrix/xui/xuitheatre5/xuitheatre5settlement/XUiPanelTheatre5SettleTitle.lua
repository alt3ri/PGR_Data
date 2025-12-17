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
        local targetCnt = self._Control.PVPControl:GetPVPTargetCountFromConfig()
        isWin = self.ResultData.XAutoChessGameplayResult.TrophyNum >= targetCnt
    else
        isWin = self.ResultData.ResultData.IsPlayerWin
    end    
    -- 胜利情况
    self.TxtWin.gameObject:SetActiveEx(isWin)
    self.TxtEnd.gameObject:SetActiveEx(not isWin)
end

return XUiPanelTheatre5SettleTitle