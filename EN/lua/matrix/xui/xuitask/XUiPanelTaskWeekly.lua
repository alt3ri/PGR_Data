local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XDynamicDailyTask = require("XUi/XUiTask/XDynamicDailyTask")

---@class XUiPanelTaskWeekly
local XUiPanelTaskWeekly = XClass(XUiNode, "XUiPanelTaskWeekly")
local IsMulting = false
local ShowRewardList = {}

function XUiPanelTaskWeekly:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskWeeklyList)
    self.DynamicTable:SetProxy(XDynamicDailyTask,self)
    self.DynamicTable:SetDelegate(self)

    self.WeeklyActiveness = XTaskConfig.GetWeeklyTwoActivenessTemplate()
end

function XUiPanelTaskWeekly:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)

    if not self.OnScreenChangeCallback then
        self.OnScreenChangeCallback = handler(self, self.RefreshWeeklyTaskRewardBar)
    end

    CsXGameEventManager.Instance:RegisterEvent(
        CS.XEventId.EVENT_SCREEN_CHANGE,
        self.OnScreenChangeCallback)
end

function XUiPanelTaskWeekly:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)
    self.DynamicTable:RecycleAllTableGrid()
    self:_HideAllWeeklyTaskRewardGrid()

    CsXGameEventManager.Instance:RemoveEvent(
        CS.XEventId.EVENT_SCREEN_CHANGE,
        self.OnScreenChangeCallback)
end

function XUiPanelTaskWeekly:OnDestroy()
    self:ReleaseRefreshWeeklyTaskRewardBarSchedule()
end

function XUiPanelTaskWeekly:ShowPanel()
    self:Open()

    local allWeeklyTasks = self:GetWeeklyTasks()
    self.WeeklyTasks = self:GetTasks(allWeeklyTasks)
    self:RefreshWeeklyTaskRewardBar()
    self.PanelNoneWeeklyTask.gameObject:SetActive(#self.WeeklyTasks <= 0)
    self.DynamicTable:SetDataSource(self.WeeklyTasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelTaskWeekly:HidePanel()
    self:Close()
end

function XUiPanelTaskWeekly:CheckRefreshLeftNewTask()
    local allWeeklyTasks = self:GetWeeklyTasks()
    local tempTasks = self:GetTasks(allWeeklyTasks)
    self:RefreshWeeklyTaskRewardBar()
    -- 同步任务刷新 开始检查是否有剩余任务
    if self.ReceiveAll then --有剩余的未激活任务
        local leftTasks = tempTasks[1].AllAchieveTaskDatas
        if leftTasks and next(leftTasks) then
            XDataCenter.TaskManager.FinishMultiTaskRequest(leftTasks, function(rewardGoodsList)
                -- 有剩余任务 返回的奖励必不弹窗，插入奖励列表
                for key, reward in pairs(rewardGoodsList) do
                    table.insert(ShowRewardList, reward)
                end
            end)
        end
    elseif not self.ReceiveAll and ShowRewardList and next(ShowRewardList) then
        -- 没有剩余任务了，弹窗任务奖励
        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(ShowRewardList, nil, nil, nil, horizontalNormalizedPosition)
        ShowRewardList = {} --刷新奖励列表
        IsMulting = false
        XLuaUiManager.SetMask(false)
    end

    return self.ReceiveAll
end

function XUiPanelTaskWeekly:Refresh(isMulti)
    if not self:IsNodeShow() then return end

    if isMulti and self:CheckRefreshLeftNewTask() then
        return
    end

    if IsMulting then  -- 一键领取未结束不刷新列表
        return
    end

    local allWeeklyTasks = self:GetWeeklyTasks()
    self.WeeklyTasks = self:GetTasks(allWeeklyTasks)
    self.PanelNoneWeeklyTask.gameObject:SetActive(#self.WeeklyTasks <= 0)
    self.DynamicTable:SetDataSource(self.WeeklyTasks)
    self.DynamicTable:ReloadDataSync()
    self:RefreshWeeklyTaskRewardBar()
end

function XUiPanelTaskWeekly:GetTasks(weeklyTasks)
    local allAchieveTasks = {}
    for _, v in pairs(weeklyTasks) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks , v.Id) 
        end
    end

    local finalResultTaskDataList = {}
    if allAchieveTasks and next(allAchieveTasks) then
        self.ReceiveAll = true        -- 一键领取激活
        local receiveCb = function ()
            IsMulting = true
            XLuaUiManager.SetMask(true)
            XDataCenter.TaskManager.FinishMultiTaskRequest(allAchieveTasks, function(rewardGoodsList)
                -- 第一次请求返回 必不做弹窗奖励，插入奖励列表 等待refresh 检测同步的任务是否还有未领取
                for key, reward in pairs(rewardGoodsList) do
                    table.insert(ShowRewardList, reward)
                end
            end)
        end
        finalResultTaskDataList[1] = {ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks, ReceiveCb = receiveCb}
        for i = 1, #weeklyTasks do
            table.insert(finalResultTaskDataList, weeklyTasks[i])
        end
    else
        self.ReceiveAll = false
        finalResultTaskDataList = weeklyTasks 
    end

    return finalResultTaskDataList
end

--动态列表事件
function XUiPanelTaskWeekly:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.WeeklyTasks[index]
        grid.RootUi = self.Parent
        grid:Open()
        grid:ResetData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()    
    end
end

function XUiPanelTaskWeekly:GetWeeklyTasks()
    return XDataCenter.TaskManager.GetWeeklyTaskList()
end

function XUiPanelTaskWeekly.JumpToSignCardAfterGetReward()
    local justOnceFlagKey = "XUiPanelTaskWeekly.JumpToSignCardAfterGetReward.justOnceFlagKey_" .. XPlayer.Id
    if XSaveTool.GetData(justOnceFlagKey) == "1" then return end

    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data then return end
    if data.DailyRewardRemainDay <= 0 then return end

    local cardsMissed = 0
    if data.DailyRewardSupplementGetData then
        cardsMissed = data.DailyRewardSupplementGetData.Count
    end

    if cardsMissed <= 0 then return end

    local params = {
        FunctionType = XAutoWindowConfigs.AutoFunctionType.Card,
        WelfareId = XSignInConfigs.GetWelfareIdByPurchasePackageId(data.Id)
    }

    XLuaUiManager.Open("UiWelfare", nil, nil, params)

    XDataCenter.GuideManager.PlayGuide(
        CS.XGame.ClientConfig:GetInt("PurchaseYKFirstGetRetroactiveCardGuide"))

    XSaveTool.SaveData(justOnceFlagKey, "1")
end

function XUiPanelTaskWeekly:OnGetReward()
    XDataCenter.TaskManager:GetWeeklyActivenessRewardRequest(function(resp)
        self:RefreshWeeklyTaskRewardBar()
        XUiManager.OpenUiObtain(
            resp.RewardGoodsList,
            nil,
            self.JumpToSignCardAfterGetReward,
            nil,
            0)
    end)
end

function XUiPanelTaskWeekly:ReleaseRefreshWeeklyTaskRewardBarSchedule()
    if self._ScheduleRefreshWeeklyTaskRewardBar then
        XScheduleManager.UnSchedule(self._ScheduleRefreshWeeklyTaskRewardBar)
        self._ScheduleRefreshWeeklyTaskRewardBar = nil
    end
end

function XUiPanelTaskWeekly:RefreshWeeklyTaskRewardBar()
    if XUiManager.IsHideFunc then
        self.TxtTasksFinished.transform.parent.gameObject:SetActiveEx(false)
        return
    end

    local activenessCount = #self.WeeklyActiveness.Activeness
    local maxActiveness = self.WeeklyActiveness.Activeness[activenessCount]
    local activeness = XDataCenter.TaskManager.GetWeeklyTaskActiveness()

    self.TxtTasksFinished.text = tostring(activeness)
    self.TxtTasksFinishedAll.text = "/" .. tostring(maxActiveness)

    local amount = XMath.Clamp(activeness / maxActiveness, 0, 1)

    self.ImgTasksFinishedProgress:DOFillAmount(amount, 2)

    if not self.PanelTasksFinishedCountArrivedGrids then
        self.PanelTasksFinishedCountArrivedGrids = {}
    end

    self:ReleaseRefreshWeeklyTaskRewardBarSchedule()

    self._ScheduleRefreshWeeklyTaskRewardBar = XScheduleManager.ScheduleNextFrame(function()
        self:ReleaseRefreshWeeklyTaskRewardBarSchedule()

        local onGetRewardHandler = handler(self, self.OnGetReward)

        local barWidth = self.ImgTasksFinishedProgress.rectTransform.rect.width
        local barX = self.ImgTasksFinishedProgress.rectTransform.anchoredPosition3D.x

        local gridArgs = XTool.MakeArray(activenessCount, function(i)
            return {
                PositionX = barX + barWidth / activenessCount * i,
                Activeness = activeness,
                TargetActiveness = self.WeeklyActiveness.Activeness[i],
                RewardId = self.WeeklyActiveness.RewardId[i],
                OnGetReward = onGetRewardHandler
            }
        end)

        XTool.SetDataForGenericGrid(
            self.PanelTasksFinishedCountArrivedGrids,
            gridArgs,
            self.PanelWeeklyTaskRewardGrid.gameObject,
            self.PanelWeeklyTaskRewardGrid.parent,
            self,
            require("XUi/XUiTask/XPanelWeeklyTasksRewardGrid"))
    end)
end

function XUiPanelTaskWeekly:_HideAllWeeklyTaskRewardGrid()
    if not XTool.IsTableEmpty(self.PanelTasksFinishedCountArrivedGrids) then
        for i, v in pairs(self.PanelTasksFinishedCountArrivedGrids) do
            v:Close()
        end
    end
end

return XUiPanelTaskWeekly
