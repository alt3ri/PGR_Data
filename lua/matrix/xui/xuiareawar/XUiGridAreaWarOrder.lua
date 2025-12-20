---@class XUiGridAreaWarOrder : XUiNode
---@field private _Control XAreaWarControl
---@field Parent XUiPanelAreaWarAuctionSellShelf
local XUiGridAreaWarOrder = XClass(XUiNode, "XUiGridAreaWarOrder")

function XUiGridAreaWarOrder:OnStart()
    self:RegisterUiEvents()

    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = XUiGridAreaWarItem.New(self.GridItem, self)
end

function XUiGridAreaWarOrder:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, nil, true)
end

function XUiGridAreaWarOrder:OnBtnCloseClick()
    local orderId = self.Order.OrderId
    local title, content = XAreaWarConfigs.GetOrderPutOffConfirmTips()
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        local itemRoom = self._Control:GetItemRoom()
        if itemRoom:IsOrderValid(orderId) then
            XMVCA.XAreaWar:RequestAreaWar4AuctionPutOff(orderId, function()
                self.Parent:Refresh()
            end)
        else
            local tips = XAreaWarConfigs.GetOrderPutOffFailTips()
            XUiManager.TipError(tips)
        end
    end)
end

-- 刷新订单
---@param order XAreaWarAuctionOrder
function XUiGridAreaWarOrder:RefreshOrder(order)
    self.Order = order
    
    -- 道具
    self.GridAreaWarItem:RefreshItem(order.ItemId, order.Num)
    -- 道具名称
    self.TxtName.text = self._Control:GetConfig():GetItemName(self.ItemId)
    -- 刷新代币图标
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    self.RImgToken:SetRawImage(icon)
    self.TxtIncome.text = order.Price
    -- 订单剩余有效时间
    self:RefreshTime()
end

-- 刷新订单剩余有效时间
function XUiGridAreaWarOrder:RefreshTime()
    if self.Order then
        local nowTime = XTime.GetServerNowTimestamp()
        local passTime = nowTime - self.Order.CreateTime
        if passTime < 0 then
            passTime = 0
        end
        local MAX_AUTO_SELL_TIME = XAreaWarConfigs.GetMaxAutoSellTime()
        if passTime > MAX_AUTO_SELL_TIME then
            self.TxtTime.text = "00:00:00"
        else
            local timestamp = MAX_AUTO_SELL_TIME - passTime
            local hourSecond = 3600
            local minSecond = 60
            local hour = math.floor(timestamp / hourSecond)
            local minute = math.floor((timestamp - hour * hourSecond) / minSecond)
            local second = timestamp - hour * hourSecond - minute * minSecond
            local time = string.format("%02d:%02d:%02d", hour, minute, second)
            self.TxtTime.text = time
        end
    end
end

return XUiGridAreaWarOrder
