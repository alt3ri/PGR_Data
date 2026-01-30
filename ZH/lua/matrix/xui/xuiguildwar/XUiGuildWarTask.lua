local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiGuildWarUpCharacter ########################
local XUiCommonTaskControl = require("XUi/XUiCommon/XUiCommonTaskControl")
local XUiGuildWarTask = XLuaUiManager.Register(XUiCommonTaskControl, "UiGuildWarTask")
local TaskGrid = require("XUi/XUiGuildWar/Task/XUiGuildWarTaskGrid")
function XUiGuildWarTask:OnAwake()
    XUiCommonTaskControl.Super.OnAwake(self)
    -- 任务列表
    self.CurrentTaskType = nil
    self.CurrentTasks = nil
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(TaskGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    -- 注册按钮事件
    self:RegisterUiEvents()
    self.TabBtns = nil
    self.GuildWarManager = XDataCenter.GuildWarManager
    XUiHelper.NewPanelActivityAssetSafe({ XGuildWarConfig.ActivityPointItemId } ,self.PanelSpecialTool, self
        , { self.GuildWarManager.GetMaxActionPoint() })
end

function XUiGuildWarTask:CreateTabBtns()
    local result = {}
    self.TaskTypeDatas = self.GuildWarManager.GetAllShowedTaskTypeList()
    XUiHelper.RefreshCustomizedList(self.BtnTabGroup.transform, self.BtnTaskTab, #self.TaskTypeDatas, function(index, go)
        local button = go.transform:GetComponent("XUiButton")
        button:SetNameByGroup(0, self.TaskTypeDatas[index].Name)
        table.insert(result, button)
    end)
    return result
end

function XUiGuildWarTask:GetEndTime()
    return self.GuildWarManager.GetActivityEndTime()
end

function XUiGuildWarTask:HandleEndTimeFunc()
   self.GuildWarManager.OnActivityEndHandler()
end

function XUiGuildWarTask:GetTaskDataByTabIndex(index)
    local taskList = self.GuildWarManager.GetTaskList(self.TaskTypeDatas[index].TaskType)
    
    self.AllAchieveTaskDatas = nil
    
    -- 收集可领取的任务
    if not XTool.IsTableEmpty(taskList) then
        for i, v in pairs(taskList) do
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                if self.AllAchieveTaskDatas == nil then
                    self.AllAchieveTaskDatas = {}
                end
                
                table.insert(self.AllAchieveTaskDatas, v.Id)
            end
        end
    end
    
    return taskList
end
--==================
--检查页签红点
--这里因为不走RedPointManager逻辑所以重写了通用方法
--==================
function XUiGuildWarTask:CheckBtnsRed()
    for index, btn in ipairs(self.TabBtns) do
        --这里任务类型和
        local isRed = XDataCenter.GuildWarManager.CheckTaskCanAchievedByType(self.TaskTypeDatas[index].TaskType)
        btn:ShowReddot(isRed)
    end
end

---@overload 
function XUiGuildWarTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.CurrentTasks[index])
        grid:SetAllReceiveTaskIds(self.AllAchieveTaskDatas)
    end
end

---@overload
function XUiGuildWarTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event ==XEventId.EVENT_FINISH_MULTI then
        self:RefreshTaskList(self.CurrentTaskType)
        self:CheckBtnsRed()
    end
end

---@overload
function XUiGuildWarTask:OnGetLuaEvents()
    return {
        XEventId.EVENT_FINISH_MULTI,
    }
end

return XUiGuildWarTask
