---@class XUiDlcRelinkEquipReform : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkEquipReform = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipReform")

function XUiDlcRelinkEquipReform:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkEquipReform:OnStart()

end

function XUiDlcRelinkEquipReform:OnEnable()

end

function XUiDlcRelinkEquipReform:OnGetEvents()

end

function XUiDlcRelinkEquipReform:OnGetLuaEvents()

end

function XUiDlcRelinkEquipReform:OnNotify(event, ...)

end

function XUiDlcRelinkEquipReform:OnDisable()

end

function XUiDlcRelinkEquipReform:OnDestroy()

end

function XUiDlcRelinkEquipReform:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiDlcRelinkEquipReform:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkEquipReform:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiDlcRelinkEquipReform
