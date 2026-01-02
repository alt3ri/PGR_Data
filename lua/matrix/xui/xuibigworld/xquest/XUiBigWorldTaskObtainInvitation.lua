
local XUiBigWorldTaskObtain = require("XUi/XUiBigWorld/XQuest/XUiBigWorldTaskObtain")

---@class XUiBigWorldTaskObtainInvitation : XUiBigWorldTaskObtain
local XUiBigWorldTaskObtainInvitation = XMVCA.XBigWorldUI:Register(XUiBigWorldTaskObtain, "UiBigWorldTaskObtainInvitation")

function XUiBigWorldTaskObtainInvitation:InitView()
    local questId = self._QuestId
    local typeId = self._Control:GetQuestType(questId)
    self.TxtTitle.text = self._Control:GetQuestTypeName(typeId)
    if self.ImgIcon then
        local sprite = self._Control:GetQuestIcon(questId)
        if string.IsNilOrEmpty(sprite) then
            XLog.Error(string.format("任务:%s 未配置任务图标", questId))
        else
            self.ImgIcon:SetSprite(sprite)
        end
    end

    local icon = XMVCA.XBigWorldQuest:GetInviteQuestRoleIcon(questId)
    if self.ImgHeadBg and not string.IsNilOrEmpty(icon) then
        self.ImgHeadBg:SetRawImage(icon)
    end
end