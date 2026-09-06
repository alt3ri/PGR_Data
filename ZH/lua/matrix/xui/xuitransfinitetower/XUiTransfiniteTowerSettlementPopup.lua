---@class XUiTransfiniteTowerSettlementPopup : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field TxtStageName UnityEngine.UI.Text
---@field Head UnityEngine.RectTransform
---@field TxtPlayerName UnityEngine.UI.Text
---@field TxtMembersNum UnityEngine.UI.Text
---@field TxtPowerNum UnityEngine.UI.Text
---@field TxtStageNum UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
local XUiTransfiniteTowerSettlementPopup = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerSettlementPopup")

function XUiTransfiniteTowerSettlementPopup:OnAwake()
    self:RegisterButtonEvent()
end

---@param towerCfgId number
function XUiTransfiniteTowerSettlementPopup:OnStart(towerCfgId)
    self._TowerCfgId = towerCfgId
end

function XUiTransfiniteTowerSettlementPopup:OnEnable()
    self:Refresh()
end

function XUiTransfiniteTowerSettlementPopup:RegisterButtonEvent()
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

--region 刷新

function XUiTransfiniteTowerSettlementPopup:Refresh()
    self:RefreshTitle()
    self:RefreshPlayer()
    self:RefreshStats()
end

function XUiTransfiniteTowerSettlementPopup:RefreshTitle()
    self.TxtStageName.text = self._Control:GetSettlePopupTitle(self._TowerCfgId)
end

function XUiTransfiniteTowerSettlementPopup:RefreshPlayer()
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TxtPlayerName.text = XPlayer.Name
end

function XUiTransfiniteTowerSettlementPopup:RefreshStats()
    local stats = self._Control:GetLastSettleStats(self._TowerCfgId)
    self.TxtMembersNum.text = stats.MemberCount or 0
    self.TxtPowerNum.text = stats.TotalPower or 0
    self.TxtStageNum.text = stats.ClearedStage or 0
end

--endregion

return XUiTransfiniteTowerSettlementPopup
