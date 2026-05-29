---@class XUiGoldenMinerGiveUp : XLuaUi
---@field _Control XGameCollectionControl
local XUiGoldenMinerGiveUp = XLuaUiManager.Register(XLuaUi, 'UiGoldenMinerGiveUp')

function XUiGoldenMinerGiveUp:OnAwake()
    self.BtnConfirm:AddEventListener(handler(self,self.OnClickBtnConfirm))
    self.BtnClose:AddEventListener(handler(self,self.Close))
end

function XUiGoldenMinerGiveUp:OnStart(title,context,surecb)
    self.TxtTitle.text = title
    self.TxtInfoNormal.text = context
    self.SureCb = surecb
end

function XUiGoldenMinerGiveUp:OnClickBtnConfirm()
    if self.SureCb then
        self.SureCb()
    end
    self:Close()

end


return XUiGoldenMinerGiveUp
