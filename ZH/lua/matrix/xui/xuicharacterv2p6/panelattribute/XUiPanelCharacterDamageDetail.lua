---@class XUiPanelCharacterDamageDetail : XUiNode
local XUiPanelCharacterDamageDetail = XClass(XUiNode, "XUiPanelCharacterDamageDetail")

function XUiPanelCharacterDamageDetail:OnStart()
    self:InitInfo()
end

function XUiPanelCharacterDamageDetail:InitInfo()
    self.TxtDesc01.text = XUiHelper.ConvertLineBreakSymbol(XMVCA.XCharacter:GetClientConfig("CharacterDamageDesc1"))
    self.TxtDesc02.text = XUiHelper.ConvertLineBreakSymbol(XMVCA.XCharacter:GetClientConfig("CharacterDamageDesc2"))
    for i = 1, 2 do
        local row = self["TxtRow0" .. i]
        if row then
            row.text = XMVCA.XCharacter:GetClientConfig("CharacterDamageRow", i)
        end
    end
    for i = 1, 6 do
        local col = self["TxtColumn0" .. i]
        if col then
            col.text = XMVCA.XCharacter:GetClientConfig("CharacterDamageColumn", i)
        end
    end
    for i = 1, 5 do
        local other = self["Txt0" .. i]
        if other then
            other.text = XMVCA.XCharacter:GetClientConfig("CharacterDamageOther", i)
        end
    end
end

return XUiPanelCharacterDamageDetail
