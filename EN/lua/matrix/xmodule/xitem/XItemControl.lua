---@class XItemControl : XControl
---@field private _Model XItemConfigModel
local XItemControl = XClass(XControl, "XItemControl")

function XItemControl:OnInit()

end

function XItemControl:AddAgencyEvent()

end

function XItemControl:RemoveAgencyEvent()

end

function XItemControl:OnRelease()

end


function XItemControl:GetItemUsePackages(id)
    local result = {}
    local cfg = self._Model:GetItemUsePackageConfig(id)
    if not cfg then
        return result
    end
    for _, v in pairs(cfg.PackageIds) do
        if v then
            if XDataCenter.ItemManager.GetCount(v) > 0 then
                table.insert(result, v)
            end
        end
    end
    return result
end

function XItemControl:GetSubItems(id)
    local cfg = self._Model:GetItemUsePackageConfig(id)
    if not cfg then
        return {}
    end
    return cfg.SubItems or {}
end

function XItemControl:GetItemExchangeConfigsByItemId(itemId)
    return self._Model:GetItemExchangeConfigsByItemId(itemId)
end
return XItemControl
