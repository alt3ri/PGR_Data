---@class XUiMainLine2Task : XLuaUi
---@field _Control XMainLine2Control
local XUiMainLine2Task = XLuaUiManager.Register(XLuaUi, "UiMainLine2Task")

function XUiMainLine2Task:OnAwake()
    -- 隐藏挑战目标
    self.PanelTreasure.gameObject:SetActiveEx(false)
    
    -- 初始化UiObject引用
    self.PanelTaskStory.gameObject:SetActiveEx(true)
    self.UiObj = {}
    XTool.InitUiObjectByUi(self.UiObj, self.PanelTaskStory)
    self.UiObj.GridTask.gameObject:SetActiveEx(false)
    
    -- 隐藏下方PanelCourse
    self.UiObj.PanelCourse.gameObject:SetActiveEx(false)
    self.UiObj.PanelCourseReward.gameObject:SetActiveEx(false)
    
    -- 修改PanelTaskStoryList参数
    local bottom = self._Control:GetClientConfigParams("PanelTaskStoryListBottom", 1)
    local panelTaskStoryList = self.UiObj.PanelTaskStoryList
    panelTaskStoryList.offsetMin = XLuaVector2.New(panelTaskStoryList.offsetMin.x, tonumber(bottom))
    
    self:InitButtonGroup()
    self:InitDynamicTable()
    self:RegisterUiEvents()
end

function XUiMainLine2Task:OnStart(mainId)
    self.MainId = mainId
    self.TaskGroupId = self._Control:GetMainTaskGroupId(mainId)
end

function XUiMainLine2Task:OnEnable()
    self:Refresh()
end

function XUiMainLine2Task:OnDisable()
    
end

function XUiMainLine2Task:OnDestroy()
    self:StopAnimationTimer()
end

function XUiMainLine2Task:OnGetLuaEvents()
    return {
        XEventId.EVENT_TASK_SYNC,
    }
end

--事件监听
function XUiMainLine2Task:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshDynamicTable()
    end
end

function XUiMainLine2Task:InitButtonGroup()
    self.BtnTab2.gameObject:SetActiveEx(false)
    self.Buttons = {self.BtnTab1, self.BtnTab2}
    self.PanelTab:Init(self.Buttons, function(index) self:OnSelectBtnTab(index) end)
    self.PanelTab:SelectIndex(1)
end

function XUiMainLine2Task:OnSelectBtnTab()
    
end

function XUiMainLine2Task:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiMainLine2Task:OnBtnBackClick()
    self:Close()
end

function XUiMainLine2Task:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMainLine2Task:Refresh()
    self:RefreshDynamicTable()
end

function XUiMainLine2Task:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
    self.DynamicTable = XDynamicTableNormal.New(self.UiObj.PanelTaskStoryList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiMainLine2Task:RefreshDynamicTable()
    self.GridCount = 0
    self.TaskDatas = XDataCenter.TaskManager.GetStoryTaskListByGroupId(self.TaskGroupId)
    self.UiObj.PanelNoneStoryTask.gameObject:SetActive(#self.TaskDatas <= 0)
    self.DynamicTable:SetDataSource(self.TaskDatas)
    self.DynamicTable:ReloadDataASync()
end

--动态列表事件
function XUiMainLine2Task:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskDatas[index]
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()
        self.GridIndex = 1
        self:StopAnimationTimer()
        self.AnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActive(true)
                item:PlayAnimation()
            end
            self.GridIndex = self.GridIndex + 1
        end, 50, self.GridCount, 0)
    end
end

function XUiMainLine2Task:StopAnimationTimer()
    if self.AnimationTimerId then
        XScheduleManager.UnSchedule(self.AnimationTimerId)
        self.AnimationTimerId = nil
    end
end

return XUiMainLine2Task