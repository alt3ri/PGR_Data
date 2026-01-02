---@class XUiPanelTaskCanLiver
local XUiPanelTaskCanLiver = XClass(XUiNode, "XUiPanelTaskCanLiver")

local IsMulting = false
local ShowRewardList = {}

function XUiPanelTaskCanLiver:OnStart()
    self.BtnShop.CallBack = function()
        local skipToShopId = 90055
        XFunctionManager.SkipInterface(skipToShopId)
    end

    local XDynamicDrawCanLiverTask = require("XUi/XUiTask/XDynamicDrawCanLiverTask")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelTaskCanLiverList, XDynamicDrawCanLiverTask)
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

----------------------------------------------------
-- ★ 本函数必须正确，否则不会弹奖励
----------------------------------------------------
function XUiPanelTaskCanLiver:CheckRefreshLeftNewTask()
    local tempTasks = self:GetTasks()

    if self.ReceiveAll then
        -- 可能还有剩余任务，要继续 finish
        local header = tempTasks[1]
        local leftTasks = header and header.AllAchieveTaskDatas

        if leftTasks and next(leftTasks) then
            XDataCenter.TaskManager.FinishMultiTaskRequest(leftTasks, function(rewardGoodsList)
                for _, reward in pairs(rewardGoodsList) do
                    table.insert(ShowRewardList, reward)
                end
            end)
        end

    elseif ShowRewardList and next(ShowRewardList) then
        -- ★ 最终弹奖励（所有奖励合并弹出）
        XUiManager.OpenUiObtain(ShowRewardList)
        ShowRewardList = {}
        IsMulting = false
        XLuaUiManager.SetMask(false)
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

    if IsMulting then
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
            IsMulting = true
            XLuaUiManager.SetMask(true)

            -- ★ 第一次 finish：不弹奖励，只累积
            XDataCenter.TaskManager.FinishMultiTaskRequest(allAchieveTasks, function(rewardGoodsList)
                for _, r in ipairs(rewardGoodsList) do
                    table.insert(ShowRewardList, r)
                end
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
