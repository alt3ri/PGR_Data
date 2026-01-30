---@class XHelpCourseControl : XControl
---@field private _Model XHelpCourseModel
local XHelpCourseControl = XClass(XControl, "XHelpCourseControl")
function XHelpCourseControl:OnInit()

end

function XHelpCourseControl:AddAgencyEvent()

end

function XHelpCourseControl:RemoveAgencyEvent()

end

function XHelpCourseControl:OnRelease()

end

--region Configs

---@return XTableHelpCourseTextGroup
function XHelpCourseControl:GetHelpCourseTextGroupCfgById(id, noTips)
    return self._Model:GetHelpCourseTextGroupCfgById(id, noTips)
end

function XHelpCourseControl:GetSubHelpCourseIdsById(id, noTips)
    local cfg = self._Model:GetHelpCourseCfgById(id, noTips)

    if cfg then
        return cfg.SubIds
    end
end

--- 获取子图文，但追加子图文类型检查
function XHelpCourseControl:TryGetSubHelpCourseIdsById(id, noTips)
    local cfg = self._Model:GetHelpCourseCfgById(id, noTips)

    if cfg then
        local result = {}

        for i, v in ipairs(cfg.SubIds) do
            local subCfg = self._Model:GetHelpCourseCfgById(v)

            if subCfg then
                if subCfg.IsShowCourse == XEnumConst.HelpCourse.UiHelpType.PopStyle then
                    table.insert(result, v)
                else
                    XLog.Error('集合式图文中，子图文Id：'..tostring(v)..' 的图文配置不是弹窗式类型，不予显示')
                end
            end
        end
        return result
    end
end
--endregion

return XHelpCourseControl