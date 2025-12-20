local tableSort = table.sort
local mathFloor = math.floor
local pairs = pairs

---@class XAreaWarAuction
local XAreaWarAuction = XClass(nil, "XAreaWarAuction")

function XAreaWarAuction:Ctor()
    ---@type number 服务器拍卖行版本号
    self._Version = 0
    ---@type number 拍卖行缓存过期时间{时间戳秒}，在打开界面时动态刷新
    self._CacheExpire = 0
    ---@type table<number, XAreaWarAuctionItemPartition[]> 拍卖行道具对应数据
    self._ItemToPartitionsDic = {}
end

-- 刷新数据
function XAreaWarAuction:RefreshData(data)
    self._Version = data.Version
    self._CacheExpire = data.CacheExpire
    
    self._ItemToPartitionsDic = {}
    for _, itemData in pairs(data.AuctionItems) do
        self._ItemToPartitionsDic[itemData.ItemId] = itemData.Partitions -- 直接赋值缓存引用，不封装成类，减少内存开销
    end
end

-- 刷新交易行单个道具数据
function XAreaWarAuction:RefreshItemData(itemData)
    self._ItemToPartitionsDic[itemData.ItemId] = itemData.Partitions
end

-- 数据是否有效
function XAreaWarAuction:IsDataValid()
    local curTime = XTime.GetServerNowTimestamp()
    return curTime < self._CacheExpire
end

-- 交易行是否存在道具
function XAreaWarAuction:IsExitItem(itemId)
    local num = self:GetItemAllNum(itemId)
    return num > 0
end

-- 获取道具各个分区价格
function XAreaWarAuction:GetPartitions(itemId)
    return self._ItemToPartitionsDic[itemId]
end

-- 获取交易行道具数量
function XAreaWarAuction:GetItemAllNum(itemId)
    local allNum = 0
    local partitions = self._ItemToPartitionsDic[itemId]
    if partitions and #partitions > 0 then
        for _, partition in pairs(partitions) do
            allNum = allNum + partition.ItemNum
        end
    end
    return allNum
end

-- 获取可购买的最大数量
function XAreaWarAuction:GetMaxBuyNum(itemId)
    local ownCoin = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    local partitions = self._ItemToPartitionsDic[itemId]
    if partitions and #partitions > 0 then
        -- 价格从低到高排序
        tableSort(partitions, function(a, b)
            return a.Price < b.Price
        end)

        local maxBuyNum = 0
        for _, partition in pairs(partitions) do
            local priceMaxBuyNum = mathFloor(ownCoin / partition.Price) -- 这个价格可以买到的数量
            if priceMaxBuyNum > partition.ItemNum then
                maxBuyNum = maxBuyNum + partition.ItemNum
                ownCoin = ownCoin - partition.ItemNum * partition.Price
            else
                maxBuyNum = maxBuyNum + priceMaxBuyNum
                ownCoin = ownCoin - priceMaxBuyNum * partition.Price
            end
        end
        return maxBuyNum
    end
    return 0
end

-- 获取商品购买价格
---@param itemId number 商品Id
---@param num number 商品数量
function XAreaWarAuction:GetItemBuyPrice(itemId, num)
    local partitions = self._ItemToPartitionsDic[itemId]
    if partitions and #partitions > 0 then
        -- 价格从低到高排序
        tableSort(partitions, function(a, b) 
            return a.Price < b.Price
        end)
        
        local allPrice = 0
        for _, partition in pairs(partitions) do
            if num >= partition.ItemNum then
                allPrice = allPrice + partition.ItemNum * partition.Price
                num =  num - partition.ItemNum
            elseif num > 0 then
                allPrice = allPrice + num * partition.Price
                num = 0
            end
        end
        return allPrice
    end
    return 0
end

-- 获取商品的平均价格
function XAreaWarAuction:GetItemAveragePrice(itemId)
    local partitions = self._ItemToPartitionsDic[itemId]
    if partitions and #partitions > 0 then
        local allPrice = 0
        local allNum = 0
        for _, partition in pairs(partitions) do
            allPrice = allPrice + partition.ItemNum * partition.Price
            allNum = allNum + partition.ItemNum
        end
        if allPrice == 0 or allNum == 0 then
            return 0
        else
            return mathFloor(allPrice / allNum)
        end
    end
    return 0
end

-- 获取商品的最低价格
function XAreaWarAuction:GetItemMinPrice(itemId)
    local partitions = self._ItemToPartitionsDic[itemId]
    if partitions and #partitions > 0 then
        -- 价格从低到高排序
        tableSort(partitions, function(a, b)
            return a.Price < b.Price
        end)

        local cnt = #partitions
        for i = 1, cnt do
            if partitions[i].ItemNum > 0 then -- 区间有商品才算有效区间
                return partitions[i].Price
            end
        end

        return 0
    end
    return 0
end

-- 获取商品的最高价格
function XAreaWarAuction:GetItemMaxPrice(itemId)
    local partitions = self._ItemToPartitionsDic[itemId]
    if partitions and #partitions > 0 then
        -- 价格从高到低排序
        tableSort(partitions, function(a, b)
            return a.Price > b.Price
        end)
        
        local cnt = #partitions
        for i = 1, cnt do
            if partitions[i].ItemNum > 0 then -- 区间有商品才算有效区间
                return partitions[i].Price
            end
        end
        
        return 0
    end
    return 0
end


return XAreaWarAuction
