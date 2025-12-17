---@class XUiPanelTheatre5ItemDetailBtns: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BubbleItemDetail
local XUiPanelTheatre5ItemDetailBtns = XClass(XUiNode, 'XUiPanelTheatre5ItemDetailBtns')

local NoTargetIndex = -1

function XUiPanelTheatre5ItemDetailBtns:OnStart()
    self.BtnSell:AddEventListener(handler(self, self.OnBtnSellClickEvent))
    self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClickEvent))
    self.BtnFreeze:AddEventListener(handler(self, self.OnBtnFreezeClickEvent))
    self.BtnDiscard:AddEventListener(handler(self, self.OnBtnSellClickEvent))
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClickEvent))
    self.BtnEquip:AddEventListener(handler(self, self.OnBtnEquipClickEvent))
    if self.UiTheatre5BtnRemove then
        self.UiTheatre5BtnRemove:AddEventListener(handler(self, self.OnUndressClickEvent))
    end
    self.UiTheatre5BtnUse:AddEventListener(handler(self, self.OnBtnUseClickEvent))
end

function XUiPanelTheatre5ItemDetailBtns:HideAllBtns()
    self.BtnFreeze.gameObject:SetActiveEx(false)
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnSell.gameObject:SetActiveEx(false)
    self.BtnDiscard.gameObject:SetActiveEx(false)
    self.BtnChoose.gameObject:SetActiveEx(false)
    self.BtnEquip.gameObject:SetActiveEx(false)
    if self.UiTheatre5BtnRemove then
        self.UiTheatre5BtnRemove.gameObject:SetActiveEx(false)
    end
    if self.UiTheatre5BtnUse then
        self.UiTheatre5BtnUse.gameObject:SetActiveEx(false)
    end
end

---@param itemData XTheatre5Item
function XUiPanelTheatre5ItemDetailBtns:RefreshBtns(itemData, ownerType)
    if type(itemData) ~= 'table' then
        return
    end
    local isOnlyShowDetails = ownerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails --只展示详情
    self.GameObject:SetActiveEx(not isOnlyShowDetails)
    if isOnlyShowDetails then
        return
    end

    if ownerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods then
        self.BtnFreeze.gameObject:SetActiveEx(true)
        self.BtnBuy.gameObject:SetActiveEx(true)

        ---@type XTableTheatre5Item
        local itemCfg = self._Control:GetTheatre5ItemCfgById(itemData.ItemId)

        ---@type XTheatre5Goods
        local goodsData = self._Control.ShopControl:GetShopGoodsByItemInstanceId(itemData.InstanceId)

        if goodsData then
            self.IsFreeze = goodsData.IsFreeze

            self.TxtBuyDiscountNum.gameObject:SetActiveEx(goodsData.IsSpecialPrice)

            if goodsData.IsSpecialPrice then
                self.TxtBuyDiscountNum.text = itemCfg.Price
                self.TxtBuyPriceNum.text = itemCfg.DiscountPrice
            else
                self.TxtBuyPriceNum.text = itemCfg.Price
            end

            self.BtnFreeze:SetNameByGroup(0, self._Control.ShopControl:GetGoodsFreezeStateLabel(self.IsFreeze))
            self.BtnFreezeStateCtrl:ChangeState(self.IsFreeze and 'ShowUnFreeze' or 'ShowFreeze')
        end
        if self.UiTheatre5BtnUse then
            self.UiTheatre5BtnUse.gameObject:SetActiveEx(false)
        end

    elseif ownerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection then
        self.BtnChoose.gameObject:SetActiveEx(true)
        if self.UiTheatre5BtnUse then
            self.UiTheatre5BtnUse.gameObject:SetActiveEx(false)
        end
    else
        if itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
            self.BtnDiscard.gameObject:SetActiveEx(true)
            if not self:IsEquip() then
                if self.Parent.OwnerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock then
                    self.BtnEquip.gameObject:SetActiveEx(true)
                end
            else
                if self.UiTheatre5BtnRemove then
                    self.UiTheatre5BtnRemove.gameObject:SetActiveEx(true)
                end
            end
            if self.UiTheatre5BtnUse then
                self.UiTheatre5BtnUse.gameObject:SetActiveEx(false)
            end

        elseif itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
            self.BtnSell.gameObject:SetActiveEx(true)
            if not self:IsEquip() then
                if self.Parent.OwnerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock then
                    self.BtnEquip.gameObject:SetActiveEx(true)
                end
            else
                if self.UiTheatre5BtnRemove then
                    self.UiTheatre5BtnRemove.gameObject:SetActiveEx(true)
                end
            end
            if self.UiTheatre5BtnUse then
                self.UiTheatre5BtnUse.gameObject:SetActiveEx(false)
            end

            ---@type XTableTheatre5Item
            local itemCfg = self._Control:GetTheatre5ItemCfgById(itemData.ItemId)

            if itemData.IsStrengthen then
                self.TxtSellNum.text = math.floor(itemCfg.SellPrice * self._Control.ShopControl:GetStrengthenRate() / 10000)
            else
                self.TxtSellNum.text = itemCfg.SellPrice
            end

        elseif itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Hammer then
            ---@type XTableTheatre5Item
            local itemCfg = self._Control:GetTheatre5ItemCfgById(itemData.ItemId)
            self.TxtSellNum.text = itemCfg.SellPrice
            self.BtnSell.gameObject:SetActiveEx(true)
            if self.UiTheatre5BtnUse then
                self.UiTheatre5BtnUse.gameObject:SetActiveEx(true)
            end
        end
    end
end

function XUiPanelTheatre5ItemDetailBtns:IsEquip()
    return self.Parent.OwnerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock and
            self.Parent.OwnerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock
end

function XUiPanelTheatre5ItemDetailBtns:OnBtnSellClickEvent()
    -- 卖出
    local isEquip = self:IsEquip()
    XMVCA.XTheatre5:RequestTheatre5ShopSellItem(self.Parent.ItemData.InstanceId, self.Parent.ItemData.ItemType, isEquip, function(success)
        if success then
            self._Control.ShopControl:RefreshAfterSellRequest()
            self:CloseRootUi()
        end
    end)
end

function XUiPanelTheatre5ItemDetailBtns:OnBtnBuyClickEvent()
    if not self._Control.ShopControl:CheckHasEngouhGoldBuyGoods(self.Parent.ItemData.InstanceId) then
        return
    end

    local isEquipped = false
    local itemType = self.Parent.ItemData.ItemType

    -- 优先检查是否能直接穿上
    if itemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        isEquipped = self._Control.ShopControl:CheckHasEmptySkillSlot()
    elseif itemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        isEquipped = self._Control.ShopControl:CheckHasEmptyRuneSlot()
    end

    -- 如果不能，则入背包，需要检查背包是否满
    if not isEquipped and self._Control.ShopControl:CheckBagListIsFull(false, true) then
        return
    end

    XMVCA.XTheatre5:RequestTheatre5ShopBuyItem(self.Parent.ItemData.InstanceId, isEquipped, NoTargetIndex, function(success)
        if success then
            self._Control.ShopControl:RefreshAfterBuyRequest()
            self._Control.ShopControl:PlayItemPlacedSFX(itemType)
            self:CloseRootUi()
        end
    end)

end

function XUiPanelTheatre5ItemDetailBtns:OnBtnFreezeClickEvent()
    local isFreeze = self.IsFreeze

    XMVCA.XTheatre5:RequestTheatre5ShopFreeze(self.Parent.ItemData.InstanceId, not self.IsFreeze, function(success)
        if success then
            self._Control.ShopControl:RefreshAfterFreezeRequest()
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PLAY_GOODS_FREEZE_SFX, not isFreeze)
            self:CloseRootUi()
        end
    end)
end

function XUiPanelTheatre5ItemDetailBtns:OnBtnChooseClickEvent()
    local isEquipped = false
    local itemType = self.Parent.ItemData.ItemType

    if itemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        isEquipped = self._Control.ShopControl:CheckHasEmptySkillSlot()
    elseif itemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        isEquipped = self._Control.ShopControl:CheckHasEmptyRuneSlot()
    end

    -- 购买到背包中前，要判断有没有空位
    if not isEquipped then
        if self._Control.ShopControl:CheckBagListIsFull(false, true) then
            return
        end
    end

    XMVCA.XTheatre5:RequestTheatre5SkillChoice(self.Parent.ItemData.InstanceId, isEquipped, -1, function(success)
        if success then
            self._Control.ShopControl:RefreshAfterBuyRequest()
            self._Control.ShopControl:PlayItemPlacedSFX(itemType)
        end

        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_STATE_CHANGED, true)
        self:CloseRootUi()
    end)
end

function XUiPanelTheatre5ItemDetailBtns:CloseRootUi()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

function XUiPanelTheatre5ItemDetailBtns:OnBtnEquipClickEvent()
    self._Control.ShopControl:EquipItem(self.Parent.ItemData)
    self.Parent:Close()
end

function XUiPanelTheatre5ItemDetailBtns:OnUndressClickEvent()
    self._Control.ShopControl:UndressItem(self.Parent.ItemData)
    self.Parent:Close()
end

function XUiPanelTheatre5ItemDetailBtns:OnBtnUseClickEvent()
    local hasRuneCanStrengthen, items = self._Control:HasRuneCanStrengthen(self.Parent.ItemData)
    if hasRuneCanStrengthen then
        XLuaUiManager.Open("UiTheatre5PopupStrengthen", self.Parent.ItemData, items)
        self.Parent:Close()
    else
        local text = XMVCA.XTheatre5:GetText("NothingCanStrength")
        XUiManager.TipMsg(text)
    end
end

return XUiPanelTheatre5ItemDetailBtns