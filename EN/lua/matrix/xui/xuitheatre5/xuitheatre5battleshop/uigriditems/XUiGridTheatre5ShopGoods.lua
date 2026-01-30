local XUiGridTheatre5ShopContainer = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopContainer')
--- 商店容器派生-商店商品格子
---@class XUiGridTheatre5ShopGoods: XUiGridTheatre5ShopContainer
---@field Parent XUiPanelTheatre5Store
local XUiGridTheatre5ShopGoods = XClass(XUiGridTheatre5ShopContainer, 'XUiGridTheatre5ShopGoods')

function XUiGridTheatre5ShopGoods:SetLockState(isLock)
    self.IsLock = isLock
    self.ImgLock.gameObject:SetActiveEx(self.IsLock)
    self.PanelPrice.gameObject:SetActiveEx(not self.IsLock)
    
    if self.IsLock then
        self:_ClearItemShow()

        if self.PanelFreeze then
            self.PanelFreeze.gameObject:SetActiveEx(false)
        end

        if self.ImgSelloutBg then
            self.ImgSelloutBg.gameObject:SetActiveEx(false)
        end
    end
    
    self.ImgLock:AddEventListener(handler(self, self.OnBtnLockClickEvent))
end

---@overload
---@param goodsData XTheatre5Goods
function XUiGridTheatre5ShopGoods:SetItemData(goodsData, isRefreshNew)
    if not goodsData then
        self:_ClearItemShow()
        return
    end

    -- 是否已售出
    if self.ImgSelloutBg then
        self.ImgSelloutBg.gameObject:SetActiveEx(goodsData.IsSoldOut)
    end
    
    if goodsData.IsSoldOut then
        self:_ClearItemShow()
        if self.PanelPrice then
            self.PanelPrice.gameObject:SetActiveEx(true)
            self.TxtDiscountNum.gameObject:SetActiveEx(false)
            self.TxtNum.text = self._Control.ShopControl:GetClientConfigGoodsPriceShowOnSellout()
        end
        return    
    end

    self:_SetItemType(goodsData.ItemInfo.ItemType)

    if not self.CurUiGrid then
        return
    end

    self.CurUiGrid:Open()
    self.CurUiGrid:RefreshShow(goodsData.ItemInfo)

    if isRefreshNew then
        self.CurUiGrid:PlayAnimation('GridRefresh')
    end

    ---@type XTableTheatre5Item
    local itemCfg = self._Control:GetTheatre5ItemCfgById(goodsData.ItemInfo.ItemId)

    if not itemCfg then
        return
    end
    
    -- 冻结状态显示
    if self.PanelFreeze then
        self.PanelFreeze.gameObject:SetActiveEx(goodsData.IsFreeze)
    end
    
    -- 价格显示
    if self.PanelPrice then
        self.PanelPrice.gameObject:SetActiveEx(true)
    end

    if self.TxtDiscountNum then
        self.TxtDiscountNum.gameObject:SetActiveEx(goodsData.IsSpecialPrice)
    end

    if goodsData.IsSpecialPrice then
        if self.TxtDiscountNum then
            self.TxtDiscountNum.text = itemCfg.Price
        end

        if self.TxtNum then
            self.TxtNum.text = itemCfg.DiscountPrice
        end
    else
        if self.TxtNum then
            self.TxtNum.text = itemCfg.Price
        end
    end
end

---@overload
function XUiGridTheatre5ShopGoods:_ClearItemShow()
    XUiGridTheatre5ShopContainer._ClearItemShow(self)
    if self.PanelPrice then
        self.PanelPrice.gameObject:SetActiveEx(true)
        self.TxtDiscountNum.gameObject:SetActiveEx(false)
        self.TxtNum.text = self._Control.ShopControl:GetClientConfigGoodsPriceShowOnSellout()
    end

    if self.ListTag then
        self.ListTag.gameObject:SetActiveEx(false)
    end

    if self.PanelFreeze then
        self.PanelFreeze.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5ShopGoods:OnBtnLockClickEvent()
    XUiManager.TipMsg(self._Control.ShopControl:GetClientConfigLockGoodsSlotClickTips())
end

return XUiGridTheatre5ShopGoods