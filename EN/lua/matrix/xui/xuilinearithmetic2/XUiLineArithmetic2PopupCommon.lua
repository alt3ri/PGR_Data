---@class XUiLineArithmetic2PopupCommon : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2PopupCommon = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2PopupCommon")

function XUiLineArithmetic2PopupCommon:Ctor()
    self._Callback = false
end

function XUiLineArithmetic2PopupCommon:OnStart(callback, text)
    self._Callback = callback
    if text then
        self.Txt.text = text
    end
end

function XUiLineArithmetic2PopupCommon:OnAwake()
    self:RegisterClickEvent(self.BtnNext, self.OnClickYes)
    self:RegisterClickEvent(self.BtnAgain, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
end

function XUiLineArithmetic2PopupCommon:OnClickYes()
    self:Close()
    if self._Callback then
        self._Callback()
    end
end

return XUiLineArithmetic2PopupCommon