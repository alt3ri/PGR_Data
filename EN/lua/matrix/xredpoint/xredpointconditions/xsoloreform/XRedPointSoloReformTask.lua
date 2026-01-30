--- mini任务红点
local XRedPointSoloReformTask = {}

function XRedPointSoloReformTask.Check()
   if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SoloReform, true, true) then
        return false
    end
    
    return XMVCA.XSoloReform:CheckTaskReddot()    
end

return XRedPointSoloReformTask