---@class XUiPanelAreaWarAuctionSell : XUiNode
---@field private _Control XAreaWarControl
local XUiPanelAreaWarAuctionSell = XClass(XUiNode, "XUiPanelAreaWarAuctionSell")

function XUiPanelAreaWarAuctionSell:OnStart()
    local XUiPanelAreaWarAuctionSellShelf = require("XUi/XUiAreaWar/XUiPanelAreaWarAuctionSellShelf")
    ---@type XUiPanelAreaWarAuctionSellShelf
    self.UiPanelShelf = XUiPanelAreaWarAuctionSellShelf.New(self.PanelShelf, self)
    
    local XUiPanelAreaWarAuctionSellBag = require("XUi/XUiAreaWar/XUiPanelAreaWarAuctionSellBag")
    ---@type XUiPanelAreaWarAuctionSellBag
    self.UiPanelBag = XUiPanelAreaWarAuctionSellBag.New(self.PanelBag, self)
end

function XUiPanelAreaWarAuctionSell:Refresh()
    self.UiPanelShelf:Refresh()
    self.UiPanelBag:Refresh()
end

return XUiPanelAreaWarAuctionSell
