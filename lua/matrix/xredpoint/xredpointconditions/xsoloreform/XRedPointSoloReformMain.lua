--- mini主红点
local XRedPointSoloReformMain = {}

function XRedPointSoloReformMain.Check()
   if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SoloReform, true, true) then
        return false
    end
    
    local hasTaskReddot = XMVCA.XSoloReform:CheckTaskReddot()
    if hasTaskReddot then
        return true
    end    
    local allChapterCfgs = XMVCA.XSoloReform:GetAllShowChapterCfgs()
    for _, chapterCfg in pairs(allChapterCfgs) do
        if XMVCA.XSoloReform:CheckChapterReddot(chapterCfg.Id) then
            return true
        end    
    end
    return false
end

return XRedPointSoloReformMain