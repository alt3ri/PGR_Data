---@class XUiBigWorldMapTab : XUiNode
---@field TxtSubName UnityEngine.UI.Text
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapTab = XClass(XUiNode, "XUiBigWorldMapTab")

function XUiBigWorldMapTab:Refresh(overviewId)
    local name = self._Control:GetOverviewName(overviewId) or ""

    self.TxtSubName.text = name
end

return XUiBigWorldMapTab