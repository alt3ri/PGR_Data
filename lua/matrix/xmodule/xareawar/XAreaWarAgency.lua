local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XAreaWarAgency : XFubenActivityAgency
---@field private _Model XAreaWarModel
local XAreaWarAgency = XClass(XFubenActivityAgency, "XAreaWarAgency")
function XAreaWarAgency:OnInit()
    -- 初始化一些变量
    self:RegisterActivityAgency()
    -- EnumConst
    self.EnumConst = require("XModule/XAreaWar/XAreaWarEnumConst")
end

function XAreaWarAgency:InitRpc()
    -- 实现服务器事件注册
    XRpc.NotifyAreaWar4ItemRoom = handler(self, self.NotifyAreaWar4ItemRoom)
    self.RequestName = {
        AreaWar4ItemRoomLevelUpRequest = "AreaWar4ItemRoomLevelUpRequest",          -- 请求升级收藏室
        AreaWar4AuctionInfoRequest = "AreaWar4AuctionInfoRequest",                  -- 请求交易行数据
        AreaWar4AuctionPutOnRequest = "AreaWar4AuctionPutOnRequest",                -- 交易行订单上架
        AreaWar4AuctionPutOffRequest = "AreaWar4AuctionPutOffRequest",              -- 交易行订单下架
        AreaWar4AuctionSellRequest = "AreaWar4AuctionSellRequest",                  -- 交易订单结算
        AreaWar4AuctionBuyRequest = "AreaWar4AuctionBuyRequest",                    -- 购买商品
        AreaWar4SubmitRaceItemRequest = "AreaWar4SubmitRaceItemRequest",            -- 请求提交珍稀道具
    }
end

---@return XAreaWarConfig
function XAreaWarAgency:GetConfig()
    return self._Model:GetConfig()
end

-- 获取收藏室数据
---@return XAreaWarItemRoom
function XAreaWarAgency:GetItemRoom()
    return self._Model:GetItemRoom()
end

--region 协议
--登录下发
function XAreaWarAgency:NotifyAreaWarActivityData(data)
    -- 4.1新增的收藏室
    local itemRoom = self._Model:GetItemRoom()
    itemRoom:RefreshData(data.ItemRoom)
end

-- 藏品室道具变化下发
function XAreaWarAgency:NotifyAreaWar4ItemRoom(data)
    local itemRoom = self._Model:GetItemRoom()
    itemRoom:ChangeItems(data.AddItems, data.RemoveItems, data.UpdateItems)
    XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE)
end

-- 请求升级收藏室
function XAreaWarAgency:RequestAreaWar4ItemRoomLevelUp(cb)
    local req = {}
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.AreaWar4ItemRoomLevelUpRequest, req, function(res)
        local itemRoom = self._Model:GetItemRoom()
        itemRoom:RefreshLv(res.ItemRoomLevel)
        if cb then cb(res.Rewards) end
    end)
end

-- 请求交易行数据
function XAreaWarAgency:RequestAreaWar4AuctionInfo(cb)
    if self:CheckServerRedisCircuitBreaker() then
        return
    end
    
    -- 交易行数据在有效期内，不需要重新请求
    local isValid = self._Model:GetAuction():IsDataValid()
    if isValid then
        if cb then cb() end
        return
    end
    
    local req = {}
    XNetwork.Call(self.RequestName.AreaWar4AuctionInfoRequest, req, function(res)
        if self:CheckServerRedisCircuitBreakerByCode(res.Code) then
            return
        end
        
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        local auction = self._Model:GetAuction()
        auction:RefreshData(res.Auction)
        if cb then cb() end
    end)
end

-- 请求交易行上架
function XAreaWarAgency:RequestAreaWar4AuctionPutOn(items, cb)
    if self:CheckServerRedisCircuitBreaker() then
        return
    end
    
    local req = { PutOnItems = items }
    XNetwork.Call(self.RequestName.AreaWar4AuctionPutOnRequest, req, function(res)
        if self:CheckServerRedisCircuitBreakerByCode(res.Code) then
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        local itemRoom = self._Model:GetItemRoom()
        itemRoom:AddOrders(res.Orders)
        if cb then cb() end
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE)
    end)
end

-- 请求交易行订单下架
function XAreaWarAgency:RequestAreaWar4AuctionPutOff(orderId, cb)
    if self:CheckServerRedisCircuitBreaker() then
        return
    end
    
    local req = { OrderId = orderId }
    XNetwork.Call(self.RequestName.AreaWar4AuctionPutOffRequest, req, function(res)
        if self:CheckServerRedisCircuitBreakerByCode(res.Code) then
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        local itemRoom = self._Model:GetItemRoom()
        itemRoom:RemoveOrder(orderId)
        if cb then cb() end
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE)
    end)
end

-- 请求交易行订单结算
function XAreaWarAgency:RequestAreaWar4AuctionSell(orderIds, cb)
    if self:CheckServerRedisCircuitBreaker() then
        return
    end
    
    local req = { OrderIds = orderIds }
    XNetwork.Call(self.RequestName.AreaWar4AuctionSellRequest, req, function(res)
        if self:CheckServerRedisCircuitBreakerByCode(res.Code) then
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        local itemRoom = self._Model:GetItemRoom()
        itemRoom:SettleOrders(orderIds)
        if cb then cb() end
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE)
    end)
end

-- 请求购买商品
function XAreaWarAgency:RequestAreaWar4AuctionBuy(itemId, num, successCb, failCb)
    if self:CheckServerRedisCircuitBreaker() then
        return
    end
    
    local req = { 
        ItemId = itemId, 
        Partitions = {}
    }
    local partitions = self._Model:GetAuction():GetPartitions(itemId)
    table.sort(partitions, function(a, b) 
        return a.Price < b.Price
    end)
    for _, partition in ipairs(partitions) do
        if partition.ItemNum > 0 then
            if num >= partition.ItemNum then
                table.insert(req.Partitions, {Partition = partition.Partition, Price = partition.Price, ItemNum = partition.ItemNum})
                num =  num - partition.ItemNum
            elseif num > 0 then
                table.insert(req.Partitions, {Partition = partition.Partition, Price = partition.Price, ItemNum = num})
                num = 0
            end
        end
    end
    
    XNetwork.Call(self.RequestName.AreaWar4AuctionBuyRequest, req, function(res)
        if self:CheckServerRedisCircuitBreakerByCode(res.Code) then
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        if res.AuctionItem then
            local auction = self._Model:GetAuction()
            auction:RefreshItemData(res.AuctionItem)
        end
        if res.BuyResultType == XMVCA.XAreaWar.EnumConst.AUCTION_BUY_RESULT_TYPE.SUCCESS then
            if successCb then successCb() end
        else
            if failCb then failCb() end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_ITEM_ROOM_SHOP_CHANGE)
    end)
end

-- 请求提交珍稀道具
function XAreaWarAgency:RequestAreaWar4SubmitRaceItem(itemId, cb)
    local req = { RaceItemId = itemId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.AreaWar4SubmitRaceItemRequest, req, function(res)
        local itemRoom = self._Model:GetItemRoom()
        itemRoom:AddSubmitRaceItem(itemId)
        if cb then cb(res.Rewards) end
    end)
end

-- 检测交易行是否挂了，挂了需要等待5秒
function XAreaWarAgency:CheckServerRedisCircuitBreakerByCode(code)
    if code == XCode.AreaWar4RedisCircuitBreaker then
        self.ServerBreakerTime = XTime.GetServerNowTimestamp()
        local tips = XAreaWarConfigs.GetServerRedisCircuitBreakerTips()
        XUiManager.TipError(tips)
        return true
    end
    return false
end

-- 检测交易行是否挂了，挂了需要等待5秒
function XAreaWarAgency:CheckServerRedisCircuitBreaker()
    if self.ServerBreakerTime then
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime > self.ServerBreakerTime and (nowTime - self.ServerBreakerTime < self.EnumConst.SERVER_BREAK_RPC_OFFSET_TIEM) then
            local tips = XAreaWarConfigs.GetServerRedisCircuitBreakerTips()
            XUiManager.TipError(tips)
            return true
        end
    end
    return false
end

--endregion

-- 检测是否第一次进入玩法
function XAreaWarAgency:CheckFirstEnter()
    -- 配合服务端把收藏室从0级升到1级，服务端需要记录1级的有效人数
    local itemRoom = self._Model:GetItemRoom()
    if itemRoom:GetLv() == 0 then
        self:RequestAreaWar4ItemRoomLevelUp()
    end
end

-- 检测结算交易行订单
function XAreaWarAgency:CheckSettleOrders()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    
    local itemRoom = self._Model:GetItemRoom()
    local orderIds = itemRoom:GetSettleOrderIds()
    if #orderIds == 0 then return end
    
    self:RequestAreaWar4AuctionSell(orderIds, function()
        if not XLuaUiManager.IsUiShow("UiAreaWarPopupRecord") then
            XLuaUiManager.Open("UiAreaWarPopupRecord")
        end
    end)
end

-- 是否有藏品室蓝点
function XAreaWarAgency:IsRedCollection()
    return self._Model:IsRedCollection()
end

function XAreaWarAgency:OpenUiAreaWarObtain(data,areaWarItems, title, closeCallback, sureCallback, horizontalNormalizedPosition, customParams)
    if not CS.XFightInterface.IsOutFight then
        return -- 战斗不弹
    end

    -- 等待父级ui中列表异步刷新完成，以保证弹窗的截图效果正常
    if XUiManager.IsTableAsyncLoading() then
        XUiManager.WaitTableLoadComplete(function()
            XLuaUiManager.Open("UiAreaWarObtain", data,areaWarItems, title, closeCallback, sureCallback, horizontalNormalizedPosition, customParams)
        end)
    else
        XLuaUiManager.Open("UiAreaWarObtain", data, areaWarItems,title, closeCallback, sureCallback, horizontalNormalizedPosition, customParams)
    end
end

return XAreaWarAgency
