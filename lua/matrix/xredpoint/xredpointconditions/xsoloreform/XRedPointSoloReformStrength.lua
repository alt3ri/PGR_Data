--- mini强化红点
local XRedPointSoloReformStrength = {}

function XRedPointSoloReformStrength.Check(data)
   if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SoloReform, true, true) then
        return false
    end
    if XTool.IsTableEmpty(data) or #data ~= 2 then
        return false
    end    
    
    return XMVCA.XSoloReform:CheckStrengthReddot(data[1], data[2])    
end

return XRedPointSoloReformStrength