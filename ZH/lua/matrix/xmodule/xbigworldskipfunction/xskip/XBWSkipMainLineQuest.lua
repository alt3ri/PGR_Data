local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipMainLineQuest : XBWSkipBase 跳转到主线关卡章节界面
local XBWSkipMainLineQuest = XClass(XBWSkipBase, "XBWSkipMainLineQuest")

function XBWSkipMainLineQuest:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return false
    end

    local chapterId = params[1] or 0

    if not XTool.IsNumberValid(chapterId) then
        XLog.Error("跳转失败, chapterId无效! chapterId: " .. tostring(chapterId))
        return false
    end

    local canOpen, tips = XMVCA.XMainLine2:CheckCanOpenChapter(chapterId)
    if not canOpen then
        XLog.Warning("跳转主线章节失败, chapterId: " .. tostring(chapterId) .. ", 原因: " .. tostring(tips))
        return false
    end

    XMVCA.XBigWorldGamePlay:ExitWorld()
    XMVCA.XMainLine2:SkipToMainLine2(chapterId)

    return true
end

return XBWSkipMainLineQuest
