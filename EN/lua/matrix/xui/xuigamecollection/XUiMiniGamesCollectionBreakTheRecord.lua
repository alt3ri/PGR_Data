---@class XUiMiniGamesCollectionBreakTheRecord : XLuaUi
---@field _Control XGameCollectionControl
local XUiMiniGamesCollectionBreakTheRecord = XLuaUiManager.Register(XLuaUi, 'UiMiniGamesCollectionBreakTheRecord')

function XUiMiniGamesCollectionBreakTheRecord:OnAwake()
    self.BtnTanchuangClose:AddEventListener(handler(self,self.Close))
    self.BtnTanchuangCloseBig:AddEventListener(handler(self,self.Close))
end

function XUiMiniGamesCollectionBreakTheRecord:OnStart(gameName, newScore)
    self._GameName = gameName or ''
    self._NewScore = newScore or 0
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
end

return XUiMiniGamesCollectionBreakTheRecord
