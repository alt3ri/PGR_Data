---@class XUiGridDlcRelinkPopupFilterTab : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkPopupFilterTab = XClass(XUiNode, "XUiGridDlcRelinkPopupFilterTab")

function XUiGridDlcRelinkPopupFilterTab:Refresh(factorId)
    self.FactorId = factorId
    local name = self._Control:GetFactorDescName(factorId)
    self.TxtType1.text = name
    self.TxtType2.text = name
end

function XUiGridDlcRelinkPopupFilterTab:SetSelect(isSelect)
    self.Normal.gameObject:SetActiveEx(not isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

return XUiGridDlcRelinkPopupFilterTab
