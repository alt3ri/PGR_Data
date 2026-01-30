local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

--- “挑战”页签活动入口样式的动态列表
-- todo: 父类不是XUiNode，先不继承XUiNode
---@class XUiFubenSimulationStyleDynamicTable
local XUiFubenSimulationStyleDynamicTable = XClass(nil, 'XUiFubenSimulationStyleDynamicTable')

function XUiFubenSimulationStyleDynamicTable:Ctor(rootUi, ui, proxy, ...)
    XUiHelper.InitUiClass(self, ui)
    -- 动态列表
    self.RootUi = rootUi
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(proxy)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenSimulationStyleDynamicTable:OnEnable()
    if not XTool.IsTableEmpty(self.DynamicTable.DataSource) then
        for i = 1, #self.DynamicTable.DataSource do
            local grid = self.DynamicTable:GetGridByIndex(i)
            if grid then
                if grid.RefreshRedPoint then
                    grid:RefreshRedPoint()
                end

                if grid.RefreshProgress then
                    grid:RefreshProgress()
                end
            end
        end
    end
end

function XUiFubenSimulationStyleDynamicTable:OnDisable()
    self.DynamicTable:RecycleAllTableGrid()
end

function XUiFubenSimulationStyleDynamicTable:SetupDynamicTable(datas, reload)
    self.DynamicTable:SetDataSource(datas)
    self.DynamicTable:ReloadDataSync(reload and 1 or -1)
end

--- 设置格子动画播放标记
function XUiFubenSimulationStyleDynamicTable:SetGridPlayAnimHasPlay(flag)
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        if grid.SetHasPlay then
            grid:SetHasPlay(flag)
        end
    end
end

--- 播放动态列表动画
function XUiFubenSimulationStyleDynamicTable:PlayGridEnableAnime()
    -- 先找到使用中的grid里序号最小的
    local minIndex, useNum = self.DynamicTable:GetFirstUseGridIndexAndUseCount()
    local allUseGird = self.DynamicTable:GetGrids()

    local playOrder = 1 -- 播放顺序
    for i = minIndex, minIndex + useNum - 1 do
        local grid = allUseGird[i]
        if grid.PlayEnableAnime then
            grid:PlayEnableAnime(playOrder)
            playOrder = playOrder + 1
        end
    end
end

function XUiFubenSimulationStyleDynamicTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.DynamicTable.DataSource[index], index, self.DynamicTable:GetFirstUseGridIndexAndUseCount())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickChapterGrid(self.DynamicTable.DataSource[index], grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnDisable()
    end
end

-- 周常入口由各自的manger管理，manger里有格子的数据
function XUiFubenSimulationStyleDynamicTable:OnClickChapterGrid(manager, grid)
    if grid and grid.OnClickSelf then
        grid:OnClickSelf()
        return
    end
    manager:ExOpenMainUi()
end

return XUiFubenSimulationStyleDynamicTable