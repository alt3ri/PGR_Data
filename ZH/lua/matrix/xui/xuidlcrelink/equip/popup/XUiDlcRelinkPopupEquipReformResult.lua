local XUiGridDlcRelinkEquipAttribute = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipAttribute")
---@class XUiDlcRelinkPopupEquipReformResult : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupEquipReformResult = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipReformResult")

function XUiDlcRelinkPopupEquipReformResult:OnAwake()
    self:RegisterUiEvents()
end

---@param attributeSlot XDlcRelinkEquipAttributeSlot
function XUiDlcRelinkPopupEquipReformResult:OnStart(attributeSlot)
    if not attributeSlot or XTool.IsTableEmpty(attributeSlot.Attributes) then
        return
    end

    local attrCount = #attributeSlot.Attributes
    self.GridAttribute1.gameObject:SetActiveEx(attrCount >= 1)
    local hasSecond = attrCount >= 2
    self.Line.gameObject:SetActiveEx(hasSecond)
    self.GridAttribute2.gameObject:SetActiveEx(hasSecond)

    for i = 1, math.min(attrCount, 2) do
        ---@type XUiGridDlcRelinkEquipAttribute
        local grid = XUiGridDlcRelinkEquipAttribute.New(self["GridAttribute" .. i], self)
        grid:Open()
        grid:Refresh2(attributeSlot.Attributes[i])
    end
end

function XUiDlcRelinkPopupEquipReformResult:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
end

function XUiDlcRelinkPopupEquipReformResult:OnBtnBackClick()
    self:Close()
end

return XUiDlcRelinkPopupEquipReformResult
