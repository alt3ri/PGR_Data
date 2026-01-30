--- mini章节红点
local XRedPointSoloReformChapter = {}

function XRedPointSoloReformChapter.Check(chapterId)
   if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SoloReform, true, true) then
        return false
    end
    
    return XMVCA.XSoloReform:CheckChapterReddot(chapterId)    
end

return XRedPointSoloReformChapter