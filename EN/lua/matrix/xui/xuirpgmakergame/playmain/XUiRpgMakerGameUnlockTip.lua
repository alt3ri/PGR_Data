local XUiRpgMakerGameUnlockTip = XClass(nil, "XUiRpgMakerGameUnlockTip")

function XUiRpgMakerGameUnlockTip:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BgDark, self.Hide)
end

function XUiRpgMakerGameUnlockTip:Show(unlockRoleId)
    self:Refresh(unlockRoleId)
    self.GameObject:SetActiveEx(true)
end

function XUiRpgMakerGameUnlockTip:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiRpgMakerGameUnlockTip:Refresh(unlockRoleId)
    local name = XMVCA.XRpgMakerGame:GetConfig():GetRoleName(unlockRoleId)
    local style = XMVCA.XRpgMakerGame:GetConfig():GetRoleStyle(unlockRoleId)
    self.TextName.text = name .. "·" .. style

    local headPath = XMVCA.XRpgMakerGame:GetConfig():GetRoleHeadPath(unlockRoleId)
    self.StandIcon:SetRawImage(headPath)
end

return XUiRpgMakerGameUnlockTip