local XUiPlotExhibitionMainGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionMainGrid")
local XUiPlotExhibitionMainFilterGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionMainFilterGrid")

---@class XUiPlotExhibitionMain : XLuaUi
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionMain = XLuaUiManager.Register(XLuaUi, "UiPlotExhibitionMain")

function XUiPlotExhibitionMain:OnAwake()
    self._TempTimers = {}
    self.GridMember.gameObject:SetActiveEx(false)
    self.PanelFilter.gameObject:SetActiveEx(false)
    self.GridPower.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnClickFilter)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnClickFilter)
    self:BindExitBtns()

    ---@type XDynamicTableNormal
    self.DynamicTableNormal = XUiHelper.DynamicTableNormal(self, self.ListMember, XUiPlotExhibitionMainGrid)

    -- 筛选也用了动态列表, 一个界面做了两个动态列表~
    ---@type XDynamicTableNormal
    self.DynamicTableFilter = XUiHelper.DynamicTableNormalWithDelegate(self, self.ListPower, XUiPlotExhibitionMainFilterGrid, {
        OnDynamicTableEvent = function(table, event, index, grid)
            if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
                -- 在update之前, 重置grid的透明度和坐标
                self:ResetGridState(grid)
                grid:Update(self.DynamicTableFilter:GetData(index))
            elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
                --self._Control:OpenUiDetail(self.DynamicTableNormal:GetData(index))
            end
        end
    })

    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnClickSkip)
    self.BtnFilterClear = self.BtnFilterClear or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelFilter/Bg/BtnFilterClear", "XUiButton")
    XUiHelper.RegisterClickEvent(self, self.BtnFilterClear, self.OnClickClearFilter)
end

function XUiPlotExhibitionMain:OnStart()
end

---@param grid XUiPlotExhibitionMainGrid
function XUiPlotExhibitionMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTableNormal:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._Control:OpenUiDetail(self.DynamicTableNormal:GetData(index))
    end
end

function XUiPlotExhibitionMain:OnEnable()
    self:Update(true)
end

function XUiPlotExhibitionMain:OnDisable()
end

function XUiPlotExhibitionMain:Update(force)
    self._Control:UpdateMain(force)
    local data = self._Control:GetUiData().Main
    self.DynamicTableNormal:SetDataSource(data.FilterRoleList)
    self.DynamicTableNormal:ReloadDataSync()
end

function XUiPlotExhibitionMain:OnClickFilter()
    if self.PanelFilter.gameObject.activeSelf then
        self:PlayAnimation("PanelFilterDisable", function()
            -- 手动close，否则在OnEnable时触发XUiNode.gameObject未激活的error
            local grids = self.DynamicTableFilter:GetGrids()
            for i, grid in pairs(grids) do
                grid:Close()
            end
            self.PanelFilter.gameObject:SetActiveEx(false)
        end)
    else
        self.PanelFilter.gameObject:SetActiveEx(true)
        -- 手动open...
        local grids = self.DynamicTableFilter:GetGrids()
        for i, grid in pairs(grids) do
            grid:Open()
        end
        self:UpdateFilter()
        self:PlayAnimation("PanelFilterEnable")
    end
end

function XUiPlotExhibitionMain:UpdateFilter()
    self._Control:UpdateFilter()
    self.DynamicTableFilter:SetDataSource(self._Control:GetUiData().Filter.FilterList)
    if self._IsInitFilter then
        self.DynamicTableFilter:ReloadVisibleGrids()
    else
        -- DynamicTableNormal在调用reload时，会触发位置计算，上下跳动，所以只在第一次初始化时，调用reload
        self._IsInitFilter = true
        self.DynamicTableFilter:ReloadDataSync()
    end
end

---@param existRoleDict number[]@在选中筛选列表中的某个阵营时，新出现的角色需要播放动画
function XUiPlotExhibitionMain:UpdateByFilter(existRoleDict)
    self:Update()
    self:StopAnimationAndResetState()
    
    ---@type XUiPlotExhibitionMainGrid[]
    local grids = self.DynamicTableNormal:GetGrids()
    if existRoleDict then
        local index = -1
        for _, grid in pairs(grids) do
            if not existRoleDict[grid:GetRoleId()] then
                index = index + 1
                grid:Close()
                local timer
                timer = self:Tween(index * 0.1, nil, function()
                    grid:Open()
                    grid:PlayAnimation("GridMemberEnable")
                    self._TempTimers[timer] = nil
                end)
                self._TempTimers[timer] = true
            end
        end
    end
end

function XUiPlotExhibitionMain:OnClickSkip()
    if XLuaUiManager.IsUiLoad("UiNewFuben") then
        self:Close()
    else
        XLuaUiManager.Open("UiNewFuben", XDataCenter.FubenManager.ChapterType.MainLine)
    end
end

function XUiPlotExhibitionMain:OnClickClearFilter()
    -- 没有筛选条件时，点击清空按钮无效
    -- 为了应对dynamicTable的bug，必须重新计算位置，这里加个判断
    if self._Control:IsFilterEmpty() then
        return
    end
    self:StopAnimationAndResetState()
    self._Control:ClearFilterForceSelected()
    self:Update()
    self:UpdateFilter()
end

-- 重置单个grid的透明度和坐标
---@param grid XUiNode
function XUiPlotExhibitionMain:ResetGridState(grid)
    local zero = Vector3.zero
    local canvasGroup = XUiHelper.TryGetComponent(grid.Transform, "Root", "CanvasGroup")
    if canvasGroup then
        canvasGroup.alpha = 1
    end
    local root = XUiHelper.TryGetComponent(grid.Transform, "Root", "RectTransform")
    if root then
        root.localPosition = zero
    end
end

function XUiPlotExhibitionMain:StopAnimationAndResetState()
    for timer, _ in pairs(self._TempTimers) do
        XScheduleManager.UnSchedule(timer)
        self._TempTimers[timer] = nil
    end
    -- 终止所有的动画，但是要保证canvas.alpha正常
    -- 不止要还原alpha，还要还原root的坐标
    ---@type XUiPlotExhibitionMainGrid[]
    local grids = self.DynamicTableNormal:GetGrids()
    for _, grid in pairs(grids) do
        self:ResetGridState(grid)
    end
end

return XUiPlotExhibitionMain