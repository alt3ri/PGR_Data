local XBigWorldUiImpactBase = require("XModule/XBigWorldUI/Impact/XBigWorldUiImpactBase")

---@class XBigWorldUiBlockImpact : XBigWorldUiImpactBase
local XBigWorldUiBlockImpact = XClass(XBigWorldUiImpactBase, "XBigWorldUiBlockImpact")

function XBigWorldUiBlockImpact:CheckAllowUiOpen(uiName, blockUiNames)
    if not XTool.IsTableEmpty(blockUiNames) then
        for _, blockUiName in pairs(blockUiNames) do
            if blockUiName == uiName then
                return false
            end
        end
    end

    return true
end

function XBigWorldUiBlockImpact:OnOpening()
    local blockUiNames = self:GetParams()

    if not XTool.IsTableEmpty(blockUiNames) then
        for _, blockUiName in pairs(blockUiNames) do
            XMVCA.XBigWorldUI:SafeClose(blockUiName)
        end
    end
end

return XBigWorldUiBlockImpact
