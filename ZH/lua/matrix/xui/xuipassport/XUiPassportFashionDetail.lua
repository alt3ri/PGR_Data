local XUiFashionDetail = require("XUi/XUiFashion/XUiFashionDetail")

local XUiPassportFashionDetail = XLuaUiManager.Register(
    XUiFashionDetail,
    "UiPassportFashionDetail")

function XUiPassportFashionDetail:OnAwake()
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnBuy = self.BtnPassport
    XUiFashionDetail.OnAwake(self)
end

return XUiPassportFashionDetail
