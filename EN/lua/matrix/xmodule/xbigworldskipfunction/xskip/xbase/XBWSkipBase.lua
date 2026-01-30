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

function XBWSkipBase:SkipTo(isNoTips, ...)
    if self:IsAllowSkip(isNoTips) then
        return self:Skip(...)
    end

    return false
end

function XBWSkipBase:Skip(...)
    -- 重写该方法更加安全
    return false
end

return XBWSkipBase
