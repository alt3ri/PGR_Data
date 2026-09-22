local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTransfiniteTowerRank = require("XUi/XUiTransfiniteTower/Grid/XUiGridTransfiniteTowerRank")

---@class XUiPanelTransfiniteTowerRank : XUiNode
---@field private _Control XTransfiniteTowerControl
local XUiPanelTransfiniteTowerRank = XClass(XUiNode, "XUiPanelTransfiniteTowerRank")

function XUiPanelTransfiniteTowerRank:OnStart()
    self:_InitDynamicTable()
    self:_InitMySelfRank()
end

function XUiPanelTransfiniteTowerRank:_InitDynamicTable()
    ---@type XDynamicTableNormal
    self._DynamicTable = XDynamicTableNormal.New(self.SViewRank)
    self._DynamicTable:SetProxy(XUiGridTransfiniteTowerRank, self)
    self._DynamicTable:SetDelegate(self)
    -- 隐藏动态列表模板节点
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiPanelTransfiniteTowerRank:_InitMySelfRank()
    ---@type XUiGridTransfiniteTowerRank
    self._MySelfGrid = XUiGridTransfiniteTowerRank.New(self.GridMySelfRank, self)
end

---@param grid XUiGridTransfiniteTowerRank
function XUiPanelTransfiniteTowerRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        if data then
            grid:Refresh(data, index)
        end
    end
end

---@param rankList table[] 排名数据数组
---@param myRankData table 自己的排名数据（含 Rank 字段），无则隐藏自己排名条
function XUiPanelTransfiniteTowerRank:Refresh(rankList, myRankData)
    rankList = rankList or table.empty
    self._DynamicTable:SetDataSource(rankList)
    self._DynamicTable:ReloadDataASync()
    self:RefreshMySelfRank(myRankData)
end

function XUiPanelTransfiniteTowerRank:RefreshMySelfRank(myRankData)
    local hasData = myRankData ~= nil
    self.GridMySelfRank.gameObject:SetActiveEx(hasData)
    if hasData then
        self._MySelfGrid:Refresh(myRankData, myRankData.Rank)
    end
end

return XUiPanelTransfiniteTowerRank
