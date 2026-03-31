local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiTaskActivity : XLuaUi
---@field _Control XControl
local XUiTaskActivity = XLuaUiManager.Register(XLuaUi, "UiTaskActivity")

function XUiTaskActivity:OnAwake()
    self.TxtTime = self.TxtTime or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelChallengeLevel/TxtTime", "XDynamicTableNormal")
    self.TaskList = self.TaskList or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/TaskList", "Text")
    self.BtnGroup = self.BtnGroup or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/BtnGroup", "XUiButtonGroup")
    self.BtnBack = self.BtnBack or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/TopControlVariable/BtnBack", "Button")
    self.BtnMainUi = self.BtnMainUi or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/TopControlVariable/BtnMainUi", "Button")
    self.PanelAsset = self.PanelAsset or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/PanelAsset", "RectTransform")
    self.ImgEmpty = self.ImgEmpty or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/ImgEmpty", "RectTransform")
    self.GridTask = self.GridTask or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/TaskList/Viewport/Content/GridTask", "RectTransform")
    self.BtnTabTask1 = self.BtnTabTask1 or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/BtnGroup/BtnTabTask1", "XUiButton")
    self.BtnTabTask2 = self.BtnTabTask2 or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CommonTask/BtnGroup/BtnTabTask2", "XUiButton")

    self:InitTimes()
    self:InitButton()
    self:InitDynamicTable()
    self:InitAssets()
end

function XUiTaskActivity:InitTimes()
    self:SetAutoCloseInfo(self:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiTaskActivity:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)

    self.TabBtns = {}
    for i = 1, 2 do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    if self.BtnGroup then
        self.BtnGroup:Init(self.TabBtns, function(index)
            self:OnSelectedTog(index)
        end)
    end
end

function XUiTaskActivity:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    -- self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end

function XUiTaskActivity:GetTaskGroupIds()
    return false
end

function XUiTaskActivity:GetTaskIdList()
    return false
end

function XUiTaskActivity:InitDynamicTable()
    -- 兼容TaskGroupIds 和 GetTaskList 两种方式
    local taskGroupIds = self:GetTaskGroupIds()
    if taskGroupIds then
        self.TaskGroupIds = taskGroupIds
    else
        self.TaskIdList = self:GetTaskIdList()
    end
    if not self.TaskGroupIds and not self.TaskIdList then
        self.TaskGroupIds = {}
    end

    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiTaskActivity:OnStart()
    if self.BtnGroup then
        self.BtnGroup:SelectIndex(self.SelectIndex or 1)
    else
        self:OnSelectedTog(1)
    end
end

function XUiTaskActivity:InitAssets()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.FreeGem }, self.PanelSpecialTool, self)
end

function XUiTaskActivity:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateDynamicTable, self)
    if self.TxtTime then
        self:UpdateTime()
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
end

function XUiTaskActivity:UpdateTime()
    local timerId = self._Control:GetActivityTimerId()
    local remainTime = XFunctionManager.GetEndTimeByTimeId(timerId) - XTime.GetServerNowTimestamp()
    remainTime = math.max(remainTime, 0)
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiTaskActivity:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateDynamicTable, self)
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiTaskActivity:GetTaskDataList()
    local index = self.SelectIndex
    if self.TaskGroupIds then
        if not self.TaskGroupIds[index] then
            return
        end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[index])
    else
        local taskIdList = self.TaskIdList[index]
        if taskIdList then
            return XDataCenter.TaskManager.GetTaskIdListData(taskIdList, true)
        end
    end
end

function XUiTaskActivity:UpdateDynamicTable()
    local taskDataList = self:GetTaskDataList()
    if not taskDataList then
        return
    end
    self.TaskDataList = taskDataList
    local allAchieveTasks = {}
    for _, v in pairs(self.TaskDataList) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks, v.Id)
        end
    end
    if not XTool.IsTableEmpty(allAchieveTasks) then
        table.insert(self.TaskDataList, 1, { ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks }) -- 领取全部
    end
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
    self:UpdateRedPoint()
end

---@param grid XDynamicGridTask
function XUiTaskActivity:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
        grid:SetTaskLock(false)
    end
end

function XUiTaskActivity:UpdateRedPoint()
    for i = 1, 2 do
        if self.TabBtns[i] then
            if self.TaskIdList then
                -- TaskIdList：任务ID列表，检查是否有任务可领取
                local taskIdList = self.TaskIdList[i]
                if taskIdList then
                    local isShowRed = XDataCenter.TaskManager.CheckAnyTaskAchievedByTaskIdList(taskIdList)
                    self.TabBtns[i]:ShowReddot(isShowRed)
                end
            elseif self.TaskGroupIds and self.TaskGroupIds[i] then
                -- TaskGroupIds：限时任务组ID，检查是否有任务可领取
                local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[i])
                self.TabBtns[i]:ShowReddot(isShowRed)
            else
                self.TabBtns[i]:ShowReddot(false)
            end
        end
    end
end

function XUiTaskActivity:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
    end
end

function XUiTaskActivity:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

return XUiTaskActivity
