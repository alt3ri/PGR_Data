local XBWMapInterfaceBase = require("XModule/XBigWorldMap/XInterface/XBWMapInterfaceBase")

---@class XBWLittleMapInterface : XBWMapInterfaceBase
---@field _Proxy XUiBigWorldPanelLittleMap
local XBWLittleMapInterface = XClass(XBWMapInterfaceBase, "XBWLittleMapInterface")

function XBWLittleMapInterface:GetCurrentFloorIndex()
    if self._Proxy then
        return self._Proxy:GetCurrentFloorIndex()
    end
end

function XBWLittleMapInterface:GetCurrentSelectFloorIndex()
    return self:GetCurrentFloorIndex()
end

function XBWLittleMapInterface:GetAxisConversion()
    if self._Proxy then
        return self._Proxy:GetAxisConversion()
    end
end

return XBWLittleMapInterface