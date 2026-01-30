local XUiPanelRecommendItem = XClass(nil, "XUiPanelRecommendItem")

function XUiPanelRecommendItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelRecommendItem:Update(package)

    local name = package:GetName()
    local buyTimes = package:GetCurrentBuyTime()
    local buyLimitCount = package:GetBuyLimitTime()
    local consumeCount = package:GetConsumeCount()
    local discountTag = package:GetTag()
    local discountDes = XPurchaseConfigs.GetTagDes(discountTag)
    
    if self.TxtName then
        self.TxtName.text = name
    end
    if self.TxtDiscountDes then
        self.TxtDiscountDes.text = discountDes
    end
    if self.TxtPrice then
        local discount = package:GetDiscount()
        if discount and XTool.IsNumberValid(discount[1]) then
            consumeCount = consumeCount * (discount[1] / 10000)
            consumeCount = tostring(math.floor(consumeCount))
        end
        self.TxtPrice.text = consumeCount
    end
    if self.TxtBuyLimit then
        self.TxtBuyLimit.text = CS.XTextManager.GetText("PurchaseLimitBuy", buyTimes, buyLimitCount)
    end
end

return XUiPanelRecommendItem