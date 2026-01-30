--- 肉鸽5活动参与提示蓝点
local XRedPointTheatre5NewActivity = {}

function XRedPointTheatre5NewActivity.Check()
    -- 先判断活动是否开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end
    
    return XMVCA.XTheatre5:CheckHasNoEnterReddot()
end

return XRedPointTheatre5NewActivity