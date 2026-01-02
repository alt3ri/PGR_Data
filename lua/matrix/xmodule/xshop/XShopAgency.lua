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
    local isShowFashionIconWithoutGift, isNeedCD, customWeaponFashionId, customDesc, suitId, isWeaponFashion, updateCb
    if params then
        isShowFashionIconWithoutGift = params.isShowFashionIconWithoutGift
        isNeedCD = params.isNeedCD
        customWeaponFashionId = params.customWeaponFashionId
        customDesc = params.customDesc
        isWeaponFashion = params.isWeaponFashion
        suitId = params.suitId
        updateCb = params.updateCb
    end
    if isWeaponFashion then
        XLuaUiManager.Open("UiFashionDetail", fashionid, isWeaponFashion, buyData,isShowFashionIconWithoutGift,isNeedCD,customWeaponFashionId,customDesc)
        return
    end
    suitId =suitId or XMVCA.XFashionSuit:GetFashionSuitId(fashionid)
    if suitId then
        XDataCenter.PurchaseManager.LBInfoDataReq(function()
            XLuaUiManager.Open("UiFashionSuitDetail", suitId, fashionid, updateCb)
        end)
    else
        XLuaUiManager.Open("UiFashionDetail", fashionid, false, buyData,isShowFashionIconWithoutGift,isNeedCD,customWeaponFashionId,customDesc)
    end
end
function XShopAgency:OpenFashionDetailShowUi(fashionid,IsWeaponFashion)
    XLuaUiManager.Open("UiFashionDetail", fashionid, IsWeaponFashion)
end

return XShopAgency
