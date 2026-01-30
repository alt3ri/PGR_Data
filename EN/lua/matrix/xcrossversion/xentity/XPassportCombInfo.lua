local type = type

---@class XPassportCombInfo@玩家通行证信息
local XPassportCombInfo = XClass(nil, "XPassportCombInfo")

local Default = {
    _Id = 1, --通行证Id
    _GotRewardDic = {}, --奖励领取记录
    _BuyTimes = 0,
}

function XPassportCombInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XPassportCombInfo:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end
    self._Id = data.Id
    
    for _, rData in ipairs(data.GotRewardList) do
        self:SetReceiveReward(rData.RewardId)
    end
    self._BuyTimes = data.BuyTimes
end

function XPassportCombInfo:GetId()
    return self._Id
end

function XPassportCombInfo:SetReceiveReward(rewardId)
    self._GotRewardDic[rewardId] = true
end

function XPassportCombInfo:IsReceiveReward(passportRewardId)
    return self._GotRewardDic[passportRewardId]
end

function XPassportCombInfo:GetBuyTimes()
    return self._BuyTimes
end

return XPassportCombInfo