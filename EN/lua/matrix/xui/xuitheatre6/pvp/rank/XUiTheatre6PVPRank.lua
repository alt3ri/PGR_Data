local XUiTheatre6PVPRankGrid = require("XUi/XUiTheatre6/PVP/Rank/Grid/XUiTheatre6PVPRankGrid")

---@class XUiTheatre6PVPRank: XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PVPRank = XLuaUiManager.Register(XLuaUi, "UiTheatre6PVPRank")

function XUiTheatre6PVPRank:OnAwake()
    ---@type XTheatre6PvpRankInfo
    self._RankInfo = self._Control:GetPvpRankInfo()
    ---@type XDynamicTableNormal
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.RankView, XUiTheatre6PVPRankGrid)
    ---@type XTableTheatre6PvpRank[]
    self._RankConfigs = self._Control:GetPvpRankConfigs()

    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainClick))

    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiTheatre6PVPRank:OnEnable()
    self:RefreshSelf()
    self:RefreshDynamicTable()
end

function XUiTheatre6PVPRank:OnBtnBackClick()
    self:Close()
end

function XUiTheatre6PVPRank:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

---@param grid XUiTheatre6PVPRankGrid
function XUiTheatre6PVPRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(index, data, self._RankConfigs)
    end
end

function XUiTheatre6PVPRank:RefreshSelf()
    if not self._RankInfo then
        self:Close()
        return
    end

    local timeId = self._Control:GetPvpActivityTimeId()
    local selfRank = self._RankInfo.SelfRank or -1
    local rankInfos = self._RankInfo.RankPlayerInfos
    local rankInfo = rankInfos and rankInfos[selfRank] or nil

    if selfRank > 0 and rankInfo then
        if not self._SelfGrid then
            ---@type XUiTheatre6PVPRankGrid
            self._SelfGrid = XUiTheatre6PVPRankGrid.New(self.PanelSelfRank, self)
        end

        self._SelfGrid:Open()
        self._SelfGrid:Refresh(selfRank, rankInfo, self._RankConfigs)
    else
        if self._SelfGrid then
            self._SelfGrid:Close()
        else
            self.PanelSelfRank.gameObject:SetActiveEx(false)
        end
    end

    if XTool.IsNumberValid(timeId) then
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
        local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "yyyy.MM.dd")
        local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "yyyy.MM.dd")

        self.TxtTime.gameObject:SetActiveEx(true)
        self.TxtTime.text = XUiHelper.GetText("Theatre6PvpRankTime", startTimeStr, endTimeStr)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre6PVPRank:RefreshDynamicTable()
    if not self._RankInfo then
        self:Close()
        return
    end

    local rankInfos = self._RankInfo.RankPlayerInfos

    if XTool.IsTableEmpty(rankInfos) then
        self._DynamicTable:SetActive(false)
        self.ImgEmpty.gameObject:SetActiveEx(true)
    else
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self._DynamicTable:SetActive(true)
        self._DynamicTable:SetDataSource(rankInfos)
        self._DynamicTable:ReloadDataASync(1)
    end
end

return XUiTheatre6PVPRank
