
---@class XUiGirdBigWorldProcessCoreExtra : XUiNode
---@field Parent XUiBigWorldProcessCoreActivity
local XUiGirdBigWorldProcessCoreExtra = XClass(XUiNode, "XUiGirdBigWorldProcessCoreExtra")

function XUiGirdBigWorldProcessCoreExtra:OnStart()
end

function XUiGirdBigWorldProcessCoreExtra:Update(data, index)
    local entryType = self.Parent:GetEntity():GetEntryType()
    if entryType == XMVCA.XBigWorldCourse.CoreEntryType.InviteQuest then
        self:_RefreshInvite(data, index)
    elseif entryType == XMVCA.XBigWorldCourse.CoreEntryType.EnvironmentQuest then
        self:_RefreshEnvironment(data, index)
    end
end

function XUiGirdBigWorldProcessCoreExtra:_RefreshInvite(inviteId, index)
    self.RImgIcon:SetRawImage(XMVCA.XBigWorldQuest:GetInviteQuestRoleIcon(inviteId))
    self.TxtExtra.text = string.format("%s/%s", XMVCA.XBigWorldQuest:GetInviteProgress(inviteId))
end

function XUiGirdBigWorldProcessCoreExtra:_RefreshEnvironment(environmentId, index)
    self.RImgIcon:SetRawImage(XMVCA.XBigWorldQuest:GetEnvironmentQuestRoleIcon(environmentId))
    self.TxtExtra.text = string.format("%s/%s", XMVCA.XBigWorldQuest:GetEnvironmentProgress(environmentId))
end

return XUiGirdBigWorldProcessCoreExtra