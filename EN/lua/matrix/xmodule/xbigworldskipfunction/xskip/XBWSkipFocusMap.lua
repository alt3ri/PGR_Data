local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipFocusMap : XBWSkipBase
local XBWSkipFocusMap = XClass(XBWSkipBase, "XBWSkipFocusMap")

function XBWSkipFocusMap:Skip()
    local params = self:GetParams()

    if not XTool.IsTableEmpty(params) then
        local worldId = params[1] or 0
        local levelId = params[2] or 0
        local posX = params[3] or 0
        local posY = params[4] or 0
        local scaleRatio = params[5] or 0

        return XMVCA.XBigWorldMap:OpenBigWorldMapUiWithPosition(worldId, levelId, posX, posY, scaleRatio)
    end

    return false
end

return XBWSkipFocusMap
