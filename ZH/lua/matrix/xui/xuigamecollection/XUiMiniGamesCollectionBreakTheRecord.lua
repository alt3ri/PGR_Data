---@class XUiMiniGamesCollectionBreakTheRecord : XLuaUi
---@field _Control XGameCollectionControl
local XUiMiniGamesCollectionBreakTheRecord = XLuaUiManager.Register(XLuaUi, 'UiMiniGamesCollectionBreakTheRecord')

function XUiMiniGamesCollectionBreakTheRecord:OnAwake()
    local function onClose()
        self:Close()
        if self.CloseCb then self.CloseCb() end
    end
    self.BtnTanchuangClose:AddEventListener(onClose)
    self.BtnTanchuangCloseBig:AddEventListener(onClose)
end

function XUiMiniGamesCollectionBreakTheRecord:OnStart(gameName, newScore, closeCb)
    self._GameName = gameName or ''
    self._NewScore = newScore or 0
    self.CloseCb = closeCb
    self:RefreshDisplay()
end

function XUiMiniGamesCollectionBreakTheRecord:RefreshDisplay()
    if self.TxtTitle then
        self.TxtTitle.text = XUiHelper.GetText("GameCollectionBreakRecordTitle",self._GameName)
    end

    if self.TxtScore then
        self.TxtScore.text = tostring(self._NewScore)
    end
end

function XUiMiniGamesCollectionBreakTheRecord:OnBtnConfirmClick()
    self:Close()
    if self.CloseCb then self.CloseCb() end
end

return XUiMiniGamesCollectionBreakTheRecord
