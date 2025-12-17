---@class XUiDlcRelinkPopupFilter : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupFilter = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupFilter")

function XUiDlcRelinkPopupFilter:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupFilter:OnStart()

end

function XUiDlcRelinkPopupFilter:OnEnable()

end

function XUiDlcRelinkPopupFilter:OnGetEvents()

end

function XUiDlcRelinkPopupFilter:OnGetLuaEvents()

end

function XUiDlcRelinkPopupFilter:OnNotify(event, ...)

end

function XUiDlcRelinkPopupFilter:OnDisable()

end

function XUiDlcRelinkPopupFilter:OnDestroy()

end

function XUiDlcRelinkPopupFilter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiDlcRelinkPopupFilter:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkPopupFilter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiDlcRelinkPopupFilter
