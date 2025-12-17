---@class XHelpCourseAgency : XAgency
---@field private _Model XHelpCourseModel
local XHelpCourseAgency = XClass(XAgency, "XHelpCourseAgency")
function XHelpCourseAgency:OnInit()

end

function XHelpCourseAgency:InitRpc()

end

function XHelpCourseAgency:InitEvent()

end

--region Configs 

function XHelpCourseAgency:GetHelpCourseCfgById(id, noTips)
    return self._Model:GetHelpCourseCfgById(id, noTips)
end

function XHelpCourseAgency:GetHelpCourseCfgByFunction(key, noTips)
    return self._Model:GetHelpCourseCfgByFunction(key, noTips)
end

function XHelpCourseAgency:GetHelpCourseImageAssetCountByFunction(functionName)
    local cfg = self._Model:GetHelpCourseCfgByFunction(functionName)

    if cfg then
        return #cfg.ImageAsset
    end

    return 0
end

--endregion

return XHelpCourseAgency