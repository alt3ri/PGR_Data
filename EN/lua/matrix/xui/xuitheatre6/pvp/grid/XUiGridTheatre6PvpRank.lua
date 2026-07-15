---@class XUiGridTheatre6PvpRank : XUiNode pvp段位
---@field _Control XTheatre6Control
local XUiGridTheatre6PvpRank = XClass(XUiNode, "XUiGridTheatre6PvpRank")

function XUiGridTheatre6PvpRank:SetData(rankId)
    local rankConfig = self._Control:GetPvpRankConfig(rankId)
    self.RImgRank:SetRawImageEx(rankConfig.Icon)
    self.TxtName.text = rankConfig.Name
end

function XUiGridTheatre6PvpRank:SetRankScore(score)
    if self.TxtRankScore then
        self.TxtRankScore.text = score or "0"
    end
end

return XUiGridTheatre6PvpRank
