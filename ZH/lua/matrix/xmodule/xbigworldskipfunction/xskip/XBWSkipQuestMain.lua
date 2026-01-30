local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipQuestMain : XBWSkipBase 跳转到玩法主界面
local XBWSkipQuestMain = XClass(XBWSkipBase, "XBWSkipQuestMain")

function XBWSkipQuestMain:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return false
    end
    local questId
    local index = 1
    while true do
        questId = params[index]
        if not questId or questId <= 0 then
            break
        end
        local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)
        if questData and questData:IsInProgress() then
            break
        end
        index = index + 1
    end
    XMVCA.XBigWorldQuest:OpenQuestMain(1, questId)

    return true
end

return XBWSkipQuestMain