---@class XUiGridRelinkPopupChooseCharacter : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridRelinkPopupChooseCharacter = XClass(XUiNode, "XUiGridRelinkPopupChooseCharacter")

function XUiGridRelinkPopupChooseCharacter:GetCharacterId()
    return self.CharacterId
end

function XUiGridRelinkPopupChooseCharacter:Refresh(characterId)
    self.CharacterId = characterId
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterName(self.CharacterId)
    self.TxtTradeName.text = XMVCA.XCharacter:GetCharacterTradeName(self.CharacterId)
end

function XUiGridRelinkPopupChooseCharacter:OnSelected(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

return XUiGridRelinkPopupChooseCharacter
