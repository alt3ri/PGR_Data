---@class XBigWorldUiImpactBase
local XBigWorldUiImpactBase = XClass(nil, "XBigWorldUiImpactBase")

function XBigWorldUiImpactBase:Ctor(uiName, impactId)
    self._UiName = uiName
    self._ImpactId = impactId
    self._Type = XMVCA.XBigWorldUI:GetUiImpactType(impactId)
    self._Params = XMVCA.XBigWorldUI:GetUiImpactParams(impactId)
end

function XBigWorldUiImpactBase:GetUiName()
    return self._UiName
end

function XBigWorldUiImpactBase:GetImpactId()
    return self._ImpactId
end

function XBigWorldUiImpactBase:GetType()
    return self._Type
end

function XBigWorldUiImpactBase:GetParams()
    return self._Params
end

function XBigWorldUiImpactBase:IsAllowOpen(uiName)
    return self:CheckAllowUiOpen(uiName, self._Params)
end

function XBigWorldUiImpactBase:CheckAllowUiOpen(uiName, ...)
    return true
end

function XBigWorldUiImpactBase:OnOpening()
end

return XBigWorldUiImpactBase
