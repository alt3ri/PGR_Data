---@class XUiPanelTaskCanLiver
local XUiPanelTaskCanLiver = XClass(XUiNode, "XUiPanelTaskCanLiver")
local MaskKey = "XUiPanelTaskCanLiver"


function XUiPanelTaskCanLiver:OnStart()
    self.IsMulting = false
    self.ShowRewardList = {}

    self.BtnShop.CallBack = function()
        local skipToShopId = 90055
        XFunctionManager.SkipInterface(skipToShopId)
    end

    local XDynamicDrawCanLiverTask = require("XUi/XUiTask/XDynamicDrawCanLiverTask")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelTaskCanLiverList, XDynamicDrawCanLiverTask)
    
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskFinishFail, self)
end

function XUiPanelTaskCanLiver:OnEnable()
    self:Open()

    self.CanLiverTasks = self:GetTasks()
    self.PanelNoneCanLiverTask.gameObject:SetActive(#self.CanLiverTasks <= 0)
    if XMVCA.XItemRestrict:IsAllItemsReachMax(XEnumConst.ItemRestrict.Type.DrawCanLiver) then
        self.TxtNone.text = XUiHelper.GetText("DrawCanLiverItemReachMax")
    else
        self.TxtNone.text = XUiHelper.GetText("DrawCanLiverWeekTaskFinish")
    end
    local cId = 770400 -- 临时写死
    local isShowShop = XConditionManager.CheckCondition(cId)
    self.PanelBtnShop.gameObject:SetActiveEx(isShowShop)
    self.DynamicTable:SetDataSource(self.CanLiverTasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelTaskCanLiver:OnDestroy()
    self.IsMulting = false
    self.ShowRewardList = {}
    self.IsWaitServerResponse = false
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskFinishFail, self)

    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end
end

function XUiPanelTaskCanLiver:OnTaskFinishFail()
    if self.IsWaitServerResponse or self.IsMulting then
        self.IsWaitServerResponse = false
        self.IsMulting = false
        self.ShowRewardList = {}
        if XLuaUiManager.IsMaskShow(MaskKey) then
            XLuaUiManager.SetMask(false, MaskKey)
        end
        self:Refresh()
    end
end

----------------------------------------------------
-- ★ 本函数必须正确，否则不会弹奖励
-- ★ 只处理本面板发起的领取流程，防止其他面板的事件触发意外领取
----------------------------------------------------
function XUiPanelTaskCanLiver:CheckRefreshLeftNewTask()
    -- 只处理本面板发起的领取流程，忽略其他面板触发的事件
    if not self.IsMulting then
        return false
    end

    if self.IsWaitServerResponse then
        return true
    end
    local tempTasks = self:GetTasks()

    if self.ReceiveAll then
        -- 可能还有剩余任务，要继续 finish
        local header = tempTasks[1]
        local leftTasks = header and header.AllAchieveTaskDatas

        if leftTasks and next(leftTasks) then
            self.IsWaitServerResponse = true
            XDataCenter.TaskManager.FinishMultiTaskRequest(leftTasks, function(rewardGoodsList)
                self.IsWaitServerResponse = false
                for _, reward in pairs(rewardGoodsList) do
                    table.insert(self.ShowRewardList, reward)
                end
                self:Refresh(true)
            end)
        end

    elseif self.ShowRewardList and next(self.ShowRewardList) then
        -- ★ 最终弹奖励（所有奖励合并弹出）
        XUiManager.OpenUiObtain(self.ShowRewardList)
        self.ShowRewardList = {}
        self.IsMulting = false

        if XLuaUiManager.IsMaskShow(MaskKey) then
            XLuaUiManager.SetMask(false, MaskKey)
        end
    else
        -- ★ 即使没有奖励，流程结束也必须解锁
        self.ShowRewardList = {}
        self.IsMulting = false

        if XLuaUiManager.IsMaskShow(MaskKey) then
            XLuaUiManager.SetMask(false, MaskKey)
        end
    end

    return self.ReceiveAll
end

----------------------------------------------------
-- ★ 必须与 Weekly 逻辑完全一致
----------------------------------------------------
function XUiPanelTaskCanLiver:Refresh(isMulti)
    if not self:IsNodeShow() then return end

    if isMulti and self:CheckRefreshLeftNewTask() then
        return
    end

    if self.IsMulting then
        return
    end

    self.CanLiverTasks = self:GetTasks()
    self.PanelNoneCanLiverTask.gameObject:SetActive(#self.CanLiverTasks <= 0)
    if XMVCA.XItemRestrict:IsAllItemsReachMax(XEnumConst.ItemRestrict.Type.DrawCanLiver) then
        self.TxtNone.text = XUiHelper.GetText("DrawCanLiverItemReachMax")
    else
        self.TxtNone.text = XUiHelper.GetText("DrawCanLiverWeekTaskFinish")
    end
    self.DynamicTable:SetDataSource(self.CanLiverTasks)
    self.DynamicTable:ReloadDataSync()
end

----------------------------------------------------
-- ★ 一键领取核心（与 Weekly 结构必须一致）
----------------------------------------------------
function XUiPanelTaskCanLiver:GetTasks()
    local allAchieveTasks = {}

    ----------------------------
    -- 1. 取出任务列表
    ----------------------------
    local taskGroupIds = XMVCA.XItemRestrict:GetTaskGroupIdList(XEnumConst.ItemRestrict.Type.DrawCanLiver)
    if XTool.IsTableEmpty(taskGroupIds) then
        self.ReceiveAll = false
        return {}
    end

    local tasks = XDataCenter.TaskManager.GetCanLiverTaskList()
    for index, groupId in ipairs(taskGroupIds) do
        if XTool.IsNumberValid(groupId) then
            if CS.XGame.ClientConfig:GetInt("DrawCanLiverWeekTaskGroupIdIndex") == index then
                local list = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
                self.CurrDrawCanLiverWeekTaskList = self.CurrDrawCanLiverWeekTaskList or {}
                for k, task in pairs(list) do
                    self.CurrDrawCanLiverWeekTaskList[task.Id] = true
                end
            end
        end
    end

    ----------------------------
    -- 2. 找出可领取任务
    ----------------------------
    for _, t in ipairs(tasks) do
        if t.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks, t.Id)
        end
    end

    ----------------------------
    -- 3. 组装 UI 列表（关键）
    ----------------------------
    local result = {}

    if next(allAchieveTasks) then
        self.ReceiveAll = true

        local receiveCb = function()
            self.IsMulting = true
            XLuaUiManager.SetMask(true, MaskKey)
            self.IsWaitServerResponse = true

            -- ★ 第一次 finish：不弹奖励，只累积
            XDataCenter.TaskManager.FinishMultiTaskRequest(allAchieveTasks, function(rewardGoodsList)
                self.IsWaitServerResponse = false
                if rewardGoodsList then
                    for _, r in ipairs(rewardGoodsList) do
                        table.insert(self.ShowRewardList, r)
                    end
                end
                self:Refresh(true)
            end)
        end

        -- ★ Weekly 的结构：首个元素是头节点（ReceiveAll = true）
        result[1] = {
            ReceiveAll = true,
            AllAchieveTaskDatas = allAchieveTasks,
            ReceiveCb = receiveCb
        }

        -- 任务接在后面
        for i = 1, #tasks do
            table.insert(result, tasks[i])
        end

    else
        self.ReceiveAll = false
        result = tasks
    end

    return result
end

----------------------------------------------------
-- 动态格子
----------------------------------------------------
function XUiPanelTaskCanLiver:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.CanLiverTasks[index]
        grid.RootUi = self.Parent
        local isSetUpdateWeeklyTime = self.CurrDrawCanLiverWeekTaskList and self.CurrDrawCanLiverWeekTaskList[data.Id]
        grid:SetIsUpdateWeeklyTime(isSetUpdateWeeklyTime)
        grid:SetTxtTaskLimitVisible(XMVCA.XItemRestrict:IsItemReachMaxByIndex(XEnumConst.ItemRestrict.Type.DrawCanLiver, 1))
        grid:ResetData(data)
    end
end

return XUiPanelTaskCanLiver
