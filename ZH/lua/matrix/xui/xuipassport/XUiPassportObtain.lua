local XUiObtain = require("XUi/XUiObtain/XUiObtain")

---@class XUiPassportObtain:XUiObtain
local XUiPassportObtain = XLuaUiManager.Register(XUiObtain, "UiPassportObtain")

function XUiPassportObtain:OnAwake()
    XUiPassportObtain.Super.OnAwake(self)
    self.TxtRule = self.Transform:Find("SafeAreaContentPane/TxtRule"):GetComponent("Text")
    self.TxtRule.text = CS.XTextManager.GetText("PassportObtain")
end

return XUiPassportObtain
