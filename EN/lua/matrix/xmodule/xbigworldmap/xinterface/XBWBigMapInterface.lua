local XBWMapInterfaceBase = require("XModule/XBigWorldMap/XInterface/XBWMapInterfaceBase")

---@class XBWBigMapInterface : XBWMapInterfaceBase
---@field _Proxy XUiBigWorldMap
local XBWBigMapInterface = XClass(XBWMapInterfaceBase, "XBWBigMapInterface")

---@param pinData XBWMapPinData
---@param selectPin XUiBigWorldMapPin
function XBWBigMapInterface:OpenPinDetail(selectPin, levelId, pinData)
    if self._Proxy then
        self._Proxy:OpenPinDetail(selectPin, levelId, pinData)
    end
end

---@param pinData XBWMapPinData
---@param bindPin XUiBigWorldMapPin
function XBWBigMapInterface:OpenTagPinDetail(bindPin, levelId, pinData)
    if self._Proxy then
        self._Proxy:OpenTagPinDetail(bindPin, levelId, pinData)
    end
end

---@param pinDatas XBWMapPinData[]
function XBWBigMapInterface:OpenPinSelectList(pinDatas, transform)
    if self._Proxy then
        self._Proxy:OpenPinSelectList(pinDatas, transform)
    end
end

function XBWBigMapInterface:AnchorToPosition(x, y, isCenter, isIgnoreTween)
    if self._Proxy then
        self._Proxy:AnchorToPosition(x, y, isCenter, isIgnoreTween)
    end
end

function XBWBigMapInterface:GetCurrentSelectGroupId()
    if self._Proxy then
        return self._Proxy:GetCurrentSelectGroupId()
    end
end

function XBWBigMapInterface:GetCurrentSelectFloorIndex()
    if self._Proxy then
        return self._Proxy:GetCurrentSelectFloorIndex()
    end
end

function XBWBigMapInterface:GetCurrentFloorIndex()
    if self._Proxy then
        return self._Proxy:GetCurrentFloorIndex()
    end
end

---@return XBWMapAxisConversion
function XBWBigMapInterface:GetAxisConversion()
    if self._Proxy then
        return self._Proxy:GetAxisConversion()
    end
end

---@return table<number, XUiBigWorldMapPin>
function XBWBigMapInterface:GetPinNodeMap()
    if self._Proxy then
        return self._Proxy:GetPinNodeMap()
    end

    return nil
end

return XBWBigMapInterface