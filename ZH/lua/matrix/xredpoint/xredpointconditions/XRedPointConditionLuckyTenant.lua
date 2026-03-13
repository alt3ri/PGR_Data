local XRedPointConditionLuckyTenant = {}

function XRedPointConditionLuckyTenant.Check()
    return XMVCA.XLuckyTenant:IsShowRedDot()
end

return XRedPointConditionLuckyTenant
