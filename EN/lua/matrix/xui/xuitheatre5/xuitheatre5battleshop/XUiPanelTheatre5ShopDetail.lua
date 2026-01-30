---@class XUiPanelTheatre5ShopDetail: XUiNode
---@field private _Control XTheatre5Control
local XUiPanelTheatre5ShopDetail = XClass(XUiNode, 'XUiPanelTheatre5ShopDetail')

function XUiPanelTheatre5ShopDetail:OnStart()
    self:RefreshShow()
    self.BtnClose.CallBack = handler(self, self.Close)
end

function XUiPanelTheatre5ShopDetail:OnEnable()
    self.BtnClose.gameObject:SetActiveEx(true)
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

function XUiPanelTheatre5ShopDetail:OnDisable()
    self.BtnClose.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre5ShopDetail:RefreshShow()
    ---@type XTableTheatre5Shop
    local shopCfg = self._Control.ShopControl:GetCurShopCfg()

    if shopCfg then
        for i = 1, 10 do
            local txtProb = self['TxtProbNum'..i]
            if txtProb then
                txtProb.text = XUiHelper.FormatText(self._Control.ShopControl:GetClientConfigShopItemProbShowLabel(), shopCfg.ProbShows[i] or 0)
            end
        end
    end
    
    ---@type XTableTheatre5PvpRoundRefresh
    local roundCfg = self._Control.ShopControl:GetCurRoundCfg()

    if roundCfg then
        self.TxtTips.text = roundCfg.ShopDetailTips
    end
    --pve隐藏
    self.TxtTips.gameObject:SetActiveEx(self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVE)
end

return XUiPanelTheatre5ShopDetail