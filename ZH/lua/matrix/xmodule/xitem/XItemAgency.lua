---@class XItemAgency : XAgency
---@field private _Model XItemModel
local XItemAgency = XClass(XAgency, "XItemAgency")
function XItemAgency:OnInit()

end

function XItemAgency:InitRpc()

end

function XItemAgency:InitEvent()

end

function XItemAgency:SelectBuyAssetType(useItemId, callBack, challengeCountData, buyAmount, isAutoClose)
    if useItemId == XDataCenter.ItemManager.ItemId.ActionPoint and
        XDataCenter.ItemManager.CheckBatteryIsHave() then
        XLuaUiManager.Open("UiUsePackage", useItemId, callBack, challengeCountData, buyAmount)
        return
    elseif useItemId == XDataCenter.ItemManager.ItemId.Coin
        and XDataCenter.ItemManager.CheckCoinPackageIsHave() then
        XLuaUiManager.Open("UiUseCoinPackage")
        return
    end
    local cfg = self._Model:GetItemUsePackageConfig(useItemId,true)
    if not cfg then
        XLuaUiManager.Open("UiBuyAsset", useItemId, callBack, challengeCountData, buyAmount, isAutoClose)
        return
    end

    if self:CheckItemHasPackage(useItemId) then
        XLuaUiManager.Open("UiCommonPopupUsePackage", useItemId, callBack, challengeCountData, buyAmount)
        return
    end

    XLuaUiManager.Open("UiCommonPopupBuyAsset", useItemId, callBack, challengeCountData, buyAmount, isAutoClose)
end

function XItemAgency:CheckItemHasPackage(itemId)
    local cfg = self._Model:GetItemUsePackageConfig(itemId)
    if not cfg then
        return false
    end
    if cfg.PackageIds and #cfg.PackageIds > 0 then
        for _, v in pairs(cfg.PackageIds) do
            if XDataCenter.ItemManager.GetCount(v) > 0 then
                return true
            end
        end
    end
    return false
end

function XItemAgency:RequestExchange(itemId, count, useItemId, callback)
    local args = {
        ItemId = itemId,
        Count = count,
        UseItemId = useItemId,
    }
    XNetwork.Call("ItemExchangeRequest", args, function(res)
        if res.Code == XCode.Success then
            callback(res.RewardGoodsList)
        end
    end)
end

function XItemAgency:CheckItemHasConfig(id)
    local cfg = self._Model:GetItemUsePackageConfig(id,true)
    if cfg then
        return true
    end
    cfg = XDataCenter.ItemManager.GetBuyAssetTemplateById(id)
    if cfg then
        return true
    end
    return false
end

return XItemAgency
