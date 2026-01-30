---@class XUiDlcMultiPlayerExchangeGrid : XUiNode
---@field RImgHeadIcon UnityEngine.UI.RawImage
---@field PanelSelected UnityEngine.RectTransform
---@field PanelFavorability UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field TxtTradeName UnityEngine.UI.Text
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerExchangeGrid = XClass(XUiNode, "XUiDlcMultiPlayerExchangeGrid")

-- region 生命周期

function XUiDlcMultiPlayerExchangeGrid:OnStart()
    self.PanelFavorability.gameObject:SetActiveEx(false)
end

-- endregion

function XUiDlcMultiPlayerExchangeGrid:Refresh(characterId, isSelect)
    self.RImgHeadIcon:SetRawImage(self._Control:GetCharacterCuteHeadIconByCharacterId(characterId))
    self.TxtName.text = self._Control:GetCharacterNameByCharacterId(characterId)
    self.TxtNameSelect.text = self._Control:GetCharacterNameByCharacterId(characterId)
    self.TxtTradeName.text = self._Control:GetCharacterTradeNameByCharacterId(characterId)
    self.TxtTradeNameSelect.text = self._Control:GetCharacterTradeNameByCharacterId(characterId)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.PanelTxtNormal.gameObject:SetActiveEx(not isSelect)
    self.PanelTxtSelected.gameObject:SetActiveEx(isSelect)
end

function XUiDlcMultiPlayerExchangeGrid:OnSelected(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.PanelTxtNormal.gameObject:SetActiveEx(not isSelect)
    self.PanelTxtSelected.gameObject:SetActiveEx(isSelect)
end

return XUiDlcMultiPlayerExchangeGrid
