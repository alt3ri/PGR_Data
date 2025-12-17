
local XUiBigWorldBlackMaskLoading = require("XUi/XUiBigWorld/XLoading/XUiBigWorldBlackMaskLoading")

---@class XUiBigWorldBlackMaskNormal : XUiBigWorldBlackMaskLoading
---@field _Control
local XUiBigWorldBlackMaskNormal = XMVCA.XBigWorldUI:Register(XUiBigWorldBlackMaskLoading, "UiBigWorldBlackMaskNormal")

function XUiBigWorldBlackMaskNormal:IsSetMask()
    return false
end

function XUiBigWorldBlackMaskNormal:IsRegisterX3CClose()
    return false
end

