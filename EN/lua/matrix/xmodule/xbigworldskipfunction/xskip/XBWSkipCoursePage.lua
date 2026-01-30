local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipCoursePage : XBWSkipBase 跳转到玩法主界面
local XBWSkipCoursePage = XClass(XBWSkipBase, "XBWSkipCoursePage")

function XBWSkipCoursePage:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return false
    end
    
    local isInternal = XTool.IsNumberValid(params[1])
    local contentId = params[2] or 0

    if XTool.IsNumberValid(contentId) then
        if isInternal then
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_CHANGE_PAGE, contentId)

            return true
        else
            return XMVCA.XBigWorldCourse:OpenMainUi(contentId)
        end
    end

    return false
end

return XBWSkipCoursePage