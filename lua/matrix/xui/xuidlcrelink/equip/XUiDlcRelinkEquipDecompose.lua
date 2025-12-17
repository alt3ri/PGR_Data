---@class XUiDlcRelinkEquipDecompose : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkEquipDecompose = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipDecompose")

function XUiDlcRelinkEquipDecompose:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkEquipDecompose:OnStart()

end

function XUiDlcRelinkEquipDecompose:OnEnable()

end

function XUiDlcRelinkEquipDecompose:OnGetEvents()

end

function XUiDlcRelinkEquipDecompose:OnGetLuaEvents()

end

function XUiDlcRelinkEquipDecompose:OnNotify(event, ...)

end

function XUiDlcRelinkEquipDecompose:OnDisable()

end

function XUiDlcRelinkEquipDecompose:OnDestroy()

end

function XUiDlcRelinkEquipDecompose:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiDlcRelinkEquipDecompose:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkEquipDecompose:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiDlcRelinkEquipDecompose
