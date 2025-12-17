---@class XBWMapInterfaceBase
local XBWMapInterfaceBase = XClass(nil, "XBWMapInterfaceBase")

function XBWMapInterfaceBase:Ctor(proxy)
    self:SetProxy(proxy)
end

function XBWMapInterfaceBase:SetProxy(proxy)
    self._Proxy = proxy
end

---@param pinData XBWMapPinData
---@param selectPin XUiBigWorldMapPin
function XBWMapInterfaceBase:OpenPinDetail(selectPin, levelId, pinData)
end

---@param pinData XBWMapPinData
---@param bindPin XUiBigWorldMapPin
function XBWMapInterfaceBase:OpenTagPinDetail(bindPin, levelId, pinData)
end

---@param pinDatas XBWMapPinData[]
function XBWMapInterfaceBase:OpenPinSelectList(pinDatas, transform)
end

function XBWMapInterfaceBase:AnchorToPosition(x, y, isCenter, isIgnoreTween)
end

function XBWMapInterfaceBase:GetCurrentSelectGroupId()
    return 0
end

function XBWMapInterfaceBase:GetCurrentFloorIndex()
    return 0
end

function XBWMapInterfaceBase:GetCurrentSelectFloorIndex()
    return 0
end

---@return XBWMapAxisConversion
function XBWMapInterfaceBase:GetAxisConversion()
end

---@return table<number, XUiBigWorldMapPin>
function XBWMapInterfaceBase:GetPinNodeMap()
    return nil
end

return XBWMapInterfaceBase