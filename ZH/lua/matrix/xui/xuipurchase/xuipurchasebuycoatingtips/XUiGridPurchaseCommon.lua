local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---
---@class XUiGridPurchaseCommon: XUiGridCommon
local XUiGridPurchaseCommon = XClass(XUiGridCommon, 'XUiGridPurchaseCommon')

function XUiGridPurchaseCommon:Ctor(rootUi, ui)
    XUiHelper.InitUiClass(self, ui)
end

return XUiGridPurchaseCommon