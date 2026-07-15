---@class XUiTheatre6PVPRankLevelGrid : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiTheatre6PVPRankGrid
local XUiTheatre6PVPRankLevelGrid = XClass(XUiNode, "XUiTheatre6PVPRankLevelGrid")

function XUiTheatre6PVPRankLevelGrid:Refresh(icon, name)
    if string.IsNilOrEmpty(icon) then
        self.RImgRank.gameObject:SetActiveEx(false)
    else
        self.RImgRank.gameObject:SetActiveEx(true)
        self.RImgRank:SetImage(icon)
    end

    self.TxtName.text = name
end

return XUiTheatre6PVPRankLevelGrid
