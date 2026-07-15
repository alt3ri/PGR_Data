local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTheatre6PVPRankLevelGrid = require("XUi/XUiTheatre6/PVP/Rank/Grid/XUiTheatre6PVPRankLevelGrid")

---@class XUiTheatre6PVPRankDetailGrid: XUiNode
---@field _Control XTheatre6Control
---@field Parent   XUiTheatre6PVPRank
local XUiTheatre6PVPRankDetailGrid = XClass(XUiNode, "XUiTheatre6PVPRankDetailGrid")

function XUiTheatre6PVPRankDetailGrid:OnStart()
    ---@type XUiGridCommon[]
    self._RewardGrids = {}
    self._Descs = {}
    ---@type XUiTheatre6PVPRankLevelGrid
    self._LevelGrid = XUiTheatre6PVPRankLevelGrid.New(self.GridRank, self)

    self:InitUi()
end

function XUiTheatre6PVPRankDetailGrid:InitUi()
    self.TxtDetail.gameObject:SetActiveEx(false)
    self.Grid256.gameObject:SetActiveEx(false)
end

---@param config XTableTheatre6PvpRank
function XUiTheatre6PVPRankDetailGrid:Refresh(config, selfScore)
    local rewardedRanks = self._Control:GetPvpRewardedRanks()

    if selfScore >= config.MinScore and selfScore <= config.MaxScore then
        self.TagNow.gameObject:SetActiveEx(true)
        self.TxtScoreRange.gameObject:SetActiveEx(false)
        self.PanelTxtScoreNow.gameObject:SetActiveEx(true)
        self.TxtScoreNow.text = selfScore
        self.TxtScoreMax.text = string.format("/%d", config.MaxScore)
    else
        self.TagNow.gameObject:SetActiveEx(false)
        self.TxtScoreRange.gameObject:SetActiveEx(true)
        self.PanelTxtScoreNow.gameObject:SetActiveEx(false)
        self.TxtScoreRange.text = string.format("%d-%d", config.MinScore, config.MaxScore)
    end

    self._LevelGrid:Open()
    self._LevelGrid:Refresh(config.Icon, config.Name)
    self:RefreshRewards(config.RewardIds, rewardedRanks[config.Id])
    self:RefreshDesc(config.Desc)
end

function XUiTheatre6PVPRankDetailGrid:RefreshRewards(rewardIds, isFinish)
    if not XTool.IsTableEmpty(rewardIds) then
        local index = 1

        for _, rewardId in pairs(rewardIds) do
            local rewards = XRewardManager.GetRewardList(rewardId)

            if not XTool.IsTableEmpty(rewards) then
                for _, reward in pairs(rewards) do
                    local grid = self._RewardGrids[index]

                    if not grid then
                        local girdUi = index == 1
                            and self.Grid256 or XUiHelper.Instantiate(self.Grid256.gameObject, self.PanelReward)

                        grid = XUiGridCommon.New(self, girdUi)
                        self._RewardGrids[index] = grid
                    end

                    index = index + 1
                    grid.GameObject:SetActiveEx(true)
                    grid:Refresh(reward)
                    grid.TxtName.gameObject:SetActiveEx(false)

                    local rawImage = grid.Transform:FindTransform("RawImage")
                    local text = grid.Transform:FindTransform("Text")

                    if rawImage then
                        rawImage.gameObject:SetActiveEx(isFinish)
                    end
                    if text then
                        text.gameObject:SetActiveEx(isFinish)
                    end
                end
            end
        end
        for i = index, #self._RewardGrids do
            self._RewardGrids[i].GameObject:SetActiveEx(false)
        end
    else
        for _, grid in pairs(self._RewardGrids) do
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre6PVPRankDetailGrid:RefreshDesc(descs)
    if not XTool.IsTableEmpty(descs) then
        for i, desc in pairs(descs) do
            local grid = self._Descs[i]

            if not grid then
                grid = i == 1 and self.TxtDetail or XUiHelper.Instantiate(self.TxtDetail, self.PanelDetail)

                self._Descs[i] = grid
            end

            grid.gameObject:SetActiveEx(true)
            grid.text = XUiHelper.ReplaceTextNewLine(desc)
        end
        for i = #descs + 1, #self._Descs do
            self._Descs[i].gameObject:SetActiveEx(false)
        end
    else
        for _, grid in pairs(self._Descs) do
            grid.gameObject:SetActiveEx(false)
        end
    end
end

return XUiTheatre6PVPRankDetailGrid
