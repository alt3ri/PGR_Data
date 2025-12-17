local CSXTextManagerGetText = CS.XTextManager.GetText

--图标的说明
local XUiGridRpgMakerGameRecord = XClass(nil, "XUiGridRpgMakerGameRecord")

function XUiGridRpgMakerGameRecord:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiGridRpgMakerGameRecord:Refresh(hintIconKey)
    local icon = XMVCA.XRpgMakerGame:GetConfig():GetHintIcon(hintIconKey)
    self.ImgIconContent:SetRawImage(icon)

    local iconName = XMVCA.XRpgMakerGame:GetConfig():GetHintName(hintIconKey)
    self.TxtContent.text = iconName
end

return XUiGridRpgMakerGameRecord