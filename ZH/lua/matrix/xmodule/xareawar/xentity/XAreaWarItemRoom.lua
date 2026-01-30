local tableInsert = table.insert
local mathFloor = math.floor
local pairs = pairs

---@class XAreaWarItemRoom
local XAreaWarItemRoom = XClass(nil, "XAreaWarItemRoom")

function XAreaWarItemRoom:Ctor()
    ---@type number 藏品室等级
    self._Lv = 1
    ---@type table<number, XAreaWarItem> 藏品道具列表，Key为ItemId
    self._ItemDic = {}
    ---@type table<number, boolean> 历史获得过的道具，Key为ItemId
    self._HistoryItemDic = {}
    ---@type table<number, boolean> 珍稀藏品是否提交点亮
    self._SubmitRaceItemDic = {}
    ---@type table<number, XAreaWarAuctionOrder> 拍卖订单，Key为OrderId
    self._SellOrderDic = {}
    ---@type XAreaWarAuctionOrder[] 历史订单
    self._HistoryOrders = {}
end

function XAreaWarItemRoom:RefreshData(data)
    if not data then return end
    
    self:RefreshLv(data.Lv)
    self:RefreshItems(data.Items)
    self:RefreshHistoryItems(data.HistoryItems)
    self:RefreshSubmitRaceItem(data.SubmitRaceItem)
    self:RefreshAuctionOrders(data.SellOrders)
end

-- 刷新藏品室等级
function XAreaWarItemRoom:RefreshLv(lv)
    self._Lv = lv
end

-- 获取藏品室等级
function XAreaWarItemRoom:GetLv()
    return self._Lv
end

--region 道具
-- 刷新道具列表
---@param items XAreaWarItem[]
function XAreaWarItemRoom:RefreshItems(items)
    self._ItemDic = {}
    for _, item in pairs(items) do
        self._ItemDic[item.ItemId] = item -- 直接赋值缓存引用，不封装成类，减少内存开销
    end
end

-- 收藏室道具发生变化
---@param addItems XAreaWarItem[]
---@param removeItemIds number[]
---@param updateItems XAreaWarItem[]
function XAreaWarItemRoom:ChangeItems(addItems, removeItemIds, updateItems)
    -- 新增道具
    if addItems and #addItems > 0 then
        for _, item in pairs(addItems) do
            self._ItemDic[item.ItemId] = item
        end
    end
    -- 删除道具
    if removeItemIds and #removeItemIds > 0 then
        for _, removeItemId in pairs(removeItemIds) do
            self._ItemDic[removeItemId] = nil
        end
    end
    -- 数量变化道具
    if updateItems and #updateItems > 0 then
        for _, item in pairs(updateItems) do
            self._ItemDic[item.ItemId] = item
        end
    end
end

-- 获取道具列表
function XAreaWarItemRoom:GetItemDic()
    return self._ItemDic
end

-- 获取道具数量
function XAreaWarItemRoom:GetItemNum(itemId)
    local item = self._ItemDic[itemId]
    return item and item.Num or 0
end

-- 刷新历史获得过的道具
function XAreaWarItemRoom:RefreshHistoryItems(itemIds)
    for _, itemId in pairs(itemIds) do
        self._HistoryItemDic[itemId] = true
    end
end

-- 道具是否曾经获得过
function XAreaWarItemRoom:IsItemHistoryGet(itemId)
    return self._HistoryItemDic[itemId] or self:GetItemNum(itemId) > 0 -- 只有打开藏品界面之后，退出藏品界面，才会加入self._HistoryItemDic
end

-- 道具是否是新获得的
function XAreaWarItemRoom:IsItemNewGet(itemId)
    local isNew = self._HistoryItemDic[itemId] ~= true and self:GetItemNum(itemId) > 0
    return isNew
end

-- 清除所有道具新获得标记
function XAreaWarItemRoom:ClearAllItemNewGet(itemIdDic)
    for itemId, _ in pairs(itemIdDic) do
        self._HistoryItemDic[itemId] = true
    end
end

-- 是否存在道具
function XAreaWarItemRoom:IsExitItem()
    for _, item in pairs(self._ItemDic) do
        if item.Num > 0 then
            return true
        end
    end
    return false
end

-- 是否获得过道具
function XAreaWarItemRoom:IsObtainedItem()
    if self:IsExitItem() then
        return true
    end

    for itemId, isGet in pairs(self._HistoryItemDic) do
        if isGet then
            return true
        end
    end
    
    return false
end

--endregion

--region 珍稀道具
-- 刷新提交的珍稀道具
function XAreaWarItemRoom:RefreshSubmitRaceItem(submitItemIds)
    self._SubmitRaceItemDic = {}
    for _, itemId in pairs(submitItemIds) do
        self._SubmitRaceItemDic[itemId] = true
    end
end

-- 增加已提交的珍稀道具
function XAreaWarItemRoom:AddSubmitRaceItem(itemId)
    self._SubmitRaceItemDic[itemId] = true
end

-- 珍稀道具是否已经提交
function XAreaWarItemRoom:IsRaceItemSubmit(itemId)
    return self._SubmitRaceItemDic[itemId] == true
end

--endregion

--region 拍卖订单
-- 刷新订单
function XAreaWarItemRoom:RefreshAuctionOrders(orders)
    self._SellOrderDic = {}
    for _, order in pairs(orders) do
        self._SellOrderDic[order.OrderId] = order -- 直接赋值缓存引用，不封装成类，减少内存开销
    end
end

-- 增加订单
function XAreaWarItemRoom:AddOrders(orders)
    for _, order in pairs(orders) do
        self._SellOrderDic[order.OrderId] = order -- 直接赋值缓存引用，不封装成类，减少内存开销
    end
end

-- 移除订单
function XAreaWarItemRoom:RemoveOrder(orderId)
    local order = self._SellOrderDic[orderId]
    self._SellOrderDic[orderId] = nil
    return order
end

-- 结算订单
---@param orderIds number[]
function XAreaWarItemRoom:SettleOrders(orderIds)
    for _, orderId in pairs(orderIds) do
        local order = self:RemoveOrder(orderId)
        tableInsert(self._HistoryOrders, order)
    end
end

-- 获取订单列表
function XAreaWarItemRoom:GetSellOrderDic()
    return self._SellOrderDic
end

-- 获取历史订单列表
function XAreaWarItemRoom:GetHistoryOrders()
    return self._HistoryOrders
end

-- 清除历史订单列表
function XAreaWarItemRoom:ClearHistoryOrders()
    self._HistoryOrders = {}
end

-- 获取结算的订单列表，包括已经出售和过期的
function XAreaWarItemRoom:GetSettleOrderIds()
    local result = {}
    local nowTime = XTime.GetServerNowTimestamp()
    local MAX_AUTO_SELL_TIME = XAreaWarConfigs.GetMaxAutoSellTime()
    for _, order in pairs(self._SellOrderDic) do
        local canSell = order.AutoSellTime <= MAX_AUTO_SELL_TIME -- 是否能够出售成功
        local isSell = nowTime > order.CreateTime + order.AutoSellTime -- 是否已经出售
        local isExpired = nowTime > order.CreateTime + MAX_AUTO_SELL_TIME -- 是否过期过期
        if canSell and isSell then
            tableInsert(result, order.OrderId) -- 成功出售订单
        elseif not canSell and isExpired then
            tableInsert(result, order.OrderId) -- 过期订单
        end
    end
    return result
end

-- 获取有效的订单列表
function XAreaWarItemRoom:GetValidOrders()
    local result = {}
    local nowTime = XTime.GetServerNowTimestamp()
    local MAX_AUTO_SELL_TIME = XAreaWarConfigs.GetMaxAutoSellTime()
    for _, order in pairs(self._SellOrderDic) do
        local isSell = nowTime > order.CreateTime + order.AutoSellTime -- 是否已经出售
        local isExpired = nowTime > order.CreateTime + MAX_AUTO_SELL_TIME -- 是否过期过期
        if not isSell and not isExpired then
            tableInsert(result, order)
        end
    end
    return result
end

-- 订单是否有效：未过期、未出售成功
function XAreaWarItemRoom:IsOrderValid(orderId)
    local order = self._SellOrderDic[orderId]
    if not order then
        return false
    end
    
    local nowTime = XTime.GetServerNowTimestamp()
    local MAX_AUTO_SELL_TIME = XAreaWarConfigs.GetMaxAutoSellTime()
    local isSell = nowTime > order.CreateTime + order.AutoSellTime -- 是否已经出售
    local isExpired = nowTime > order.CreateTime + MAX_AUTO_SELL_TIME -- 是否过期过期
    return not isSell and not isExpired
end

-- 获取订单的预计收入
function XAreaWarItemRoom:GetOrderIncome(order)
    local allPrice = order.Num * order.Price -- 总价
    local SELL_RATE = XAreaWarConfigs.GetAuctionSellRate() -- 出售手续费万分比，配置1000则为10%
    local sellCharge = mathFloor(SELL_RATE / 10000 * allPrice) -- 出售手续费
    return allPrice - sellCharge
end

-- 是否存在订单出售成功
function XAreaWarItemRoom:IsExitOrderSellSuccess()
    local nowTime = XTime.GetServerNowTimestamp()
    local MAX_AUTO_SELL_TIME = XAreaWarConfigs.GetMaxAutoSellTime()
    for _, order in pairs(self._SellOrderDic) do
        local canSell = order.AutoSellTime <= MAX_AUTO_SELL_TIME -- 是否能够出售成功
        local isSell = nowTime > order.CreateTime + order.AutoSellTime -- 是否已经出售
        if canSell and isSell then
            return true
        end
    end
    return false
end

--endregion

return XAreaWarItemRoom
