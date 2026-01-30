local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipFocusMapPin : XBWSkipBase
local XBWSkipFocusMapPin = XClass(XBWSkipBase, "XBWSkipFocusMapPin")

function XBWSkipFocusMapPin:Skip()
    local params = self:GetParams()

    if not XTool.IsTableEmpty(params) then
        local worldId = params[1] or 0
        local levelId = params[2] or 0
        local pinId = params[3] or 0

        return XMVCA.XBigWorldMap:OpenBigWorldMapUiWithPinId(worldId, levelId, pinId)
    end

    return false
end

return XBWSkipFocusMapPin
