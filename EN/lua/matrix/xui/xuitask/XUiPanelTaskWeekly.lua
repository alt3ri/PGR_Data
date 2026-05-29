local XUiPanelTask = require("XUi/XUiMoneyReward/XUiPanelTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XDynamicDailyTask = require("XUi/XUiTask/XDynamicDailyTask")
local XPanelWeeklyTasksRewardGrid = require("XUi/XUiTask/XPanelWeeklyTasksRewardGrid")
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
end

function XUiPanelTaskWeekly:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)
    self.DynamicTable:RecycleAllTableGrid()
    self:_HideAllWeeklyTaskRewardGrid()
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

    local barWidth = self.ImgTasksFinishedProgress.rectTransform.rect.width
    local barX = self.ImgTasksFinishedProgress.rectTransform.anchoredPosition3D.x

    for i = 1, activenessCount do
        local grid = self.PanelTasksFinishedCountArrivedGrids[i]
        if not grid then
            if i == 1 then
                grid = XPanelWeeklyTasksRewardGrid.New(
                    self.PanelWeeklyTaskRewardGrid,
                    self.Parent)
            else
                local go = CS.UnityEngine.Object.Instantiate(
                    self.PanelWeeklyTaskRewardGrid)

                go.transform:SetParent(
                    self.PanelWeeklyTaskRewardGrid.transform.parent,
                    false)

                grid = XPanelWeeklyTasksRewardGrid.New(
                    go, self.Parent)
            end

            self.PanelTasksFinishedCountArrivedGrids[i] = grid

            grid.Transform.anchoredPosition3D = CS.UnityEngine.Vector3(
                barX + barWidth / activenessCount * i,
                grid.Transform.anchoredPosition3D.y,
                grid.Transform.anchoredPosition3D.z)

        end
        grid:Open()
        grid:SetData(
            activeness,
            self.WeeklyActiveness.Activeness[i],
            self.WeeklyActiveness.RewardId[i],
            function() self:OnGetReward() end)
    end
end

function XUiPanelTaskWeekly:_HideAllWeeklyTaskRewardGrid()
    if not XTool.IsTableEmpty(self.PanelTasksFinishedCountArrivedGrids) then
        for i, v in pairs(self.PanelTasksFinishedCountArrivedGrids) do
            v:Close()
        end
    end
end

return XUiPanelTaskWeekly
