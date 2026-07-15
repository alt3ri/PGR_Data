local XUiTheatre6PVPRankLevelGrid = require("XUi/XUiTheatre6/PVP/Rank/Grid/XUiTheatre6PVPRankLevelGrid")

---@class XUiTheatre6PVPRankGrid: XUiNode
---@field _Control XTheatre6Control
---@field Parent   XUiTheatre6PVPRank
local XUiTheatre6PVPRankGrid = XClass(XUiNode, "XUiTheatre6PVPRankGrid")

function XUiTheatre6PVPRankGrid:OnStart()
    self._PlayerId = 0
    self.BtnHead:AddEventListener(Handler(self, self.OnBtnHeadClick))
    ---@type XUiTheatre6PVPRankLevelGrid
    self.Grid = XUiTheatre6PVPRankLevelGrid.New(self.GridRank, self)
end

---@param data XTheatre6PvpRankPlayer
function XUiTheatre6PVPRankGrid:Refresh(index, data, rankConfigs)
    local info = nil

    self._PlayerId = data.Id
    self.TxtRank.text = tostring(index)
    self.TxtName.text = data.Name
    self.TxtPoint.text = tostring(data.Score)
    XUiPlayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)

    if not XTool.IsTableEmpty(rankConfigs) then
        for id, config in pairs(rankConfigs) do
            if data.Score >= config.MinScore and data.Score <= config.MaxScore then
                info = config
                break
            end
        end
    end

    if info then
        self.Grid:Open()
        self.Grid:Refresh(info.Icon, info.Name)
    else
        self.Grid:Close()
    end
end

function XUiTheatre6PVPRankGrid:OnBtnHeadClick()
    if XTool.IsNumberValid(self._PlayerId) then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._PlayerId)
    end
end

return XUiTheatre6PVPRankGrid
