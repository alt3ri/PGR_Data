-- 购买弹框
local XUiShopItem = require("XUi/XUiShop/XUiShopItem")
---@class XUiDlcRelinkShopItem : XUiShopItem
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkShopItem = XLuaUiManager.Register(XUiShopItem, "UiDlcRelinkShopItem")

function XUiDlcRelinkShopItem:ChangeCostColor(bool, index)
    local colorStr = self._Control:GetClientConfig("ShopCanBuyColor", bool and 1 or 2)
    self["TxtCostCount" .. index].color = XUiHelper.Hexcolor2Color(colorStr)
end

return XUiDlcRelinkShopItem
