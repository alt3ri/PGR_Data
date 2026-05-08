---@class XBWSkipBase
local XBWSkipBase = XClass(nil, "XBWSkipBase")

function XBWSkipBase:Ctor(id)
    self:SetId(id)
end

function XBWSkipBase:SetId(id)
    self._Id = id or 0
end

function XBWSkipBase:GetId()
    return self._Id
end

function XBWSkipBase:GetParams()
    if not self:IsNil() then
        return XMVCA.XBigWorldSkipFunction:GetSkipParamsBySkipId(self:GetId())
    end

    return nil
end

function XBWSkipBase:IsNil()
    return not XTool.IsNumberValid(self:GetId())
end

function XBWSkipBase:IsAllowSkip(isNoTips)
    if not self:IsNil() then
        local conditionId = XMVCA.XBigWorldSkipFunction:GetSkipConditionIdBySkipId(self:GetId())

        if XTool.IsNumberValid(conditionId) then
            local isSuccess, tips = XMVCA.XBigWorldService:CheckCondition(conditionId)

            if not isSuccess then
                if not isNoTips then
                    XMVCA.XBigWorldUI:TipMsg(tips)
                end
                return false
            end
        end
        
        --TimeId
        local timeId = XMVCA.XBigWorldSkipFunction:GetSkipTimeIdBySkipId(self:GetId())
        if XMVCA.XBigWorldService:CheckInTimeByTimeId(timeId, true) == false then
            if not isNoTips then
                local text = XMVCA.XBigWorldService:GetText("SkipFailByTime")
                XMVCA.XBigWorldUI:TipMsg(text)
            end
            return false
        end
        
        conditionId = XMVCA.XBigWorldSkipFunction:GetSkipFinishConditionIdBySkipId(self:GetId())
        if XTool.IsNumberValid(conditionId) then
            --完成了就不跳转了
            local isFinish, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
            if isFinish then
                return false
            end
        end

        return true
    end

    return false
end

function XBWSkipBase:SkipTo(isNoTips, skipParams)
    if self:IsAllowSkip(isNoTips) then
        return self:Skip(skipParams or table.empty)
    end

    return false
end

function XBWSkipBase:Skip(skipParams)
    -- 重写该方法更加安全
    return false
end

return XBWSkipBase
