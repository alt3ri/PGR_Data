--- 肉鸽5 PVP新赛季提示红点
local XRedPoinTheatre5PVPNewActivity = {}

function XRedPoinTheatre5PVPNewActivity.Check()
    -- 先判断活动是否开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end
    
    -- 判断是否过了PVE教学
    if XMVCA.XTheatre5:IsInTeachingStoryLine() then
        return false
    end
    
    -- 再判断是否在赛季时间内
    if not XMVCA.XTheatre5:CheckInPVPActivityTime() then
        return false
    end
    
    return XMVCA.XTheatre5:CheckHasNewPVPActivityReddot()
end

return XRedPoinTheatre5PVPNewActivity