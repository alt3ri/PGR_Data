---@class XUiTheatre6PopupNewContent : XLuaUi 养成预览弹窗
---@field _Control XTheatre6Control
local XUiTheatre6PopupNewContent = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupNewContent")

function XUiTheatre6PopupNewContent:OnAwake()
    self.BtnBack:AddEventListener(Handler(self, self.Close))
    self.BtnTanchuangCloseWhite:AddEventListener(Handler(self, self.Close))
end

return XUiTheatre6PopupNewContent
