local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipQuestMain : XBWSkipBase 跳转到玩法主界面
local XBWSkipQuestMain = XClass(XBWSkipBase, "XBWSkipQuestMain")

function XBWSkipQuestMain:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return
    end

    local questId = params[1]

    XMVCA.XBigWorldQuest:OpenQuestMain(1, questId)
end

return XBWSkipQuestMain