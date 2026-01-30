local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipQuestInvite : XBWSkipBase 跳转到玩法主界面
local XBWSkipQuestInvite = XClass(XBWSkipBase, "XBWSkipQuestInvite")

function XBWSkipQuestInvite:Skip()
    --策划要求，如果有领取的邀约任务，则跳转到任务界面，否则跳转到邀约界面
    if XMVCA.XBigWorldQuest:IsUnderTakenInviteQuest() then
        XMVCA.XBigWorldQuest:OpenQuestMainByType(XMVCA.XBigWorldQuest.QuestType.Invitation)
    else
        XMVCA.XBigWorldQuest:OpenInvitationView()
    end

    return true
end

return XBWSkipQuestInvite