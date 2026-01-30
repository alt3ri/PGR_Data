---@class XUiGridAreaWarHistoryOrder : XUiNode
---@field private _Control XAreaWarControl
---@field Parent XUiAreaWarPopupRecord
local XUiGridAreaWarHistoryOrder = XClass(XUiNode, "XUiGridAreaWarHistoryOrder")

function XUiGridAreaWarHistoryOrder:OnStart()
    self:RegisterUiEvents()

    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = XUiGridAreaWarItem.New(self.GridItem, self)
end

function XUiGridAreaWarHistoryOrder:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClick, nil, true)
end

function XUiGridAreaWarHistoryOrder:OnBtnHelpClick()
    self.Parent:ShowIncomeDetail(self.Order, self.BtnHelp.transform.position)
end

-- 刷新订单
---@param order XAreaWarAuctionOrder
function XUiGridAreaWarHistoryOrder:RefreshOrder(order)
    self.Order = order
    
    -- 道具
    self.GridAreaWarItem:RefreshItem(order.ItemId, order.Num)
    -- 道具数量
    self.TxtNum.text = order.Num
    -- 单价
    self.TxtPrice.text = order.Price
    -- 总收益
    self.TxtIncome.text = self._Control:GetItemRoom():GetOrderIncome(self.Order)
    -- 是否成功出售
    local MAX_AUTO_SELL_TIME = XAreaWarConfigs.GetMaxAutoSellTime()
    local isSellSuccess = order.AutoSellTime < MAX_AUTO_SELL_TIME
    self.PanelSold.gameObject:SetActiveEx(isSellSuccess)
    self.PanelExpired.gameObject:SetActiveEx(not isSellSuccess)
end

return XUiGridAreaWarHistoryOrder
