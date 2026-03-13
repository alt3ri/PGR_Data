---@class XFashionSuitControl : XControl
---@field private _Model XFashionSuitModel
local XFashionSuitControl = XClass(XControl, "XFashionSuitControl")

function XFashionSuitControl:OnInit()

end

function XFashionSuitControl:AddAgencyEvent()

end

function XFashionSuitControl:RemoveAgencyEvent()

end

function XFashionSuitControl:OnRelease()

end

--region 配置

---@return string
function XFashionSuitControl:GetClientConfig(key, index)
    index = index or 1
    local config = self._Model:GetClientConfigById(key)
    if config then
        return config.Values[index]
    end
    return nil
end

---@return number
function XFashionSuitControl:GetIntClientConfig(key, index)
    local value = self:GetClientConfig(key, index)
    if value then
        return tonumber(value)
    end
    return nil
end

---@return XTableFashionSuit
function XFashionSuitControl:GetFashionSuitById(id)
    return self._Model:GetFashionSuitById(id)
end

--endregion

function XFashionSuitControl:IsSuitRewardGain(id)
    return self._Model:IsSuitRewardGain(id)
end

function XFashionSuitControl:GetCollectCount(suitId)
    local count = 0
    local fashionIds = self:GetFashionSuitById(suitId).FashionIds
    for _, fashionId in pairs(fashionIds) do
        if XDataCenter.FashionManager.CheckHasFashion(fashionId) then
            count = count + 1
        end
    end
    return count
end

function XFashionSuitControl:SetFashionViewed(fashionId)
    if not fashionId or XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        return
    end
    self._Model:SetFashionViewed(fashionId)
end

function XFashionSuitControl:IsFashionViewed(fashionId)
    if not fashionId or XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        return false
    end
    return self._Model:IsFashionViewed(fashionId)
end

---领取涂装套装奖励
function XFashionSuitControl:RequestGetSuitReward(suitId, cb)
    local req = {}
    req.SuitId = suitId
    XNetwork.CallWithAutoHandleErrorCode("FashionGetSuitRewardRequest", req, function(res)
        self._Model:SetSuitRewardGain(suitId)
        XUiManager.OpenUiObtain(res.RewardGoodsList)
        if cb then
            cb()
        end
    end)
end

return XFashionSuitControl