local XUiPanelAccountSetOverSea = XClass(XUiNode, "XUiPanelAccountSetOverSea")

function XUiPanelAccountSetOverSea:OnStart()
    self:AddListener()
end

function XUiPanelAccountSetOverSea:AddListener()
    XUiHelper.RegisterClickEvent(self, self.KuroBind, self.OnKuroBind)
    XUiHelper.RegisterClickEvent(self, self.BackLogin, self.OnLogout)
end

function XUiPanelAccountSetOverSea:OnKuroBind()
    CS.XHeroSdkAgent.ShowUserCenter()
end

function XUiPanelAccountSetOverSea:OnLogout()
    XUserManager.Logout()
end

return XUiPanelAccountSetOverSea