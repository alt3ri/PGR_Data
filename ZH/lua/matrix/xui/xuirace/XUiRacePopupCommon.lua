---@class XUiRacePopupCommon : XLuaUi 弹框
---@field _Control XRaceControl
local XUiRacePopupCommon = XLuaUiManager.Register(XLuaUi, "UiRacePopupCommon")

function XUiRacePopupCommon:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnClose.CallBack = handler(self, self.OnBtnCloseClick)
    self.BtnSure.CallBack = handler(self, self.OnBtnSureClick)
end

function XUiRacePopupCommon:OnStart(title, content, closeCb, sureCb)
    self.TxtTitle.text = title
    self.TxtContent.text = content
    self._CloseCb = closeCb
    self._SureCb = sureCb

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
end

function XUiRacePopupCommon:OnBtnCloseClick()
    if self._CloseCb then
        self._CloseCb()
    end
    self:Close()
end

function XUiRacePopupCommon:OnBtnSureClick()
    if self._SureCb then
        self._SureCb()
    end
    self:Close()
end

return XUiRacePopupCommon