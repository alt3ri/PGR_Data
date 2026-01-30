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

---@return XAccumulateExpendShop
function XShopControl:GetAccumulateExpendShopModel()
    return self._Model:GetAccumulateExpendShop()
end

function XShopControl:AccumulateExpendShopSign()

    if self:GetAccumulateExpendShopModel():IsSign() then
        XMVCA.XShop:AccumulateExpendShopSign(function()
            XMVCA.XShop:EnterAccumulateExpendShop()
         end)
    else
        XMVCA.XShop:EnterAccumulateExpendShop()
    end
    self:EnterAccumulateExpendShop()
end

function XShopControl:EnterAccumulateExpendShop()
    self:GetAccumulateExpendShopModel():EnterShop()
end
return XShopControl