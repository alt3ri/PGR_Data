---@class XUiDlcRelinkToastResearchUp : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkToastResearchUp = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkToastResearchUp")

function XUiDlcRelinkToastResearchUp:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiDlcRelinkToastResearchUp:OnStart(oldLevel, curLevel)
    self.TxtOldLv.text = oldLevel
    self.TxtCurLv.text = curLevel
end

function XUiDlcRelinkToastResearchUp:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkToastResearchUp
