---@class XUiRaceRank : XLuaUi 排行榜
---@field _Control XRaceControl
local XUiRaceRank = XLuaUiManager.Register(XLuaUi, "UiRaceRank")

local ServerRank = 1
local GuildRank = 2

function XUiRaceRank:OnAwake()
    ---@type RankData[]
    self._RankDataDict = {}
end

function XUiRaceRank:OnStart()
    ---@type XUiGridRaceRank
    self._MyRank = require("XUi/XUiRace/Grid/XUiGridRaceRank").New(self.PanelSelfRank, self)
    self._MyRank:Init()
    self.PanelRank.gameObject:SetActiveEx(false)

    self:InitTab()
    self:InitComponent()
    self:InitDynamicTable()
end

function XUiRaceRank:InitTab()
    local btns = { self.GridTab1, self.GridTab2 }
    self.BtnTabGroup:Init(btns, function(index)
        self:OnSelectedTag(index)
    end)

    local timerId = XScheduleManager.ScheduleOnce(function()
        self.BtnTabGroup:SelectIndex(1)
    end, 500)
    self:_AddTimerId(timerId)

    self._IsJoin = XDataCenter.GuildManager.IsJoinGuild()
    self.GridTab2:SetButtonState(self._IsJoin and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiRaceRank:InitComponent()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
    XUiHelper.NewPanelTopControl(self, self.TopControl)
    self.TxtTimeDesc.text = XUiHelper.GetText("RaceRankDesc")
end

function XUiRaceRank:InitDynamicTable()
    self.GridRank.gameObject:SetActiveEx(false)
    self._DynamicTable = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal").New(self.ListRank)
    self._DynamicTable:SetProxy(require("XUi/XUiRace/Grid/XUiGridRaceRank"), self)
    self._DynamicTable:SetDelegate(self)
end

function XUiRaceRank:OnSelectedTag(index)
    if index == GuildRank and not self._IsJoin then
        self._Control:OpenTip("RaceNotJoinGuildTIp")
        return
    end
    
    self._CurIndex = index

    if not self._RankDataDict[index] then
        ---@type RankData
        local data = {}
        if index == ServerRank then
            self._Control:RequestRankQuery(function(res)
                self.PanelRank.gameObject:SetActiveEx(true)
                if res.SelfRankPlayer then
                    data.SelfRankPlayer = res.SelfRankPlayer
                elseif res.SelfRank then
                    data.SelfRankPlayer = res.RankPlayerInfos[res.SelfRank]
                end
                if data.SelfRankPlayer then
                    data.SelfRankPlayer.Rank = res.SelfRank
                end
                data.TotalCount = res.TotalCount
                data.RankPlayerInfos = res.RankPlayerInfos
                self._RankDataDict[index] = data
                self:UpdateRank()
            end)
        elseif index == GuildRank then
            self._Control:RequestGuildRankQuery(function(res)
                self.PanelRank.gameObject:SetActiveEx(true)
                for i, rankInfo in ipairs(res.RankPlayerInfos) do
                    if rankInfo.Id == XPlayer.Id then
                        data.SelfRankPlayer = rankInfo
                        data.SelfRankPlayer.Rank = i
                        break
                    end
                end
                data.TotalCount = #res.RankPlayerInfos
                data.RankPlayerInfos = res.RankPlayerInfos
                self._RankDataDict[index] = data
                self:UpdateRank()
            end)
        end
        return
    end

    self:UpdateRank()
end

function XUiRaceRank:UpdateRank()
    local data = self._RankDataDict[self._CurIndex]
    if not data then
        return
    end

    self._DataList = data.RankPlayerInfos
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync(1)
    self.ImgEmpty.gameObject:SetActiveEx((not next(self._DataList)))
    
    self._MyRank:Open()
    self._MyRank:RefreshMine(data.SelfRankPlayer, data.TotalCount)
end

---@param grid XUiGridRaceRank
function XUiRaceRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self._DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        ---@type XUiGridRaceRank[]
        local grids = self._DynamicTable:GetGrids()
        local gridCount = XTool.GetTableCount(grids)
        if XTool.IsTableEmpty(grids) or #grids <= 0 then
            --非完整完成不播动画
            return
        end
        for i, grid in ipairs(grids) do
            grid:Close()
            local timerId = XScheduleManager.ScheduleOnce(function()
                grid:Open()
                grid:PlayAnimationWithMask("GridRankEnable")
            end, 50 * i)
            self:_AddTimerId(timerId)
        end
    end
end

---@class RankData
---@field SelfRankPlayer table 当前自己的信息（含排名）
---@field TotalCount number 排行榜总人数
---@field RankPlayerInfos table 玩家信息列表

return XUiRaceRank