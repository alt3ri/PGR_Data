local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XDynamicDailyTask = require("XUi/XUiTask/XDynamicDailyTask")

---@class XUiPanelTaskWeekly
local XUiPanelTaskWeekly = XClass(XUiNode, "XUiPanelTaskWeekly")
local IsMulting = false
-- 任务奖励与里程碑奖励分开累积，各弹一个弹窗
local ShowRewardList = {}
local ActivenessRewardList = {}

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
        -- 任务已全部领完，接着领里程碑奖励并收尾
        self:_ReceiveActivenessAndFinish()
    end

    return self.ReceiveAll
end

-- 是否存在已达标但未领取的任务完成数量奖励（里程碑活跃度奖励）
function XUiPanelTaskWeekly:HasUnclaimedActivenessReward()
    local activeness = XDataCenter.TaskManager.GetWeeklyTaskActiveness()
    for _, target in ipairs(self.WeeklyActiveness.Activeness) do
        if activeness >= target and not XDataCenter.TaskManager.WeeklyActivenessProgressRewardGot(target) then
            return true
        end
    end
    return false
end

-- 领取达标的里程碑（任务完成数量）奖励，随后收尾
function XUiPanelTaskWeekly:_ReceiveActivenessAndFinish()
    if self:HasUnclaimedActivenessReward() then
        XDataCenter.TaskManager:GetWeeklyActivenessRewardRequest(function(resp)
            -- 进度已推进但本次无实际发奖时 RewardGoodsList 为 nil，需判空防崩
            if resp.RewardGoodsList then
                for _, reward in pairs(resp.RewardGoodsList) do
                    table.insert(ActivenessRewardList, reward)
                end
            end
            self:_FinishMultiReceive()
        end)
    else
        self:_FinishMultiReceive()
    end
end

-- 一键领取收尾：任务奖励、里程碑奖励分两个弹窗依次展示。
-- 状态复位必须在此同步执行，不能放进弹窗关闭回调，否则复位前若再有任务同步事件进来，
-- CheckRefreshLeftNewTask 会重复进入本函数，造成重复弹窗、SetMask(false) 多减使 MaskCount 变负。
function XUiPanelTaskWeekly:_FinishMultiReceive()
    local horizontalNormalizedPosition = 0
    -- 先持有旧列表引用，复位后弹窗内容不受影响
    local taskRewards = ShowRewardList
    local activenessRewards = ActivenessRewardList
    local hasTaskReward = taskRewards and next(taskRewards)
    local hasActivenessReward = activenessRewards and next(activenessRewards)

    ShowRewardList = {}
    ActivenessRewardList = {}
    IsMulting = false
    XLuaUiManager.SetMask(false)

    -- 里程碑弹窗作为任务弹窗的关闭回调，保证两者先后出现
    local openActivenessObtain = function()
        if hasActivenessReward then
            XUiManager.OpenUiObtain(activenessRewards, nil, nil, nil, horizontalNormalizedPosition)
        end
    end

    if hasTaskReward then
        XUiManager.OpenUiObtain(taskRewards, nil, openActivenessObtain, nil, horizontalNormalizedPosition)
    else
        openActivenessObtain()
    end

    self:Refresh()
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
    local hasAchieveTask = allAchieveTasks and next(allAchieveTasks)
    -- self.ReceiveAll 仅表示"还有已达标可领的任务"，供循环领取控制用，不能含里程碑，否则会死循环、mask 卡死
    self.ReceiveAll = hasAchieveTask and true or false
    -- 一键按钮显示条件：有可领任务，或有达标未领的里程碑奖励
    local showReceiveAll = hasAchieveTask or self:HasUnclaimedActivenessReward()
    if showReceiveAll then
        local receiveCb = function ()
            IsMulting = true
            XLuaUiManager.SetMask(true)
            if allAchieveTasks and next(allAchieveTasks) then
                XDataCenter.TaskManager.FinishMultiTaskRequest(allAchieveTasks, function(rewardGoodsList)
                    -- 任务奖励只累积不弹窗，待确认无剩余任务后统一收尾
                    for key, reward in pairs(rewardGoodsList) do
                        table.insert(ShowRewardList, reward)
                    end
                end)
            else
                -- 无可领任务、仅有达标里程碑：直接领里程碑并收尾
                self:_ReceiveActivenessAndFinish()
            end
        end
        finalResultTaskDataList[1] = {ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks, ReceiveCb = receiveCb}
        for i = 1, #weeklyTasks do
            table.insert(finalResultTaskDataList, weeklyTasks[i])
        end
    else
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
