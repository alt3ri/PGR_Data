---@class XHelpCourseModel : XModel
local XHelpCourseModel = XClass(XModel, "XHelpCourseModel")

local TableNormal = {
    HelpCourse = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    HelpCourseFunctionMap = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Function", ReadFunc = XConfigUtil.ReadType.String },
    HelpCourseTextGroup = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
}

function XHelpCourseModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey('HelpCourse', TableNormal, XConfigUtil.CacheType.Normal)
end

function XHelpCourseModel:ClearPrivate()

end

function XHelpCourseModel:ResetAll()

end

--region Configs

---@return XTableHelpCourse
function XHelpCourseModel:GetHelpCourseCfgById(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.HelpCourse, id, noTips)
end

function XHelpCourseModel:GetHelpCourseCfgByFunction(key, noTips)
    local funcMapCfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.HelpCourseFunctionMap, key, noTips)
    
    if funcMapCfg then
        return self:GetHelpCourseCfgById(funcMapCfg.Id)
    end
end

---@return XTableHelpCourseTextGroup
function XHelpCourseModel:GetHelpCourseTextGroupCfgById(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.HelpCourseTextGroup, id, noTips)
end
--endregion

return XHelpCourseModel