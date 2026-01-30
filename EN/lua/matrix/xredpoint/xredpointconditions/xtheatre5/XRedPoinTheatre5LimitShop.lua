--- 肉鸽5 限时商店红点
local XRedPoinTheatre5LimitShop = {}

function XRedPoinTheatre5LimitShop.Check()
    -- 先判断活动是否开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end
    local baseShopUnlock = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true)
    if not baseShopUnlock then
        return false
    end    
    --当天是否提醒过了
    if XMVCA.XTheatre5:CheckLimitShopReddot() then
        --是否有能买的商品
        return XMVCA.XTheatre5:CheckLimitShopCanBuyGoods()
    end
    
    -- 如果有商品新增
    if XMVCA.XTheatre5:CheckShopNewGoods() then
        return true
    end
    
    return false
end

return XRedPoinTheatre5LimitShop