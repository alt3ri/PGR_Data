---@class XUiBigWorldPurchaseItem : XBigWorldUi
---@field BtnBack XUiComponent.XUiButton
---@field TxtName UnityEngine.UI.Text
---@field TxtCount UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
---@field RImgCostIcon UnityEngine.UI.RawImage
---@field TxtCostCount UnityEngine.UI.Text
---@field BtnBuy XUiComponent.XUiButtonExt
---@field PanelTips UnityEngine.UI.Text
---@field TxtTips UnityEngine.UI.Text
---@field TxtBuyCount UnityEngine.UI.Text
---@field BtnAddSelect XUiComponent.XUiButtonExt
---@field BtnMinusSelect XUiComponent.XUiButtonExt
---@field BtnMax XUiComponent.XUiButtonExt
---@field TxtSelect UnityEngine.UI.InputField
local XUiBigWorldPurchaseItem = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPurchaseItem")

function XUiBigWorldPurchaseItem:OnAwake()
    self._ShopId = 0
    self._Data = false
    self._Callback = false
    self._Consume = false

    self._MaxCount = CS.XGame.Config:GetInt("ShopBuyGoodsCountLimit")
    self._ColorRed = CS.XGame.ClientConfig:GetString("ShopCanNotBuyColor")
    self._ColorBlack = CS.XGame.ClientConfig:GetString("ShopCanBuyColor")

    self._Sales = 100
    self._Count = 1

    self:_RegisterButtonClicks()
end

function XUiBigWorldPurchaseItem:OnStart(shopId, data, callback)
    self._ShopId = shopId
    self._Data = data
    self._Callback = callback

    self:_InitConsume()
end

function XUiBigWorldPurchaseItem:OnEnable()
    self:_RefreshItem()
    self:_RefreshCost()
    self:_RefreshTips()
    self:_RefreshCount()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPurchaseItem:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldPurchaseItem:OnDestroy()
end

function XUiBigWorldPurchaseItem:OnBtnBuyClick()
    if not self:_CheckItemCount() then
        XMVCA.XBigWorldUI:TipText("ShopBuyNotEnough")
        return
    end

    XMVCA.XBigWorldService:RequestShopBuy(self._ShopId, self._Data.Id, self._Count, function()
        XMVCA.XBigWorldUI:TipText("ShopBuySuccess")

        if self._Callback then
            self._Callback(self._Count)
        end

        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_SHOP_BUY, self._Data, self._Count)

        self._Count = 1

        self:_RefreshMaxCount()

        if self:_CheckItemCount() and self._MaxCount > 0 then
            self:_RefreshTips()
            self:_RefreshCostCount()
            self:_RefreshCount()
        else
            self:Close()
        end
    end)
end

function XUiBigWorldPurchaseItem:OnBtnMaxClick()
    self._Count = self._MaxCount
    self:_RefreshCount()
    self:_RefreshCostCount()
end

function XUiBigWorldPurchaseItem:OnBtnAddSelectClick()
    self._Count = math.min(self._Count + 1, self._MaxCount)
    self:_RefreshCount()
    self:_RefreshCostCount()
end

function XUiBigWorldPurchaseItem:OnBtnMinusSelectClick()
    self._Count = math.max(self._Count - 1, 1)
    self:_RefreshCount()
    self:_RefreshCostCount()
end

function XUiBigWorldPurchaseItem:OnTxtSelectChanged(text)
    self._Count = math.min(self._MaxCount, math.max(tonumber(text) or 1, 1))
    self:_RefreshCostCount()
end

function XUiBigWorldPurchaseItem:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBack:AddEventListener(Handler(self, self.Close))
    self.BtnBuy:AddEventListener(Handler(self, self.OnBtnBuyClick))
    self.BtnMax:AddEventListener(Handler(self, self.OnBtnMaxClick))
    self.BtnAddSelect:AddEventListener(Handler(self, self.OnBtnAddSelectClick))
    self.BtnMinusSelect:AddEventListener(Handler(self, self.OnBtnMinusSelectClick))
    self.TxtSelect.onValueChanged:AddListener(Handler(self, self.OnTxtSelectChanged))
end

function XUiBigWorldPurchaseItem:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldPurchaseItem:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldPurchaseItem:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPurchaseItem:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPurchaseItem:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPurchaseItem:_InitConsume()
    if not self._Data then
        return
    end

    if not XTool.IsTableEmpty(self._Data.ConsumeList) then
        self._Consume = self._Data.ConsumeList[1]
    end
end

function XUiBigWorldPurchaseItem:_RefreshMaxCount()
    if not self._Data or not XTool.IsNumberValid(self._ShopId) then
        return
    end

    local sortedKeys = {}
    local onSales = self._Data.OnSales
    local leftSalesGoods = self._MaxCount
    local leftGoodsTimes = self._MaxCount
    local leftShopTimes = XMVCA.XBigWorldService:GetShopLeftBuyTimes(self._ShopId)

    for key, _ in pairs(onSales) do
        table.insert(sortedKeys, key)
    end

    table.sort(sortedKeys)

    for i = 1, #sortedKeys do
        if self._Data.TotalBuyTimes >= sortedKeys[i] - 1 then
            self._Sales = onSales[sortedKeys[i]]
        else
            leftSalesGoods = sortedKeys[i] - self._Data.TotalBuyTimes - 1
            break
        end
    end

    if not leftShopTimes then
        leftShopTimes = self._MaxCount
    end

    if self._Data.BuyTimesLimit and self._Data.BuyTimesLimit > 0 then
        local buyCount = self._Data.TotalBuyTimes and self._Data.TotalBuyTimes or 0

        leftGoodsTimes = self._Data.BuyTimesLimit - buyCount
    end

    self._MaxCount = math.min(leftGoodsTimes, leftShopTimes, leftSalesGoods)
end

function XUiBigWorldPurchaseItem:_RefreshItem()
    if not self._Data then
        return
    end

    local templateId = self._Data.RewardGoods.TemplateId

    self.TxtCount.text = XMVCA.XBigWorldService:GetGoodsCurrentCountByTemplateId(templateId)
    self.TxtName.text = XMVCA.XBigWorldService:GetGoodsNameByTemplateId(templateId)
    self.RImgIcon:SetImage(XMVCA.XBigWorldService:GetGoodsIconByTemplateId(templateId))
end

function XUiBigWorldPurchaseItem:_RefreshCost()
    if not self._Consume then
        return
    end

    self.RImgCostIcon:SetImage(XMVCA.XBigWorldService:GetGoodsIconByTemplateId(self._Consume.Id))
    self:_RefreshCostCount()
end

function XUiBigWorldPurchaseItem:_RefreshCostCount()
    if not self._Consume then
        return
    end

    self.TxtCostCount.text = self._Consume.Count * self._Count

    if not self:_CheckItemCount() then
        self.TxtCostCount.color = XUiHelper.Hexcolor2Color(self._ColorRed)
    else
        self.TxtCostCount.color = XUiHelper.Hexcolor2Color(self._ColorBlack)
    end
end

function XUiBigWorldPurchaseItem:_RefreshTips()
    self:_RefreshMaxCount()
    self.TxtTips.text = self._MaxCount
end

function XUiBigWorldPurchaseItem:_RefreshCount()
    self.TxtSelect:SetTextWithoutNotify(self._Count)
end

function XUiBigWorldPurchaseItem:_CheckItemCount()
    if not self._Consume then
        return false
    end

    local itemCount = XMVCA.XBigWorldService:GetGoodsCurrentCountByTemplateId(self._Consume.Id)

    return itemCount >= self._Consume.Count * self._Count
end

return XUiBigWorldPurchaseItem
