---@class XTheatre5ShopControl : XControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5Control
local XTheatre5ShopControl = XClass(XControl, "XTheatre5ShopControl")

function XTheatre5ShopControl:OnInit()

end

function XTheatre5ShopControl:AddAgencyEvent()

end

function XTheatre5ShopControl:RemoveAgencyEvent()

end

function XTheatre5ShopControl:OnRelease()
    self:ResetOnShopClose()
end

function XTheatre5ShopControl:GetShopState()
    return self._Model.CurAdventureData:GetCurPlayStatus()
end

--region ActivityData - Shop

function XTheatre5ShopControl:GetGoldNum()
    return self._Model.CurAdventureData:GetGoldNum()
end

function XTheatre5ShopControl:GetHealth()
    return self._Model.CurAdventureData:GetHealth()
end

function XTheatre5ShopControl:GetShopGoodsByItemInstanceId(instanceId)
    return self._Model.CurAdventureData:GetShopGoodsByItemInstanceId(instanceId)
end

function XTheatre5ShopControl:GetShopId()
    return self._Model.CurAdventureData:GetShopId()
end

--- 获取商店已解锁格子数
function XTheatre5ShopControl:GetShopUnlockGridsCount()
    return self._Model.CurAdventureData:GetShopUnlockGridsNum()
end

--- 获取商店指定位置的商品数据
function XTheatre5ShopControl:GetShopGoodsByIndex(index)
    return self._Model.CurAdventureData:GetShopGoodsByIndex(index)
end

--- 获取背包栏指定位置的物品数据
function XTheatre5ShopControl:GetItemInBagByIndex(index)
    return self._Model.CurAdventureData:GetItemInBagByIndex(index)
end

function XTheatre5ShopControl:GetItemInTempBagByIndex(index)
    return self._Model.CurAdventureData:GetItemInTempBagByIndex(index)
end

--- 获取技能栏格子数
function XTheatre5ShopControl:GetSkillListSize()
    return self._Model.CurAdventureData:GetBagSkillGridsNum()
end

--- 获取技能栏指定位置的技能数据
function XTheatre5ShopControl:GetItemInSkillListByIndex(index)
    return self._Model.CurAdventureData:GetItemInSkillListByIndex(index)
end

--- 检查背包栏是否已满
function XTheatre5ShopControl:CheckBagListIsFull(notips, isBuy)
    local itemCount = self._Model.CurAdventureData:GetBagListItemCount()
    local bagBlockCount = self:GetBagSizeLimit()

    if itemCount >= bagBlockCount then
        if not notips then
            if isBuy then
                XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('ShopBuyFaultFullBag'))
            end
        end
        return true
    end

    return false
end

function XTheatre5ShopControl:CheckAllGoodsIsFreeze()
    return self._Model.CurAdventureData:CheckAllGoodsIsFreeze()
end

function XTheatre5ShopControl:CheckHasAnyGoodsIsSellOut()
    return self._Model.CurAdventureData:CheckHasAnyGoodsIsSellOut()
end

function XTheatre5ShopControl:CheckAllGoodsAreSellOut()
    return self._Model.CurAdventureData:CheckAllGoodsAreSellOut()
end

--- 判断是否有足够的金币购买指定商品
function XTheatre5ShopControl:CheckHasEngouhGoldBuyGoods(instanceId, notips)
    -- 判断货币是否充足
    local goodsPrice = self:GetShopGoodsPriceByItemInstanceId(instanceId)
    local ownGold = self._Model.CurAdventureData:GetGoldNum()

    if ownGold < goodsPrice then
        if not notips then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('ShopBuyFaultMoneyNoEnough'))
        end
        return false
    end
    return true
end

--- 根据物品uid获取商品当前的价格
function XTheatre5ShopControl:GetShopGoodsPriceByItemInstanceId(instanceId)
    ---@type XTheatre5Goods
    local goods = self._Model.CurAdventureData:GetShopGoodsByItemInstanceId(instanceId)

    if XTool.IsTableEmpty(goods) then
        XLog.Error('实例Id:' .. tostring(instanceId) .. ' 找不到对应商品数据')
        return false
    end

    ---@type XTableTheatre5Item
    local itemCfg = self._Model:GetTheatre5ItemCfgById(goods.ItemInfo.ItemId)

    if goods and itemCfg then
        return goods.IsSpecialPrice and itemCfg.DiscountPrice or itemCfg.Price
    end

    return 0
end
--endregion

--region ActivityData - 技能三选一

function XTheatre5ShopControl:GetSkillChoiceList()
    if self._Model.CurAdventureData then
        return self._Model.CurAdventureData:GetSkillChoiceSkillGroup()
    end
end

function XTheatre5ShopControl:GetSkillChoiceListCount()
    if self._Model.CurAdventureData then
        return XTool.GetTableCount(self._Model.CurAdventureData:GetSkillChoiceSkillGroup())
    end

    return 0
end

--endregion

--region Configs 

--- 获取当前商店的配置
function XTheatre5ShopControl:GetCurShopCfg()
    local shopId = self:GetShopId()

    if XTool.IsNumberValid(shopId) then
        return self._Model:GetTheatre5ShopCfgById(shopId)
    end
end

--- 获取当前回合的配置
function XTheatre5ShopControl:GetCurRoundCfg()
    local roundNum = self._Model.CurAdventureData:GetRoundNum()

    if XTool.IsNumberValid(roundNum) then
        return self._Model:GetTheatre5PvpRoundRefreshCfgByRoundNum(roundNum)
    end
end

--- 获取购买时背包格子占用提示文本
function XTheatre5ShopControl:GetShopBuyBagContainerIndexIsFullTips(containerType)
    return self._Model:GetTheatre5ClientConfigText('ShopBuyBagContainer' .. tostring(containerType) .. 'IndexIsFull')
end

--- 获取单个商品的冻结按钮文本
function XTheatre5ShopControl:GetGoodsFreezeStateLabel(isFreeze)
    return self._Model:GetTheatre5ClientConfigText('GoodsFreezeStateLabels', isFreeze and 1 or 2)
end

--- 获取商店的冻结按钮文本
function XTheatre5ShopControl:GetShopFreezeStateLabel(isFreeze)
    return self._Model:GetTheatre5ClientConfigText('ShopFreezeStateLabels', isFreeze and 1 or 2)
end

--- 获取商店刷新失败提示文本
function XTheatre5ShopControl:GetShopRefreshErrorTips()
    return self._Model:GetTheatre5ClientConfigText('ShopRefreshErrorTips')
end

--- 全冻结下的刷新提示文本
function XTheatre5ShopControl:GetClientConfigAllFreezeShopRefreshTips()
    return self._Model:GetTheatre5ClientConfigText('AllFreezeShopRefreshTips')
end

--- 商品售出后的价格栏显示文本
function XTheatre5ShopControl:GetClientConfigGoodsPriceShowOnSellout()
    local content = self._Model:GetTheatre5ClientConfigText('GoodsPriceShowOnSellout')

    content = string.gsub(content, '\\', '')

    return content
end

--- 获取背包容量
function XTheatre5ShopControl:GetBagSizeLimit()
    return self._Model:GetTheatre5ConfigValByKey('BagItemGridMaxNum')
end

--- 获取临时背包容量
function XTheatre5ShopControl:GetTempBagSizeLimit()
    return self._Model:GetTheatre5ConfigValByKey('TempItemBagGridMaxNum')
end

--- 获取当前的刷新商店配置
function XTheatre5ShopControl:GetCurShopRefreshCntCostCfg()
    local refreshCnt = self._Model.CurAdventureData:GetShopRefreshTimes()

    ---@type XTableTheatre5Shop
    local shopCfg = self:GetCurShopCfg()

    if shopCfg then
        local groupId = shopCfg.RefreshCostGroupId

        if XTool.IsNumberValid(groupId) then
            local idPreix = groupId * XMVCA.XTheatre5.EnumConst.RefreshCntCostIdPreix

            for i = 1, XMVCA.XTheatre5.EnumConst.RefreshCntCostIdPreix - 1 do
                local id = idPreix + i

                ---@type XTableTheatre5ShopRefreshCost
                local refreshCfg = self._Model:GetTheatre5ShopRefreshCostCfgById(id)

                if refreshCfg then
                    if refreshCnt >= refreshCfg.RefreshCnt then
                        return refreshCfg
                    end
                else
                    return
                end
            end
        end
    end
end

--- 获取当前下一个槽位解锁的配置
function XTheatre5ShopControl:GetTheatre5GridUnlockCostCfg()
    local originCount = self._MainControl.GameEntityControl:GetRuneGridInitCount()
    local unlockCount = self._MainControl:GetGemUnlockSlotCount()
    local unlockTimes = unlockCount - originCount + 1

    return self._Model:GetTheatre5GridUnlockCostCfgByUnlockNum(unlockTimes)
end

--- 获取当前下一关槽位解锁的费用
function XTheatre5ShopControl:GetCurTurnsGemSlotUnlockCost()
    ---@type XTableTheatre5GridUnlockCost
    local cfg = self:GetTheatre5GridUnlockCostCfg()
    local reduce = self._MainControl.GameEntityControl:GetCurRoundGridUnlockCostReduce()

    return math.max(cfg.GoldCost - reduce, 1)
end

--- 获取商店概率文本格式
function XTheatre5ShopControl:GetClientConfigShopItemProbShowLabel()
    return self._Model:GetTheatre5ClientConfigText('ShopItemProbShowLabel')
end

--- 获取卖出技能时显示的文本
function XTheatre5ShopControl:GetClientConfigSellSkillLabel()
    return self._Model:GetTheatre5ClientConfigText('SellSkillLabel')
end

--- 获取卖出其他道具，显示价格的文本格式
function XTheatre5ShopControl:GetClientConfigSellItemWithPriceShow()
    return self._Model:GetTheatre5ClientConfigText('SellItemWithPriceShow')
end

function XTheatre5ShopControl:GetClientConfigLockGoodsSlotClickTips()
    return self._Model:GetTheatre5ClientConfigText('LockGoodsSlotClickTips')
end

--- 获取没有商品可冻结时，点击冻结全部的提示文本
function XTheatre5ShopControl:GetClientConfigFreezeAllSellOutGoodsTips()
    return self._Model:GetTheatre5ClientConfigText('FreezeAllSellOutGoodsTips')
end
--endregion

--region 界面数据 - 商店

function XTheatre5ShopControl:ResetOnShopClose()
    self._DraggingItemData = nil
    self._FocusContainerType = nil
    self._FocusContainerIndex = nil
    self._DraggingItemOwnerContainerType = nil
    self._DraggingItemBelongIndex = nil

    self._SelectedUiItem = nil
end

function XTheatre5ShopControl:SetDraggingItemData(itemData, containerType, index)
    ---@type XTheatre5Item
    self._DraggingItemData = itemData
    self._DraggingItemOwnerContainerType = containerType
    self._DraggingItemBelongIndex = index
end

function XTheatre5ShopControl:GetIsDraggingItem()
    return self._DraggingItemData and true or false
end

function XTheatre5ShopControl:GetDraggingItemOwnerContainerType()
    return self._DraggingItemOwnerContainerType or 0
end

function XTheatre5ShopControl:GetDraggingItemData()
    return self._DraggingItemData
end

function XTheatre5ShopControl:CheckIsSameItem(itemData)
    if self._DraggingItemData then
        return self._DraggingItemData.InstanceId == itemData.InstanceId
    end

    return false
end

function XTheatre5ShopControl:SetFocusContainer(containerType, index)
    self._FocusContainerType = containerType
    self._FocusContainerIndex = index
end

function XTheatre5ShopControl:CheckIsSameContainer(containerType, index)
    return self._FocusContainerType == containerType and self._FocusContainerIndex == index
end

--- 判断目标容器是否可容纳拖拽的物品
function XTheatre5ShopControl:CheckDraggingItemIsFitInContainer()
    if self._DraggingItemData == nil or self._FocusContainerType == nil then
        return true
    end

    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock and self._DraggingItemData.ItemType ~= XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        return false
    elseif self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock and self._DraggingItemData.ItemType ~= XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        return false
    end

    return true
end

function XTheatre5ShopControl:OnEndDragging(cb)
    -- 检查拖拽物品是否还在，以及是否聚焦在某个类型的容器上
    if self._DraggingItemData and self._FocusContainerIndex and self._FocusContainerType then
        -- 判断是买入/卖出/装备调整
        local originIsFromGoods = self._DraggingItemOwnerContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods
        local targetIsGoods = self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods

        -- 判断是否三选一
        local originIsFromSkillChoice = self._DraggingItemOwnerContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection
        local targetIsSkillChoice = self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection

        if originIsFromSkillChoice then
            if not targetIsSkillChoice then
                if not self:_EndDragForSkillChoice(cb) then
                    return false
                end
            else
                return false
            end
        elseif originIsFromGoods and not targetIsGoods then
            -- 买入
            if not self:_EndDragForBuyFromNormalShop(cb) then
                return false
            end
        elseif not originIsFromGoods and (targetIsGoods or targetIsSkillChoice) then
            -- 卖出
            if not self:_EndDragForSellToNormalShop(cb) then
                return false
            end
        elseif not originIsFromGoods and not targetIsGoods then
            -- 装备调整
            if not self:_EndDragForEquipArrange(cb) then
                return false
            end
        else
            return false
        end

        return true
    end
end

function XTheatre5ShopControl:_EndDragForBuyFromNormalShop(cb)
    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('NoDragToTempBag'))
        return false
    end

    if not self:CheckHasEngouhGoldBuyGoods(self._DraggingItemData.InstanceId) then
        return false
    end

    -- 判断位置是否对
    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock and self._DraggingItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('RuneToSkillContainerTips'))
        return false
    end

    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock and self._DraggingItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('SkillToRuneContainerTips'))
        return false
    end

    -- 判断拖拽位置是否已经有物品了
    if self._Model.CurAdventureData:CheckHasItemByContainerTypeAndIndex(self._FocusContainerType, self._FocusContainerIndex) then
        XUiManager.TipMsg(self:GetShopBuyBagContainerIndexIsFullTips(self._FocusContainerType))
        return false
    end
    
    -- 不能把炼金锤拖到装备栏/技能栏
    if self._DraggingItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Hammer then
        if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock
            or self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock
        then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText("HammerDragFail"))
            return
        end
    end

    local isEquipped = self._FocusContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock
    local itemType = self._DraggingItemData.ItemType

    XMVCA.XTheatre5:RequestTheatre5ShopBuyItem(self._DraggingItemData.InstanceId, isEquipped, self._FocusContainerIndex, function(success)
        if success then
            self:RefreshAfterBuyRequest()

            self:PlayItemPlacedSFX(itemType)
        end

        if cb then
            cb()
        end
    end)

    return true
end

function XTheatre5ShopControl:_EndDragForSellToNormalShop(cb)
    local isEquipped = self._DraggingItemOwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock and
            self._DraggingItemOwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock

    -- 卖出
    XMVCA.XTheatre5:RequestTheatre5ShopSellItem(self._DraggingItemData.InstanceId, self._DraggingItemData.ItemType, isEquipped, function(success)
        if success then
            self:RefreshAfterSellRequest()
        end

        if cb then
            cb(XMVCA.XTheatre5.EnumConst.ShopOperationType.SellGem)
        end
    end)

    return true
end

function XTheatre5ShopControl:_EndDragForEquipArrange(cb)
    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('NoDragToTempBag'))
        return false
    end

    if not self:CheckItemTypeFitInContainerType(self._DraggingItemData.ItemType, self._FocusContainerType) then
        return false
    end

    local isEquipped = self._DraggingItemOwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock and
            self._DraggingItemOwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock
    local isTargetEquip = self._FocusContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock
    local isTempBag = self._DraggingItemOwnerContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock

    -- 获取存在的被交换的道具的类型，用于音效播放
    local item
    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock then
        item = self._Model.CurAdventureData:GetItemInBagByIndex(self._FocusContainerIndex)
    elseif self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock then
        item = self._Model.CurAdventureData:GetItemInRuneListByIndex(self._FocusContainerIndex)
    end
    local targetItemType = nil

    if item then
        targetItemType = item.ItemType
    end

    -- 如果是从装备栏上拖到背包，需要判断背包中被交换的物品是否能放到该装备栏上
    if isEquipped and not isTargetEquip then
        -- 判断背包指定位置是否有物品
        if item then
            if not self:CheckItemTypeFitInContainerType(item.ItemType, self._DraggingItemOwnerContainerType) then
                return false
            end
        end
    end

    -- 如果是强化锤，则不能拖到其他背包
    if self._DraggingItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Hammer then
        if self._FocusContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock and
                self._FocusContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock
        then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText("HammerDragFail"))
            return false
        end
    end
    if targetItemType == XMVCA.XTheatre5.EnumConst.ItemType.Hammer then
        if isEquipped then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText("HammerDragFail"))
            return false
        end
    end

    self:SendItemSwitch(self._DraggingItemData.InstanceId, self._DraggingItemData.ItemType, isEquipped,
            self._DraggingItemBelongIndex, isTempBag, isTargetEquip, self._FocusContainerIndex, cb, targetItemType)

    return true
end

--- 判断物品类型和装备栏类型是否一致
function XTheatre5ShopControl:CheckItemTypeFitInContainerType(itemType, containerType, notips)
    if containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock and itemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then

        if not notips then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('RuneToSkillContainerTips'))
        end

        return false
    end

    if containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock and itemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then

        if not notips then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('SkillToRuneContainerTips'))
        end

        return false
    end

    return true
end

---@param itemData XTheatre5Item
function XTheatre5ShopControl:EquipItem(itemData)
    if itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        if not self._Model.CurAdventureData:CheckHasEmptySkillSlot() then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('DressItemFieldIsFull'))
            return
        end
    elseif itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        if not self._Model.CurAdventureData:CheckHasEmptyRuneSlot() then
            XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('DressItemFieldIsFull'))
            return
        end
    end

    local index = self._Model.CurAdventureData:GetItemIndexInBag(itemData)
    if index then
        local indexToEquip
        if itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
            indexToEquip = self._Model.CurAdventureData:GetEmptyBagSkillIndex()
        elseif itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
            indexToEquip = self._Model.CurAdventureData:GetEmptyBagRuneIndex()
        end
        self:SendItemSwitch(itemData.InstanceId, itemData.ItemType, false, index, false, true, indexToEquip)
    else
        XLog.Error('[XTheatre5ShopControl:EquipItem] itemData not found')
    end
end

function XTheatre5ShopControl:UndressItem(itemData)
    -- 背包已满要提示
    if not self._Model.CurAdventureData:CheckHasEmptyBagSlot() then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('RemoveItemBagIsFull'))
        return
    end

    local index
    if itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        index = self._Model.CurAdventureData:GetSkillIndexInSkillBag(itemData)
    elseif itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        index = self._Model.CurAdventureData:GetRuneIndexInRuneBag(itemData)
    end
    if index then
        local indexToUndress = self._Model.CurAdventureData:GetEmptyBagIndex() or 1
        self:SendItemSwitch(itemData.InstanceId, itemData.ItemType, true, index, false, false, indexToUndress)
    else
        XLog.Error("[XTheatre5ShopControl:UndressItem] index is nil")
    end
end

--发生物品交换协议
function XTheatre5ShopControl:SendItemSwitch(instanceId, itemType, srcEquipped, srcIndex, srcIsTempItem, targetEquipped, targetIndex, cb, targetItemType)
    XMVCA.XTheatre5:RequestTheatre5BagItemMove(instanceId, itemType, srcEquipped, srcIndex, srcIsTempItem, targetEquipped, targetIndex, function(success)
        if success then
            self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW)
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW)
            self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_SKILL_SHOW)
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_EQUIP_SHOW)

            self:PlayItemPlacedSFX(itemType)

            if targetItemType then
                self:PlayItemPlacedSFX(targetItemType)
            end
        end

        if cb then
            cb()
        end
    end)
end

function XTheatre5ShopControl:_EndDragForSkillChoice(cb)
    if not self._DraggingItemData then
        return
    end

    -- 判断位置是否对
    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock and self._DraggingItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('RuneToSkillContainerTips'))
        return false
    end

    if self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock and self._DraggingItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        XUiManager.TipMsg(self._Model:GetTheatre5ClientConfigText('SkillToRuneContainerTips'))
        return false
    end

    -- 判断拖拽位置是否已经有物品了
    if self._Model.CurAdventureData:CheckHasItemByContainerTypeAndIndex(self._FocusContainerType, self._FocusContainerIndex) then
        XUiManager.TipMsg(self:GetShopBuyBagContainerIndexIsFullTips(self._FocusContainerType))
        return false
    end

    local isTargetEquip = self._FocusContainerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock

    XMVCA.XTheatre5:RequestTheatre5SkillChoice(self._DraggingItemData.InstanceId, isTargetEquip, self._FocusContainerIndex, function(success)
        if success then
            self:RefreshAfterBuyRequest()
            self:PlayItemPlacedSFX(XMVCA.XTheatre5.EnumConst.ItemType.Skill)
        end

        -- 请求完数据会立刻清除，需要客户端手动标记选择用于表现
        if self._DraggingItemData then
            self._DraggingItemData.IsSelected = true
        end

        if cb then
            cb()
        end
        self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SKILL_CHOICE_END)


        -- todo：初始化会稍微花点时间，后续看看播动画回调里刷新，现在先隔帧刷新不影响拖拽效果
        XScheduleManager.ScheduleNextFrame(function()
            self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_STATE_CHANGED, true)
        end)
    end)

    return true
end
--endregion

function XTheatre5ShopControl:RefreshAfterBuyRequest()
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_SKILL_SHOW)
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_EQUIP_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_BUY)
end

function XTheatre5ShopControl:RefreshAfterSellRequest()
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW)
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_SKILL_SHOW)
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_EQUIP_SHOW)
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_SELL)
end

function XTheatre5ShopControl:RefreshAfterFreezeRequest()
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW)
end

function XTheatre5ShopControl:RefreshAfterRefreshRequest()
    --- 参数1表示是否是刷新商店商品
    self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, true)
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW)
end

---@return XTableTheatre5ShopNpcChat
function XTheatre5ShopControl:GetShopChatCfg(shopChatTriggerType)
    local shopCfg = self:GetCurShopCfg()
    if not shopCfg or not XTool.IsNumberValid(shopCfg.ShopNpcId) then
        return
    end
    local shopNpcCfg = self._Model:GetTheatre5ShopNpcCfg(shopCfg.ShopNpcId)
    if not shopNpcCfg then
        return
    end
    local shopChatGroupId
    if shopChatTriggerType == XMVCA.XTheatre5.EnumConst.ShopNpcTriggerChatType.Click then
        shopChatGroupId = shopNpcCfg.TouchChatGroup
    elseif shopChatTriggerType == XMVCA.XTheatre5.EnumConst.ShopNpcTriggerChatType.Buy then
        shopChatGroupId = shopNpcCfg.BuyChatGroup
    elseif shopChatTriggerType == XMVCA.XTheatre5.EnumConst.ShopNpcTriggerChatType.Sell then
        shopChatGroupId = shopNpcCfg.SellChatGroup
    end
    local shopChatCfgs = self._Model:GetTheatre5ShopChatCfgs(shopChatGroupId)
    if XTool.IsTableEmpty(shopChatCfgs) then
        return
    end
    local showShopChatCfg = {}
    local weighTotal = 0
    for k, cfg in pairs(shopChatCfgs) do
        if XConditionManager.CheckConditionAndDefaultPass(cfg.Condition) then
            weighTotal = weighTotal + cfg.Weigh
            table.insert(showShopChatCfg, cfg)
        end
    end
    if weighTotal <= 0 then
        return
    end
    local random = math.random(1, weighTotal)
    local curAdd = 0
    for _, cfg in ipairs(showShopChatCfg) do
        curAdd = curAdd + cfg.Weigh
        if curAdd >= random then
            return cfg
        end
    end

end

function XTheatre5ShopControl:GetTempBagGrids()
    return self._Model.CurAdventureData:GetTempBagGrids()
end

function XTheatre5ShopControl:HasTempBagGrid()
    return self._Model.CurAdventureData:HasTempBagGrid()
end

--获得一个背包的空位索引
function XTheatre5ShopControl:GetEmptyBagIndex()
    return self._Model.CurAdventureData:GetEmptyBagIndex()
end

--获得一个技能的空位索引
function XTheatre5ShopControl:GetEmptyBagSkillIndex()
    return self._Model.CurAdventureData:GetEmptyBagSkillIndex()
end

--获得一个装备(宝珠)的空位索引
function XTheatre5ShopControl:GetEmptyBagRuneIndex()
    return self._Model.CurAdventureData:GetEmptyBagRuneIndex()
end

--- 判断装备栏是否有空位
function XTheatre5ShopControl:CheckHasEmptyRuneSlot()
    return self._Model.CurAdventureData:CheckHasEmptyRuneSlot()
end

--- 判断技能栏是否有空位
function XTheatre5ShopControl:CheckHasEmptySkillSlot()
    return self._Model.CurAdventureData:CheckHasEmptySkillSlot()
end

--- 播放物品放置（购买、穿戴）音效
function XTheatre5ShopControl:PlayItemPlacedSFX(itemType)
    if itemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ITEM_SKILL_PLACED)
    elseif itemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        self._MainControl:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ITEM_GEM_PLACED)
    end
end

--region 杂项表

--- 获取拖拽界限值
function XTheatre5ShopControl:GetTheatre5ItemDragLimitFromClientConfig()
    return self._Model:GetTheatre5ClientConfigNum('ItemDragLimit')
end

--- 获取解锁槽位提示文本
function XTheatre5ShopControl:GetTheatre5NewGemSlotUnlockTipsFromClientConfig()
    return self._Model:GetTheatre5ClientConfigText('NewGemSlotUnlockTips')
end

--- 获取解锁槽位失败文本-金币不足
function XTheatre5ShopControl:GetTheatre5GemSlotUnlockLackGoldErrorFromClientConfig()
    return self._Model:GetTheatre5ClientConfigText('GemSlotUnlockLackGoldError')
end

--endregion

---@param itemData XTheatre5Item
function XTheatre5ShopControl:CheckRuneValid(itemData)
    local runeDict = self._Model.CurAdventureData:GetRuneDict()
    if not runeDict then
        XLog.Error("[XTheatre5ShopControl] 符文背包为空？")
        return true
    end
    local isValid = true
    local config = self._Model:GetTheatre5ItemCfgById(itemData.ItemId)
    local buffType = config.BuffType
    if buffType > 0 then
        -- 筛选同类buff里最高级的第一个符文
        local bestQuality
        local bestIndex
        for i, runeData in pairs(runeDict) do
            local configRune = self._Model:GetTheatre5ItemCfgById(runeData.ItemId)
            if configRune.BuffType == buffType then
                if not bestQuality or bestQuality < configRune.Quality then
                    bestQuality = configRune.Quality
                    bestIndex = i
                elseif bestQuality == configRune.Quality then
                    if not bestIndex or i < bestIndex then
                        bestIndex = i
                    end
                end
            end
        end
        local thisIndex
        for i, runeData in pairs(runeDict) do
            if itemData.InstanceId == runeData.InstanceId then
                thisIndex = i
            end
        end
        if bestIndex and thisIndex and bestIndex ~= thisIndex then
            isValid = false
        end
    end
    return isValid
end

function XTheatre5ShopControl:GetShopRefreshCost()
    local adventureData = self._Model.CurAdventureData
    if adventureData then
        local freeRefreshCnt = adventureData:GetEffectFreeRefreshCnt()
        if freeRefreshCnt then
            if freeRefreshCnt > 0 then
                return 0
            end
        end
    end

    local curRefreshCfg = self:GetCurShopRefreshCntCostCfg()
    return curRefreshCfg.GoldCost
end

--- 获取背包容量
function XTheatre5ShopControl:GetStrengthenRate()
    return self._Model:GetTheatre5ConfigValByKey("StrengthenRate")
end

return XTheatre5ShopControl