---@class XUiShopPopupSkyGardenFashion : XBigWorldUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnBuy XUiComponent.XUiButton
---@field BtnGo XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
local XUiShopPopupSkyGardenFashion = XMVCA.XBigWorldUI:Register(nil, "UiShopPopupSkyGardenFashion")
-- v1.28 采购优化-时装购买CD
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000
-- region 生命周期
local ConditionId = 601000
local SkipId = 89076

function XUiShopPopupSkyGardenFashion:OnAwake()
    local ColorRed = CS.XGame.ClientConfig:GetString("ShopCanNotBuyColor")
    self.shopCanNotBuyColor = XUiHelper.Hexcolor2Color(ColorRed)
    self.shopCanBuyColor = CS.UnityEngine.Color(1, 1, 1)
    self:InitComponents()
end

function XUiShopPopupSkyGardenFashion:InitComponents()
    -- Button
    self.BtnUse:AddEventListener(function()
        self:OnBtnUseClick()
    end)
    self.BtnTanchuangClose:AddEventListener(function()
        self:OnBtnCloseClick()
    end)
    self.BtnBuy:AddEventListener(function()
        self:OnBtnBuyClick()
    end)
    self.BtnGo:AddEventListener(function()
        self:OnBtnGoClick()
    end)
end

function XUiShopPopupSkyGardenFashion:OnStart(partId, buyData, goodsData)
    self.PartId = partId
    self.BuyData = buyData
    self.GoodsData = goodsData
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.BuyData.CurRewardGoods.TemplateId)
    self:SetBuyDataAndRefreshView()
end

function XUiShopPopupSkyGardenFashion:SetBuyDataAndRefreshView()
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnUse.gameObject:SetActiveEx(false)
    self.BtnGo.gameObject:SetActiveEx(false)

    if not self.BuyData or self.BuyData.HideBuyBtn then
        return
    end

    self:RefreshBuyButton()
    self:RefreshBuyPrice()
    self:RefreshItemInfo()
    self:RefrshSuitState()
end

function XUiShopPopupSkyGardenFashion:RefreshBuyPrice()
    if self.BuyData.ItemCount then
        local itemId = self.BuyData.ItemId
        local needItemCount = self.BuyData.ItemCount
        local itemCount = XDataCenter.ItemManager.GetCount(itemId)
        local color = self.shopCanBuyColor
        if itemCount < needItemCount then
            color = self.shopCanNotBuyColor
        end
        self.BtnBuy:SetRawImage(self.BuyData.ItemIcon)
        self.BtnBuy:SetNameByGroup(0, needItemCount)
        self.BtnBuy:SetTxtColorByGroup(0, color)
    else
        XLog.Error("购买数据不完整，缺少 ItemCount")
    end
end

function XUiShopPopupSkyGardenFashion:RefreshItemInfo()
    -- ShopIcon
    self.UiTxtName.text = self.GoodsShowParams.GoodsName
    self.UiTxtDesc.text = self.GoodsShowParams.WorldDesc
    self.UiRImgCoating:SetRawImage(self.GoodsShowParams.ShopIcon)
end

function XUiShopPopupSkyGardenFashion:RefrshSuitState()
    local isSuit = XMVCA.XBigWorldCommanderDIY:GetPartIsSuit(self.PartId)
    self.PanelSuit.gameObject:SetActiveEx(isSuit)
end

function XUiShopPopupSkyGardenFashion:RefreshBuyButton()
    local isHave = self.GoodsData.TotalBuyTimes >= self.GoodsData.BuyTimesLimit
    self.BtnBuy.gameObject:SetActiveEx(not isHave)
    self.BtnGo.gameObject:SetActiveEx(isHave)
end

function XUiShopPopupSkyGardenFashion:OnBtnBuyClick()
    self:OnBeforeBtnBuyClick(handler(self, self.ShowBuyPopup))
end

function XUiShopPopupSkyGardenFashion:ShowBuyPopup()
    if self.IsEnableGroupSales then
        self:BuyFashionGroup()
        return
    end
    local sureCb = function()
        if self.BuyData.QuickBuyCallBack ~= nil and XOverseaManager.IsTWRegion() then
            self.BuyData.QuickBuyCallBack()
        else
            self.BuyData.BuyCallBack()
        end

        self:OnBtnBackClick()
    end

    sureCb()
end

--- 执行正常购买流程前的处理，用于特殊逻辑
function XUiShopPopupSkyGardenFashion:OnBeforeBtnBuyClick(cb)
    -- 未执行特殊逻辑，则直接执行回调
    if cb then
        cb()
    end
end

function XUiShopPopupSkyGardenFashion:OnBtnUseClick()
    XUiManager.TipText("UseSuccess")
    self.BtnUse:SetDisable(true, false)
end

function XUiShopPopupSkyGardenFashion:OnBtnGoClick()
    -- 跳转逻辑
    XFunctionManager.SkipInterface(SkipId)
end

function XUiShopPopupSkyGardenFashion:OnBtnBackClick()
    self:Close()
end

function XUiShopPopupSkyGardenFashion:OnBtnCloseClick()
    self:Close()
end

return XUiShopPopupSkyGardenFashion
