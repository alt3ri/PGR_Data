---@class XHelpCourseAgency : XAgency
---@field private _Model XHelpCourseModel
local XHelpCourseAgency = XClass(XAgency, "XHelpCourseAgency")
function XHelpCourseAgency:OnInit()

end

function XHelpCourseAgency:InitRpc()

end

function XHelpCourseAgency:InitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_OPEN_HELP_COURSE, self.OpenHelpCourseUiById, self)
end

function XHelpCourseAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_OPEN_HELP_COURSE, self.OpenHelpCourseUiById, self)
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

function XHelpCourseAgency:OpenHelpCourseUiById(id, jumpIndex, cb, closeCb)
    if type(id) == "string" and string.IsNumeric(id) then
        id = tonumber(id)
    end

    if type(jumpIndex) == "string" and string.IsNumeric(jumpIndex) then
        jumpIndex = tonumber(jumpIndex)
    end
    
    local config = self:GetHelpCourseCfgById(id)
    
    if not config then
        return
    end

    if config.IsShowCourse == XEnumConst.HelpCourse.UiHelpType.Default then
        XLuaUiManager.Open("UiHelp", config, cb, jumpIndex, closeCb)
    elseif config.IsShowCourse == XEnumConst.HelpCourse.UiHelpType.SimpleContent then
        XUiManager.UiFubenDialogTip(config.Name, config.Describe)
    elseif config.IsShowCourse == XEnumConst.HelpCourse.UiHelpType.PopStyle then
        XLuaUiManager.Open("UiPopupTeach", config, cb, jumpIndex, closeCb)
    elseif config.IsShowCourse == XEnumConst.HelpCourse.UiHelpType.Collections then
        XLuaUiManager.Open("UiCollectionTeach", config, cb, jumpIndex, closeCb)
    end
end

return XHelpCourseAgency