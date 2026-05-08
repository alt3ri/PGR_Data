---@class XUiGameCollectionRecord : XLuaUi
---@field _Control XGameCollectionControl
local XUiGameCollectionRecord = XLuaUiManager.Register(XLuaUi, 'UiGameCollectionRecord')

function XUiGameCollectionRecord:OnAwake()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiGameCollectionRecord:OnStart(gameName, newScore)
    self._GameName = gameName or ''
    self._NewScore = newScore or 0
    self:RefreshDisplay()
end

function XUiGameCollectionRecord:RefreshDisplay()
    if self.TxtGameName then
        self.TxtGameName.text = self._GameName
    end

    if self.TxtNewScore then
        self.TxtNewScore.text = tostring(self._NewScore)
    end
end

function XUiGameCollectionRecord:OnBtnConfirmClick()
    self:Close()
end

return XUiGameCollectionRecord
