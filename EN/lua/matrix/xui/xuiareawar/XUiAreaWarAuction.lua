---@class XUiAreaWarAuction : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarAuction = XLuaUiManager.Register(XLuaUi, "UiAreaWarAuction")

function XUiAreaWarAuction:OnAwake()
    -- 页签类型
    self.TAB_TYPE = {
        BUY = 1,
        SELL = 2,
    }
    
    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe({XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin}, self.PanelSpecialTool, self)
    self:RegisterUiEvents()
end

function XUiAreaWarAuction:OnStart(skipBuyItemId)
    self._SkipBuyItemId = skipBuyItemId -- 跳转购买的ItemId
    self.PanelTabGroup:SelectIndex(self.TAB_TYPE.BUY)
end

function XUiAreaWarAuction:OnEnable()
    self:Refresh()
end

function XUiAreaWarAuction:OnDisable()

end

function XUiAreaWarAuction:OnDestroy()
    
end

function XUiAreaWarAuction:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)

    self.TabButtons = { self.GridTabBuy, self.GridTabSell }
    self.PanelTabGroup:Init(self.TabButtons,function(index) self:OnSelectTab(index) end)
end

function XUiAreaWarAuction:OnBtnBackClick()
    self:Close()
end

function XUiAreaWarAuction:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAreaWarAuction:OnSelectTab(index)
    if self.TabIndex == index then return end
    if self.TabIndex then
        self:PlayAnimation("Qiehuan")
    end
    self.TabIndex = index

    if index == self.TAB_TYPE.BUY then
        self:ClosePanelSell()
        self:OpenPanelBuy()
    elseif index == self.TAB_TYPE.SELL then
        self:ClosePanelBuy()
        self:OpenPanelSell()
    end
    
    XMVCA.XAreaWar:CheckSettleOrders()
end

function XUiAreaWarAuction:OpenPanelBuy()
    if not self.UiPanelBuy then
        local XUiPanelAreaWarAuctionBuy = require("XUi/XUiAreaWar/XUiPanelAreaWarAuctionBuy")
        ---@type XUiPanelAreaWarAuctionBuy
        self.UiPanelBuy = XUiPanelAreaWarAuctionBuy.New(self.PanelBuy, self)
    end
    self.UiPanelBuy:Open()
    self.UiPanelBuy:Refresh()
end

function XUiAreaWarAuction:ClosePanelBuy()
    if self.UiPanelBuy then
        self.UiPanelBuy:Close()
    else
        self.PanelBuy.gameObject:SetActiveEx(false)
    end
end

function XUiAreaWarAuction:OpenPanelSell()
    if not self.UiPanelSell then
        local XUiPanelAreaWarAuctionSell = require("XUi/XUiAreaWar/XUiPanelAreaWarAuctionSell")
        ---@type XUiPanelAreaWarAuctionSell
        self.UiPanelSell = XUiPanelAreaWarAuctionSell.New(self.PanelSell, self)
    end
    self.UiPanelSell:Open()
    self.UiPanelSell:Refresh()
end

function XUiAreaWarAuction:ClosePanelSell()
    if self.UiPanelSell then
        self.UiPanelSell:Close()
    else
        self.PanelSell.gameObject:SetActiveEx(false)
    end
end

function XUiAreaWarAuction:Refresh()
    if self.TabIndex == self.TAB_TYPE.BUY then
        self.UiPanelBuy:Refresh()
    elseif self.TabIndex == self.TAB_TYPE.SELL then
        self.UiPanelSell:Refresh()
    end
end

function XUiAreaWarAuction:GetSkipBuyItemId()
    return self._SkipBuyItemId
end

function XUiAreaWarAuction:ClearSkipBuyItemId()
    self._SkipBuyItemId = nil
end

return XUiAreaWarAuction
