---@class XPartnerUtil 静态工具类（尽量无状态纯函数；不反向读写模块数据）
local XPartnerUtil = XClass(nil, "XPartnerUtil")

--region 品质映射

--- 将辅助机养成品质映射为通用格子使用的物品质量枚举
---@param partnerQuality number 辅助机养成品质（B/A/S/SS/SSS/SSS+）
---@return number goodsQuality 通用格子物品质量枚举（五星/六星）
function XPartnerUtil.GetGoodsQualityByPartnerQuality(partnerQuality)
    return partnerQuality < 3 and XGoodsCommonManager.QualityType.Gold or XGoodsCommonManager.QualityType.Red
end

--endregion

--region 技能

--- 辅助机是否已装满技能（主动技 1 个 + 当前品质已解锁的被动技能槽）
---@param partner XPartner
---@return boolean
function XPartnerUtil.IsSkillSlotFull(partner)
    if not partner then
        return false
    end

    local carryMainList = partner:GetCarryMainSkillGroupList()
    if not carryMainList or #carryMainList < 1 then
        return false
    end

    local carryPassiveList = partner:GetCarryPassiveSkillGroupList()
    local carryPassiveCount = carryPassiveList and #carryPassiveList or 0
    return carryPassiveCount >= partner:GetQualitySkillColumnCount()
end

--endregion

--region 碎片/矿石兑换

--- 某碎片当前持有数量
---@param chipItemId number 碎片道具Id
---@return number
function XPartnerUtil.GetChipHaveCount(chipItemId)
    if not XTool.IsNumberValid(chipItemId) then
        return 0
    end
    return XDataCenter.ItemManager.GetCount(chipItemId)
end

--- 某碎片的矿石兑换路线（取第一条兑换路线，多返回值避免建表）
---@param chipItemId number 碎片道具Id
---@return number|nil shopId 商店Id（无有效兑换路线时返回 nil）
---@return number|nil goodsId 商品Id
---@return number|nil gainCount 单次兑换获得的碎片数
---@return number|nil consumeId 消耗的矿石道具Id
---@return number|nil consumeCount 当前单次兑换消耗的矿石数
function XPartnerUtil.GetChipOreExchangeRoute(chipItemId)
    if not XTool.IsNumberValid(chipItemId) then
        return nil
    end
    local exchangeInfo = XDataCenter.ItemManager.GetItemAutoExchangeInfo(chipItemId)
    if not exchangeInfo then
        return nil
    end

    local gainCount = exchangeInfo.RewardCountList[1] or 0
    local consume = exchangeInfo.ConsumeList[1] and exchangeInfo.ConsumeList[1][1]
    local consumeCount = consume and consume.ConsumeCount or 0
    if gainCount <= 0 or not consume or not XTool.IsNumberValid(consumeCount) then
        return nil
    end
    return exchangeInfo.ShopIdList[1], exchangeInfo.GoodsIdList[1], gainCount, consume.ConsumeId, consumeCount
end

--- 某碎片当前可被矿石兑换出的权威数量及总消耗
---@param chipItemId number 碎片道具Id
---@return number chipCount
---@return number consumeCount
function XPartnerUtil.GetOreExchangeChipCount(chipItemId)
    local shopId, goodsId = XPartnerUtil.GetChipOreExchangeRoute(chipItemId)
    if not shopId or not goodsId then
        return 0, 0
    end

    local goods = XShopManager.GetShopGoodsInfo(shopId, goodsId)
    if not goods then
        return 0, 0
    end

    local consume = goods.ConsumeList and goods.ConsumeList[1]
    local rewardGoods = goods.RewardGoods
    if not consume or not rewardGoods or rewardGoods.TemplateId ~= chipItemId
            or not XTool.IsNumberValid(consume.Count) or not XTool.IsNumberValid(rewardGoods.Count) then
        return 0, 0
    end

    local maxBuyTimes
    if XTool.IsNumberValid(goods.BuyTimesLimit) then
        maxBuyTimes = math.max(0, goods.BuyTimesLimit - (goods.TotalBuyTimes or 0))
    end
    local shopLeftBuyTimes = XShopManager.GetShopLeftBuyTimes(shopId)
    if shopLeftBuyTimes then
        maxBuyTimes = maxBuyTimes and math.min(maxBuyTimes, shopLeftBuyTimes) or shopLeftBuyTimes
    end

    local onSales = {}
    local sortedSalesKeys = {}
    XTool.LoopMap(goods.OnSales, function(salesBuyTimes, sales)
        onSales[salesBuyTimes] = sales
        table.insert(sortedSalesKeys, salesBuyTimes)
    end)
    table.sort(sortedSalesKeys)

    local totalBuyTimes = goods.TotalBuyTimes or 0
    local leftOreCount = XDataCenter.ItemManager.GetCount(consume.Id)
    local buyTimes = 0.0
    local consumeCount = 0.0

    while not maxBuyTimes or buyTimes < maxBuyTimes do
        local currentTotalBuyTimes = totalBuyTimes + buyTimes
        local sales = goods.Sales or 100
        local segmentLeftTimes = math.huge
        for _, salesBuyTimes in ipairs(sortedSalesKeys) do
            if currentTotalBuyTimes < salesBuyTimes - 1 then
                segmentLeftTimes = salesBuyTimes - currentTotalBuyTimes - 1
                break
            end
            sales = onSales[salesBuyTimes] or sales
        end

        local oneConsumeCount = math.floor(consume.Count * sales / 100)
        if oneConsumeCount <= 0 then
            break
        end

        local segmentBuyTimes = math.floor(leftOreCount / oneConsumeCount) + 0.0
        segmentBuyTimes = math.min(segmentBuyTimes, segmentLeftTimes)
        if maxBuyTimes then
            segmentBuyTimes = math.min(segmentBuyTimes, maxBuyTimes - buyTimes)
        end
        if segmentBuyTimes <= 0 then
            break
        end

        local segmentConsumeCount = segmentBuyTimes * oneConsumeCount
        buyTimes = buyTimes + segmentBuyTimes
        consumeCount = consumeCount + segmentConsumeCount
        leftOreCount = leftOreCount - segmentConsumeCount
    end

    return buyTimes * rewardGoods.Count, consumeCount
end


--- 获取目标碎片数对应的购买次数、实际碎片数和矿石消耗
---@param chipItemId number 碎片道具Id
---@param needChipCount number 目标碎片数
---@return number buyTimes
---@return number chipCount
---@return number|nil consumeId
---@return number consumeCount
function XPartnerUtil.GetOreExchangeChipCostByCount(chipItemId, needChipCount)
    if not XTool.IsNumberValid(needChipCount) then
        return 0, 0, nil, 0
    end

    local shopId, goodsId = XPartnerUtil.GetChipOreExchangeRoute(chipItemId)
    if not shopId or not goodsId then
        return 0, 0, nil, 0
    end

    local goods = XShopManager.GetShopGoodsInfo(shopId, goodsId)
    if not goods then
        return 0, 0, nil, 0
    end

    local consume = goods.ConsumeList and goods.ConsumeList[1]
    local rewardGoods = goods.RewardGoods
    if not consume or not rewardGoods or rewardGoods.TemplateId ~= chipItemId
            or not XTool.IsNumberValid(consume.Count) or not XTool.IsNumberValid(rewardGoods.Count) then
        return 0, 0, nil, 0
    end

    local maxBuyTimes = math.ceil(needChipCount / rewardGoods.Count)
    if XTool.IsNumberValid(goods.BuyTimesLimit) then
        maxBuyTimes = math.min(maxBuyTimes, math.max(0, goods.BuyTimesLimit - (goods.TotalBuyTimes or 0)))
    end
    local shopLeftBuyTimes = XShopManager.GetShopLeftBuyTimes(shopId)
    if shopLeftBuyTimes then
        maxBuyTimes = math.min(maxBuyTimes, shopLeftBuyTimes)
    end

    local onSales = {}
    local sortedSalesKeys = {}
    XTool.LoopMap(goods.OnSales, function(salesBuyTimes, sales)
        onSales[salesBuyTimes] = sales
        table.insert(sortedSalesKeys, salesBuyTimes)
    end)
    table.sort(sortedSalesKeys)

    local totalBuyTimes = goods.TotalBuyTimes or 0
    local leftOreCount = XDataCenter.ItemManager.GetCount(consume.Id)
    local buyTimes = 0.0
    local consumeCount = 0.0

    while buyTimes < maxBuyTimes do
        local currentTotalBuyTimes = totalBuyTimes + buyTimes
        local sales = goods.Sales or 100
        local segmentLeftTimes = math.huge
        for _, salesBuyTimes in ipairs(sortedSalesKeys) do
            if currentTotalBuyTimes < salesBuyTimes - 1 then
                segmentLeftTimes = salesBuyTimes - currentTotalBuyTimes - 1
                break
            end
            sales = onSales[salesBuyTimes] or sales
        end

        local oneConsumeCount = math.floor(consume.Count * sales / 100)
        if oneConsumeCount <= 0 then
            break
        end

        local segmentBuyTimes = math.min(math.floor(leftOreCount / oneConsumeCount), segmentLeftTimes,
            maxBuyTimes - buyTimes)
        if segmentBuyTimes <= 0 then
            break
        end

        local segmentConsumeCount = segmentBuyTimes * oneConsumeCount
        buyTimes = buyTimes + segmentBuyTimes
        consumeCount = consumeCount + segmentConsumeCount
        leftOreCount = leftOreCount - segmentConsumeCount
    end

    buyTimes = math.floor(buyTimes)
    local exchangeChipCount = math.floor(buyTimes * rewardGoods.Count)
    consumeCount = math.floor(consumeCount)
    return buyTimes, exchangeChipCount, consume.Id, consumeCount
end

--endregion

return XPartnerUtil
