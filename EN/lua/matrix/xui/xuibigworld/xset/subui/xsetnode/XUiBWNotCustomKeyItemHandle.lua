local XUiBWBtnKeyItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWBtnKeyItem")
local XUiBWNotCustomKeyItemHandle = XClass(XUiBWBtnKeyItem, "XUiBWNotCustomKeyItemHandle")

function XUiBWNotCustomKeyItemHandle:OnStart()
    self.Super.OnStart(self)
    self.BtnClear.gameObject:SetActiveEx(false)
end

function XUiBWNotCustomKeyItemHandle:Refresh(data, cb, resetTextOnly, curInputMapId, curOperationType)
    self.Super.Refresh(self, data, cb, resetTextOnly, curInputMapId, curOperationType)
    self.GroupRecommend.gameObject:SetActiveEx(false)
end

function XUiBWNotCustomKeyItemHandle:SetRecommendText(operationKey)
    self.Super.SetRecommendText(self, operationKey)
    self.GroupRecommend.gameObject:SetActiveEx(false)
end

return XUiBWNotCustomKeyItemHandle