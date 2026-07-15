---@class XFashionSuitAgency : XAgency
---@field private _Model XFashionSuitModel
local XFashionSuitAgency = XClass(XAgency, "XFashionSuitAgency")

function XFashionSuitAgency:OnInit()
    --初始化一些变量
end

function XFashionSuitAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XFashionSuitAgency:InitEvent()
    
end

----------public start----------

--region 涂装套装

function XFashionSuitAgency:SetFashionSuitData(fashionSuitList)
    self._Model:SetFashionSuitData(fashionSuitList)
end

function XFashionSuitAgency:OpenMain()
    local config = self._Model:GetClientConfigById("CloseGuideGroupId")
    local guideGroupIds = config and config.Values
    local needCloseIds = {}

    if not XTool.IsTableEmpty(guideGroupIds) then
        for _, idStr in ipairs(guideGroupIds) do
            local id = tonumber(idStr)
            if not XDataCenter.GuideManager.CheckIsGuide(id) then
                table.insert(needCloseIds, id)
            end
        end
    end

    if #needCloseIds > 0 then
        --玩家主动进入套装界面后，强制完成指定ID的强引导
        XDataCenter.GuideManager.ReqMultiGuideComplete(needCloseIds, function()
            XLuaUiManager.Open("UiFashionSuitLobby")
        end)
    else
        XLuaUiManager.Open("UiFashionSuitLobby")
    end
end

function XFashionSuitAgency:IsRed()
    --功能未开启
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionSuit) then
        return false
    end
    --涂装上新、全收集奖励未领取
    local configs = self._Model:GetFashionSuitConfigs()
    for _, config in pairs(configs) do
        local ownCount = 0
        for _, fashionId in pairs(config.FashionIds) do
            if not self._Model:IsFashionViewed(fashionId) then
                return true
            end
            if XDataCenter.FashionManager.CheckHasFashion(fashionId) then
                ownCount = ownCount + 1
            end
        end
        if config.IsComplete and ownCount == #config.FashionIds and not self._Model:IsSuitRewardGain(config.Id) then
            return true
        end
    end
    return false
end

function XFashionSuitAgency:GetFashionSuitId(fashionId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionSuit) then
        return nil
    end
    --如果传进来的是武器涂装Id，则尝试通过FashionGroup表找到对应的角色涂装Id
    if XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        local fashionGroup = self:GetFashionGroupByFashionId(fashionId)
        if not fashionGroup then
            return nil
        end
        fashionId = fashionGroup.FashionId
    end
    local configs = self._Model:GetFashionSuitConfigs()
    for _, cfg in pairs(configs) do
        if table.contains(cfg.FashionIds, fashionId) then
            return cfg.Id
        end
    end
    return nil
end

function XFashionSuitAgency:CheckFashionShopOpen(suitId, cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
        if cb then
            cb()
        end
        return
    end
    local shopIds = self._Model:GetSuitShopIds(suitId)
    if XTool.IsTableEmpty(shopIds) then
        if cb then
            cb()
        end
    else
        XShopManager.RequestShopValidInfo(shopIds, cb)
    end
end

function XFashionSuitAgency:GetSuitShopIds(suitId)
    return self._Model:GetSuitShopIds(suitId)
end

function XFashionSuitAgency:IsFashionViewed(fashionId)
    if not fashionId or XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        return false
    end
    return self._Model:IsFashionViewed(fashionId)
end

--endregion

--region 涂装组合

---根据涂装Id获取涂装组配置
---@param fashionId number 角色涂装Id、武器涂装Id
---@return XTableFashionGroup
function XFashionSuitAgency:GetFashionGroupByFashionId(fashionId)
    return self._Model:GetFashionGroupByFashionId(fashionId)
end

---显示涂装组合购买弹框
function XFashionSuitAgency:ShowGroupSalesPopup(ids, consumeId, consumeCount, sureCb)
    local itemName
    if #ids > 1 then
        itemName = XUiHelper.GetText("FashionGroupSalesPopupItem3")
    elseif XWeaponFashionConfigs.IsWeaponFashion(ids[1]) then
        itemName = XUiHelper.GetText("FashionGroupSalesPopupItem2")
    else
        itemName = XUiHelper.GetText("FashionGroupSalesPopupItem1")
    end
    local consumeName = XDataCenter.ItemManager.GetItemName(consumeId)
    local content = XUiHelper.GetText("FashionGroupSalesPopupTitle", consumeCount, consumeName, itemName)
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, XUiManager.DialogType.Normal, nil, sureCb)
end

---获取套装涉及到的商店Id
function XFashionSuitAgency:GetGroupSalesShopIds(fashionId)
    if not self._Model:IsSupportGroupSales(fashionId) then
        return nil
    end
    local config = self:GetFashionGroupByFashionId(fashionId)
    if config.GainType ~= XEnumConst.FashionSuit.GainType.Shop then
        return nil
    end
    return { config.FashionGainParams[1], config.WeaponFashionGainParams[1] }    
end

---该套装是否允许整套购买
function XFashionSuitAgency:IsAllowGroupSales(fashionId)
    return self._Model:IsAllowGroupSales(fashionId)
end

---自选礼包点涂装详情前置位，XUiFashionDetail 打开时消费
function XFashionSuitAgency:SetFromSelfChoicePack(value)
    self._FromSelfChoicePack = value
end

---读取并消费"是否来自自选礼包"标记
function XFashionSuitAgency:ConsumeFromSelfChoicePack()
    local value = self._FromSelfChoicePack
    self._FromSelfChoicePack = false
    return value
end

function XFashionSuitAgency:GetGroupIdByFashion(fashionId)
    return self._Model:GetGroupIdByFashion(fashionId)
end

---穿戴多件涂装
---@param fashionIds number[] 角色涂装、武器涂装
function XFashionSuitAgency:RecursionUseFashion(characterId, fashionIds, successCb)
    if XTool.IsTableEmpty(fashionIds) then
        if successCb then
            successCb()
        end
        return
    end

    local index, count = 1, #fashionIds
    local function nextStep()
        if index > count then
            if successCb then
                successCb()
            end
            return
        end

        local fashionId = fashionIds[index]
        index = index + 1

        self:UseFashion(characterId, fashionId, nextStep)
    end

    nextStep()
end

---穿戴涂装
function XFashionSuitAgency:UseFashion(characterId, fashionId, cb)
    if XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        XDataCenter.WeaponFashionManager.UseFashion(fashionId, characterId, cb)
    else
        XDataCenter.FashionManager.UseFashion(fashionId, cb)
    end
end

---将涂装加入随机涂装
function XFashionSuitAgency:JoinFashionToRandom(characterId, fashionId, weaponFashionId, successCb)
    if not fashionId and weaponFashionId then
        --武器涂装加入随机涂装
        XLuaUiManager.Open("UiFashionRandom", characterId)
        return
    end

    local activeList = {}
    local bindWeaponFashionDic = {}
    local dataList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(characterId)
    for k, fashionId in pairs(dataList) do
        local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
        if fashionData then
            bindWeaponFashionDic[fashionId] = fashionData.WeaponFashionId
            if fashionData.IsRandom then
                table.insert(activeList, fashionId)
            end
        end
    end

    --角色涂装加入随机涂装
    table.insert(activeList, fashionId)
    if weaponFashionId then
        --角色涂装、武器涂装加入随机涂装
        bindWeaponFashionDic[fashionId] = weaponFashionId
    end
    
    XDataCenter.FashionManager.FashionSuitPoolSaveRequest(characterId, bindWeaponFashionDic, activeList, function()
        if successCb then
            successCb()
        end
    end)
end

---是否加入随机涂装
function XFashionSuitAgency:IsRandom(fashionId, weaponFashionId)
    if fashionId and not XDataCenter.FashionManager.IsFashionRandom(fashionId) then
        return false
    end
    if weaponFashionId and not XDataCenter.FashionManager.IsWeaponFashionRandom(weaponFashionId) then
        return false
    end
    return true
end

---涂装是否已穿戴
function XFashionSuitAgency:IsDressed(fashionId, weaponFashionId, characterId)
    if fashionId and not self:IsFashionDressed(fashionId) then
        return false
    end
    if weaponFashionId and not self:IsWeaponFashionDressed(weaponFashionId, characterId) then
        return false
    end
    return true
end

---是否穿戴了角色涂装
function XFashionSuitAgency:IsFashionDressed(id)
    local status = XDataCenter.FashionManager.GetFashionStatus(id)
    return status == XDataCenter.FashionManager.FashionStatus.Dressed
end

---是否穿戴了武器涂装
function XFashionSuitAgency:IsWeaponFashionDressed(id, characterId)
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(id, characterId)
    return status == XDataCenter.WeaponFashionManager.FashionStatus.Dressed
end

---总礼包价格
function XFashionSuitAgency:PurchaseConsumeCount(itemDataList)
    local count = 0
    for _, itemData in ipairs(itemDataList) do
        count = count + (itemData.ConsumeCount or 0)
    end
    return count
end

---总礼包折扣价格
function XFashionSuitAgency:PurchaseConvertSwitch(itemDataList)
    local count = 0
    for _, itemData in ipairs(itemDataList) do
        count = count + (itemData.ConvertSwitch or 0)
    end
    return count
end

---获取最终需要支付的礼包价格
function XFashionSuitAgency:GetRealPurchasePriceWithDiscount(itemDataList)
    local _, itemData = next(itemDataList)
    local tag = itemData.Tag
    local isDisCount = false
    local consumeCount = self:PurchaseConsumeCount(itemDataList)
    local convertSwitch = self:PurchaseConvertSwitch(itemDataList)
    local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(itemData)

    if tag > 0 and XPurchaseConfigs.GetTagType(tag) == XPurchaseConfigs.PurchaseTagType.Discount then
        isDisCount = disCountValue < 1
    end

    if consumeCount == 0 then
        return 0 --免费
    elseif isDisCount or convertSwitch < consumeCount then
        if convertSwitch <= 0 then
            return -1 --无需购买
        else
            local consumeNum = consumeCount
            if convertSwitch > 0 and convertSwitch < consumeCount then
                consumeNum = convertSwitch
            end
            if isDisCount then
                consumeNum = math.modf(disCountValue * consumeNum) or ""
            end
            return consumeNum, consumeCount --打折
        end
    else
        return consumeCount --无折扣
    end
end

---货币不足跳转
function XFashionSuitAgency:OnMoneyNotEnough(skipIndex, leftTabIndex, payCount)
    if leftTabIndex == nil then
        leftTabIndex = 1
    end
    if skipIndex == XPurchaseConfigs.TabsConfig.Pay and XHeroSdkManager.IsPayEnable() then
        if payCount then
            XLuaUiManager.Open("UiPurchaseQuickBuy", payCount, function(index)
                XLuaUiManager.SafeClose("UiPurchaseQuickBuy")
                -- 把UiPurchase从UiFashionSuitDetail底下 移动到它上面 避免被挡住
                if XLuaUiManager.IsUiLoad("UiPurchase") then
                    XLuaUiManager.Remove("UiPurchase")
                end
                XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay, false, index)
            end)
        end
    else
        XLuaUiManager.Open("UiPurchase", skipIndex)
    end
end

---通过礼包购买涂装组合
function XFashionSuitAgency:PurchaseBuyFashionGroup(fashionGroupId, cb)
    --过滤需要购买的礼包
    local packageItems, packageIds, itemIds = {}, {}, {}
    local dict = self:GetGroupNeedToBuyInfo(fashionGroupId)
    for itemId, params in pairs(dict) do
        table.insert(itemIds, itemId)
        table.insert(packageIds, params[1])
    end
    for _, id in pairs(packageIds) do
        local item = XDataCenter.PurchaseManager.GetPurchaseDataById(id)
        if item then
            table.insert(packageItems, item)
        end
    end
    if XTool.IsTableEmpty(packageItems) then
        XLog.Error(string.format("购买失败，商店数据不存在或者已全部购买：%s", fashionGroupId))
        return
    end
    --检查购买条件
    if not self:CheckPurchaseGroupBuy(packageItems) then
        return
    end
    --涂装组合购买专属确认弹窗
    local packageData = packageItems[1]
    local price = self:GetRealPurchasePriceWithDiscount(packageItems)
    self:ShowGroupSalesPopup(itemIds, packageData.ConsumeId, price, function()
        --批量购买
        XDataCenter.PurchaseManager.MultiPurchaseRequest(packageIds, XPurchaseConfigs.GetLBUiTypesList(), function(rewardList)
            if cb then
                cb(rewardList)
            end
        end)
    end)
end

---检查来自礼包的套装组合是否可购买
---@param itemDataList table 礼包组
function XFashionSuitAgency:CheckPurchaseGroupBuy(itemDataList)
    if XTool.IsTableEmpty(itemDataList) then
        return false
    end

    local convertSwitch = self:PurchaseConvertSwitch(itemDataList)
    local consumeCount = self:PurchaseConsumeCount(itemDataList)

    local itemData = itemDataList[1]
    if itemData.BuyLimitTimes > 0 and itemData.BuyTimes == itemData.BuyLimitTimes then
        --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return false
    end

    if itemData.TimeToShelve > 0 and itemData.TimeToShelve > XTime.GetServerNowTimestamp() then
        --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return false
    end

    if itemData.TimeToUnShelve > 0 and itemData.TimeToUnShelve < XTime.GetServerNowTimestamp() then
        --下架了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if itemData.TimeToInvalid > 0 and itemData.TimeToInvalid < XTime.GetServerNowTimestamp() then
        --失效了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if consumeCount > 0 and convertSwitch <= 0 then
        -- 礼包内容全部拥有
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return false
    end

    if consumeCount > convertSwitch then
        -- 已经被服务器计算了抵扣和折扣后的钱
        consumeCount = convertSwitch
    end

    if XPurchaseConfigs.GetTagType(itemData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then
        -- 计算打折后的钱(普通打折或者选择了打折券)
        local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(itemData)
        consumeCount = math.floor(disCountValue * consumeCount)
    end

    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(itemData.ConsumeId) then
        --钱不够
        local tips = XUiHelper.GetCountNotEnoughTips(itemData.ConsumeId)
        XUiManager.TipMsg(tips, XUiManager.UiTipType.Wrong)
        if itemData.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            self:OnMoneyNotEnough(XPurchaseConfigs.TabsConfig.HK)
        elseif itemData.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            local payCount = consumeCount - XDataCenter.ItemManager.GetCount(itemData.ConsumeId)
            self:OnMoneyNotEnough(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end
        return false
    end

    return true
end

---获取涂装组合中还未购买的涂装的信息
function XFashionSuitAgency:GetGroupNeedToBuyInfo(fashionGroupId)
    local dict = {}
    local fashionGroup = self._Model:GetFashionGroupById(fashionGroupId)
    local hasFashion = XDataCenter.FashionManager.CheckHasFashion(fashionGroup.FashionId) and XDataCenter.FashionManager.IsFashionInTime(fashionGroup.FashionId)
    local hasWeaponFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(fashionGroup.WeaponFashionId) and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(fashionGroup.WeaponFashionId)
    local gainType = fashionGroup.GainType
    if not hasFashion then
        dict[fashionGroup.FashionId] = fashionGroup.FashionGainParams
    end
    if not hasWeaponFashion then
        dict[fashionGroup.WeaponFashionId] = fashionGroup.WeaponFashionGainParams
    end
    return dict
end

---通过商店购买涂装组合
function XFashionSuitAgency:ShopBuyFashionGroup(fashionGroupId, cb)
    --过滤需要购买的礼包
    local goodsDataDict, goodsIds, itemIds = {}, {}, {}
    local dict = self:GetGroupNeedToBuyInfo(fashionGroupId)
    for itemId, params in pairs(dict) do
        local shopId, goodsId = params[1], params[2]
        local data = XShopManager.GetShopGoodsInfo(shopId, goodsId)
        goodsDataDict[data] = shopId
        table.insert(itemIds, itemId)
        table.insert(goodsIds, goodsId)
    end
    if XTool.IsTableEmpty(goodsDataDict) then
        XLog.Error(string.format("购买失败，商店数据不存在或者已全部购买：%s", fashionGroupId))
        return
    end
    --检查购买条件
    local goodsData, shopId = next(goodsDataDict)
    local consumeId = goodsData.ConsumeList[1].Id
    local price = self:GetRealGoodsPriceWithDiscount(goodsDataDict)
    if not self:CheckShopGoodsBuy(consumeId, price) then
        return
    end
    --涂装组合购买专属确认弹窗
    self:ShowGroupSalesPopup(itemIds, consumeId, price, function()
        --批量购买
        local activityOpen, _ = self:GetDiscountActivityIsOpen(shopId, goodsData)
        local shopIds, goodsIds = {}, {}
        for data, shopId in pairs(goodsDataDict) do
            table.insert(shopIds, shopId)
            table.insert(goodsIds, data.Id)
        end
        XShopManager.MultiBuyShop(shopIds, goodsIds, function(goodList)
            if cb then
                cb(goodList)
            end
        end, nil, activityOpen)
    end)
end

---检查来自商店的套装组合是否可购买
function XFashionSuitAgency:CheckShopGoodsBuy(consumeId, price)
    local result = XDataCenter.ItemManager.CheckItemCountById(consumeId, price)
    if not result and consumeId == XDataCenter.ItemManager.ItemId.HongKa then
        local tips = XUiHelper.GetCountNotEnoughTips(consumeId)
        XUiManager.TipMsg(tips, XUiManager.UiTipType.Wrong)
        local payCount = price - XDataCenter.ItemManager.GetCount(consumeId)
        self:OnMoneyNotEnough(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        return false
    elseif not result and consumeId == XDataCenter.ItemManager.ItemId.PaidGem then
        XUiManager.TipText("ShopItemPaidGemNotEnough")
        self:OnMoneyNotEnough(XPurchaseConfigs.TabsConfig.HK)
        return false
    end
    return true
end

---V4.2商店打折
function XFashionSuitAgency:GetDiscountActivityIsOpen(shopId, goodsData)
    if not XShopManager.IsShopOpen(shopId) or not XShopManager.GetShopActivityIsOpen(shopId) then
        return false, nil
    end
    return XShopManager.GetShopActivityIsOpen(shopId), goodsData.ActivityConsumeCount
end

---商品总价
function XFashionSuitAgency:GoodsConsumeCount(goodsDataDict)
    local count = 0
    for data in pairs(goodsDataDict) do
        count = count + data.ConsumeList[1].Count
    end
    return count
end

---获取最终需要支付的商品价格
---@param goodsDataDict table<number,table> [key]=商品信息 [value]=商店Id
function XFashionSuitAgency:GetRealGoodsPriceWithDiscount(goodsDataDict)
    local goodsData, shopId = next(goodsDataDict) --套装组里 商品的折扣都是一样的 拿其中一个就行
    local consumeCount = self:GoodsConsumeCount(goodsDataDict)
    local activityOpen, needCount = self:GetDiscountActivityIsOpen(shopId, goodsData)
    if activityOpen then
        return needCount
    else
        local sales = self:GetShopGoodsSale(shopId, goodsData)
        return math.floor(consumeCount * sales / 100)
    end
end

---获取商品折扣
function XFashionSuitAgency:GetShopGoodsSale(shopId, goodsData)
    local onSales = {}
    local sales = 100
    local activityOpen, needCount = self:GetDiscountActivityIsOpen(shopId, goodsData)

    XTool.LoopMap(goodsData.OnSales, function(k, sales)
        onSales[k] = sales
    end)

    if not XTool.IsTableEmpty(onSales) then
        local sortedKeys = {}
        for k, _ in pairs(onSales) do
            table.insert(sortedKeys, k)
        end
        table.sort(sortedKeys)
        for i = 1, #sortedKeys do
            if goodsData.TotalBuyTimes >= sortedKeys[i] - 1 then
                sales = onSales[sortedKeys[i]]
            end
        end
    end
    if activityOpen then
        sales = goodsData.ActivityDiscount
    end
    return sales
end

--endregion

----------public end----------

----------private start----------


----------private end----------

return XFashionSuitAgency