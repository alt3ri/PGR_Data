---@class XShopAgency : XAgency
---@field private _Model XShopModel
local XShopAgency = XClass(XAgency, "XShopAgency")
function XShopAgency:OnInit()

end

function XShopAgency:InitRpc()
    XRpc.NotifyAccumulateExpendShopData = handler(self, self.RecieveAccumulateExpendShopDataNotify)
    self.RequestName = {
        EnterAccumulateExpendShop = "EnterAccumulateExpendShopRequest",
        ClaimSignReward = "ClaimSignRewardRequest",
    }
end

function XShopAgency:InitEvent()

end
--region 累消商店
function XShopAgency:RecieveAccumulateExpendShopDataNotify(data)
    -- self._Model:RecieveActivityData(data)
    self._Model:SetAccumulateExpendShopData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_ACCUMULATE_EXPEND_SHOP_DATA)
end

--检查并发放待领取的代币
function XShopAgency:EnterAccumulateExpendShop(cb)
    XNetwork.Call(self.RequestName.EnterAccumulateExpendShop, {}, function(res)
    if res.RewardGoodsList then
        XUiManager.OpenUiObtainByUi("UiAccumulateExpendShopPopupDailyReward",res.RewardGoodsList)
    end   
        if cb then
            cb()
        end
    end)
end

--领取每日签到奖励
function XShopAgency:AccumulateExpendShopSign(cb)
    XNetwork.Call(self.RequestName.ClaimSignReward, {}, function(res)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtainByUi("UiAccumulateExpendShopPopupDailyReward",res.RewardGoodsList)
        end   
        if cb then
            cb()
        end
    end)
end

function XShopAgency:GetAccumulateExpendShopLeftTime(timeId)
    return self._Model:GetAccumulateExpendShop():GetLeftTime(timeId)
end

function XShopAgency:IsShowAccumulateExpendShopRedPoint()
    return self._Model:GetAccumulateExpendShop():IsRedPointShow()
end

function XShopAgency:GetAccumulateExpendShopConvertedCount()
    return self._Model:GetAccumulateExpendShop():GetConvertedCount()
end
--endregion

--region 涂装商店打开涂装详情

function XShopAgency:OpenFashionDetailUi(fashionid, buyData, params)
    local isShowFashionIconWithoutGift, isNeedCD, customWeaponFashionId, customDesc, suitId, isWeaponFashion, updateCb, skipType
    if params then
        isShowFashionIconWithoutGift = params.isShowFashionIconWithoutGift
        isNeedCD = params.isNeedCD
        customWeaponFashionId = params.customWeaponFashionId
        customDesc = params.customDesc
        isWeaponFashion = params.isWeaponFashion
        suitId = params.suitId
        updateCb = params.updateCb
        skipType = params.skipType
    end
    --v4.3 涂装套装详情界面支持显示武器涂装
    suitId = suitId or XMVCA.XFashionSuit:GetFashionSuitId(fashionid)
    if suitId then
        local reqQueue = {}
        local context = {}
        --请求商店是否开启
        table.insert(reqQueue, function(next)
            self:_CheckFashionShopOpen(suitId, context, next)
        end)
        --请求商店折扣
        table.insert(reqQueue, function(next)
            self:_GetBaseInfo(next)
        end)
        --请求商店商品信息
        table.insert(reqQueue, function(next)
            self:_GetShopInfoList(context.hasOpenShopIds, next, XShopManager.ActivityShopType.FashionShop)
        end)
        --请求礼包信息
        table.insert(reqQueue, function(next)
            XDataCenter.PurchaseManager.LBInfoDataReq(next)
        end)
        --开始执行
        self:RunChain(reqQueue, function()
            XLuaUiManager.Open("UiFashionSuitDetail", suitId, fashionid, skipType, updateCb)
        end)
    else
        local reqQueue = {}
        local shopIds = XMVCA.XFashionSuit:GetGroupSalesShopIds(fashionid)
        --请求商店商品信息
        table.insert(reqQueue, function(next)
            self:_GetShopInfoList(shopIds, next, XShopManager.ActivityShopType.FashionShop)
        end)
        --开始执行
        self:RunChain(reqQueue, function()
            XLuaUiManager.Open("UiFashionDetail", fashionid, isWeaponFashion, buyData, isShowFashionIconWithoutGift, isNeedCD, customWeaponFashionId, customDesc)
        end)
    end
end

function XShopAgency:_CheckFashionShopOpen(suitId, context, next)
    XMVCA.XFashionSuit:CheckFashionShopOpen(suitId, function()
        context.hasOpenShopIds = {}
        local shopIds = XMVCA.XFashionSuit:GetSuitShopIds(suitId)
        for _, shopId in pairs(shopIds) do
            if XShopManager.IsShopOpen(shopId) then
                table.insert(context.hasOpenShopIds, shopId)
            end
        end
        next()
    end)
end

function XShopAgency:_GetShopInfoList(shopIdList, cb, shopType, notTip)
    if XTool.IsTableEmpty(shopIdList) or not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
        if cb then
            cb()
        end
        return
    end
    XShopManager.GetShopInfoList(shopIdList, cb, shopType, notTip)
end

function XShopAgency:_GetBaseInfo(cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
        if cb then
            cb()
        end
        return
    end
    XShopManager.GetBaseInfo(cb)
end

function XShopAgency:RunChain(steps, finalCb)
    local index = 1
    local function next()
        local step = steps[index]
        index = index + 1

        if step then
            step(next)
        else
            if finalCb then
                finalCb()
            end
        end
    end
    next()
end

function XShopAgency:OpenFashionDetailShowUi(fashionid,IsWeaponFashion)
    XLuaUiManager.Open("UiFashionDetail", fashionid, IsWeaponFashion)
end

return XShopAgency
