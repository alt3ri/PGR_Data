---@class XUiGridBWFashionColor : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldCoating
local XUiGridBWFashionColor = XClass(XUiNode, "XUiGridBWFashionColor")

function XUiGridBWFashionColor:OnStart()
    self._Index = 0
    self._ColorId = 0
    self._FashionId = 0
    self.BtnClick:AddEventListener(Handler(self, self.OnBtnClick))
end

function XUiGridBWFashionColor:Refresh(fashionId, colorId, isCurrent, index)
    self._FashionId = fashionId
    self._Index = index
    self._ColorId = colorId
    self.ImgColour.color = XMVCA.XBigWorldCharacter:GetFashionColor(fashionId, colorId)
    self.PanelNow.gameObject:SetActiveEx(isCurrent)
    self:SetSelect(isCurrent)
end

function XUiGridBWFashionColor:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiGridBWFashionColor:OnBtnClick()
    self:SetSelect(true)
    self.Parent:OnColorSelect(self._Index, self._ColorId)
end

return XUiGridBWFashionColor
