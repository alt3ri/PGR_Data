---@class XShopControl : XControl
---@field private _Model XShopModel
local XShopControl = XClass(XControl, "XShopControl")

function XShopControl:OnInit()
    
end

function XShopControl:AddAgencyEvent()
    
end

function XShopControl:RemoveAgencyEvent()

end

function XShopControl:OnRelease()
    
end

function XShopControl:GetModel()
    return self._Model
end
function XShopControl:AccumulateExpendShopSign()

    if self._Model:GetAccumulateExpendShop():IsSign() then
        XMVCA.XShop:AccumulateExpendShopSign(function()
            XMVCA.XShop:EnterAccumulateExpendShop()
         end)
    else
        XMVCA.XShop:EnterAccumulateExpendShop()
    end
    self._Model:GetAccumulateExpendShop():EnterShop()
end

return XShopControl