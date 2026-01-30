---@class XAreaWarAuctionOrder 辅助Rider提示，实际没有用到这个类
---@field OrderId number 订单号
---@field CreateTime number 订单创建时间(S)
---@field AutoSellTime number 客户端检测自动出售时间(S)，结束时间为(CreateTime+AutoSellTime)
---@field ItemId number 道具Id
---@field Num number 出售数量
---@field Price number 出售价格
---@field AutoSellCoin number 获得拍卖行币
local XAreaWarAuctionOrder = XClass(nil, "XAreaWarAuctionOrder")

function XAreaWarAuctionOrder:Ctor()
    
end

return XAreaWarAuctionOrder
