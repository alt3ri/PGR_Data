---@class XUiGridDlcRelinkCharacter : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkCharacter = XClass(XUiNode, "XUiGridDlcRelinkCharacter")

function XUiGridDlcRelinkCharacter:OnStart()
    self.TxtNow.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiGridDlcRelinkCharacter:Refresh(characterId)
    self.CharacterId = characterId
    self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    -- TODO 等级
    local occupationType = self._Control:GetOccupationTypeByCharacterId(characterId)
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", occupationType) or ""
    if not string.IsNilOrEmpty(occupationIcon) then
        self.RImgType:SetRawImage(occupationIcon)
    end
end

function XUiGridDlcRelinkCharacter:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiGridDlcRelinkCharacter:SetNow(isNow)
    self.TxtNow.gameObject:SetActiveEx(isNow)
end

return XUiGridDlcRelinkCharacter
