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
    self._TodaySignRewardStatus = data.SignRewardData.TodaySignRewardStatus
    self._ActivityId            = data.ActivityId
    self._TotalConsumeCount     = data.TotalConsumeCount
    self._ConvertedCount        = data.ConvertedCount
    self._ActivityConfig        = self._Model:GetAccumulateExpendShopActivityConfig(self._ActivityId)
    self._NotifyChange          = self._NotifyChange or
    XSaveTool.GetData(SaveKey .. "TotalConsumeCount") ~= data.TotalConsumeCount * self._ActivityConfig.ItemExchangeRate

    self._CurDateSignRewardId   = self._Model:GetAccumulateExpendShopSignRewardReward(data.SignRewardData.Id,
        data.SignRewardData.Index+1)
end

function XAccumulateExpendShop:GetLeftTime(timeId)
    if not self._ActivityId then
        return ""
    end
    
    local leftTime = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
    if leftTime <= self._ActivityConfig.PromptLeftTime then
        local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        return string.format("<color=#FF0000>%s</color>", leftTimeStr)
    end
    return ""
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
    return self._ConvertedCount * self._ActivityConfig.ItemExchangeRate
end

function XAccumulateExpendShop:GetCurDateSignReward()
    return self._CurDateSignRewardId
end

function XAccumulateExpendShop:IsRedPointShow()
    return self._NotifyChange
end

function XAccumulateExpendShop:EnterShop()
    self._NotifyChange = false
    XSaveTool.SaveData(SaveKey .. "TotalConsumeCount", self._TotalConsumeCount * self._ActivityConfig.ItemExchangeRate)
end

return XAccumulateExpendShop
