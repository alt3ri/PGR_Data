--- 肉鸽5 PVE入口提示红点
local XRedPoinTheatre5PVENewActivity = {}

function XRedPoinTheatre5PVENewActivity.Check()
    -- 先判断活动是否开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end
    
    return XMVCA.XTheatre5:CheckHasNewPVEActivityReddot()
end

return XRedPoinTheatre5PVENewActivity