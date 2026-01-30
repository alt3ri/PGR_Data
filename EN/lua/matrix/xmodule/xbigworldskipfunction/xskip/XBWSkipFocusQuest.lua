local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipFocusQuest : XBWSkipBase 跳转到玩法主界面
local XBWSkipFocusQuest = XClass(XBWSkipBase, "XBWSkipFocusQuest")

function XBWSkipFocusQuest:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return false
    end
    
    local questId = params[1] or 0

    if XTool.IsNumberValid(questId) then
        local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)

        if questData then
            if questData:GetState() == XMVCA.XBigWorldQuest.QuestState.Ready then
                return XMVCA.XBigWorldMap:OpenBigWorldMapUiAnchorQuest(questId, false, true)
            elseif questData:GetState() == XMVCA.XBigWorldQuest.QuestState.InProgress then
                XMVCA.XBigWorldQuest:OpenQuestMain(1, questId)

                return true
            end
        end
    end

    return false
end

return XBWSkipFocusQuest