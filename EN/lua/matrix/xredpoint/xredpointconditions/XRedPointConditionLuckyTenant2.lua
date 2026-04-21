local XRedPointConditionLuckyTenant2 = {}

--- 幸运租客二期红点检测
---@return boolean 是否显示红点
function XRedPointConditionLuckyTenant2.Check()
    return XMVCA.XLuckyTenant2:IsShowRedDot()
end

return XRedPointConditionLuckyTenant2
