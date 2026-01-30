local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipQuestEnvironmentPopup : XBWSkipBase 跳转到玩法主界面
local XBWSkipQuestEnvironmentPopup = XClass(XBWSkipBase, "XBWSkipQuestEnvironmentPopup")

function XBWSkipQuestEnvironmentPopup:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return false
    end

    local environmentId = params[1]
    XMVCA.XBigWorldQuest:OpenEnvironmentPopupView(environmentId)

    return true
end

return XBWSkipQuestEnvironmentPopup