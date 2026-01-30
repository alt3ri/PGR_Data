--累消商店
---@class XAccumulateExpendShop
---@field _Model XShopModel
local XAccumulateExpendShop = XClass(nil, "XAccumulateExpendShop")
local SaveKey = "XAccumulateExpendShop_"
function XAccumulateExpendShop:Ctor(model)
    self._Model = model
end

-- 刷新整个阶段数据
function XAccumulateExpendShop:RefreshData(data)
    if data.ActivityId == 0 then
        self._ActivityId            = data.ActivityId
        return
    end
    self._TodaySignRewardStatus = data.SignRewardData.TodaySignRewardStatus
    self._ActivityId            = data.ActivityId
    self._TotalConsumeCount     = data.TotalConsumeCount
    self._ConvertedCount        = data.ConvertedCount
    self._ActivityConfig        = self:GetActivityConfigs()
    if not self:IsConsumeCountMax() then
        self._NotifyChange = self._NotifyChange or
            XSaveTool.GetData(SaveKey .. "TotalConsumeCount") ~=
            data.TotalConsumeCount * self._ActivityConfig.ItemExchangeRate
    end

    self._CurDateSignRewardId = self._Model:GetAccumulateExpendShopSignRewardReward(data.SignRewardData.Id,
        data.SignRewardData.Index + 1)
end

function XAccumulateExpendShop:GetLeftTime(timeId)
    local leftTime = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
    local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    if not self._ActivityId or not self._ActivityConfig then
        return leftTimeStr
    end

    if leftTime <= self._ActivityConfig.PromptLeftTime then
        return string.format("<color=#FF0000>%s</color>", leftTimeStr)
    end
    return leftTimeStr
end

function XAccumulateExpendShop:GetActivityId()
    return self._ActivityId
end

--已签到
function XAccumulateExpendShop:IsSign()
    return self._TodaySignRewardStatus == 0
end

--总消耗的虹卡数
function XAccumulateExpendShop:GetTotalConsumeCount()
    return self._TotalConsumeCount
end

--代币总数量
function XAccumulateExpendShop:GetConvertedCount()
    if not self._ActivityConfig then
        return 0
    end
    if self:IsConsumeCountMax() then
        return self._ActivityConfig.ShopItemMaxCount
    end
    return self._ConvertedCount * self._ActivityConfig.ItemExchangeRate
end

function XAccumulateExpendShop:GetCurDateSignReward()
    return self._CurDateSignRewardId
end

function XAccumulateExpendShop:IsRedPointShow()
    return self._NotifyChange or self._CurDateSignRewardId ~= nil
end

function XAccumulateExpendShop:EnterShop()
    self._NotifyChange = false
    if not self:IsConsumeCountMax() then
        XSaveTool.SaveData(SaveKey .. "TotalConsumeCount",
            self._TotalConsumeCount * self._ActivityConfig.ItemExchangeRate)
    end
end

function XAccumulateExpendShop:IsConsumeCountMax()
    return self._ActivityConfig.ShopItemMaxCount <= self._ConvertedCount * self._ActivityConfig.ItemExchangeRate
end

function XAccumulateExpendShop:SortGoodList(shopId)
    local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)
    --排序优先级
    table.sort(goodsList, function(a, b)
        -- 是否卖光
        if a.BuyTimesLimit > 0 or b.BuyTimesLimit > 0 then
            -- 如果商品有次数限制，并且达到次数限制，则判断为售罄
            local isSellOutA = a.BuyTimesLimit == a.TotalBuyTimes and a.BuyTimesLimit > 0
            local isSellOutB = b.BuyTimesLimit == b.TotalBuyTimes and b.BuyTimesLimit > 0
            if isSellOutA ~= isSellOutB then
                return isSellOutB
            end
        end

        -- 是否限时
        if a.SelloutTime ~= b.SelloutTime then
            if a.SelloutTime > 0 and b.SelloutTime > 0 then
                return a.SelloutTime < b.SelloutTime
            elseif a.SelloutTime > 0 and b.SelloutTime <= 0 then
                return XShopManager.GetLeftTime(a.SelloutTime) > 0
            elseif a.SelloutTime <= 0 and b.SelloutTime > 0 then
                return XShopManager.GetLeftTime(b.SelloutTime) < 0
            end
        end

        if a.Tags ~= b.Tags and a.Tags ~= 0 and b.Tags ~= 0 then
            return a.Tags < b.Tags
        end

        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
    end)
    return goodsList
end

function XAccumulateExpendShop:GetActivityConfigs()
    return self._Model:GetAccumulateExpendShopActivityConfig(self._ActivityId)
end

return XAccumulateExpendShop
