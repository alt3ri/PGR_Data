local XUiDyeMergeTaskGridTask = require("XUi/XUiDyeMergeGame/UiDyeMergeTask/XUiDyeMergeTaskGridTask")
---
---@class XUiDyeMergeTask: XLuaUi
---@field protected _Control
local XUiDyeMergeTask = XLuaUiManager.Register(XLuaUi, "UiDyeMergeTask")

function XUiDyeMergeTask:OnAwake()
    self:InitComponents()

end

function XUiDyeMergeTask:InitComponents()
    -- Back Mainui Help
    self:BindExitBtns()
    
    self.GridTask.gameObject:SetActiveEx(false)
    self._OnRecievedAllHandler = handler(self, self._OnRecievedAll)

    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.SViewTask, XUiDyeMergeTaskGridTask, self._OnRecievedAllHandler)
end

function XUiDyeMergeTask:OnStart(...)

end

function XUiDyeMergeTask:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshCurTabTasks, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshCurTabTasks, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.RefreshCurTabTasks, self)

    self:RefreshCurTabTasks()
end

function XUiDyeMergeTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshCurTabTasks, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshCurTabTasks, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.RefreshCurTabTasks, self)
end

function XUiDyeMergeTask:OnDestroy()
    
end

function XUiDyeMergeTask:RefreshCurTabTasks()
    local taskDataList, canRecieveTaskDataList = XMVCA.XDyeMergeGame:GetConfigTaskIdList(true, true)

    -- 缓存所有可领取任务ID，供 BeforeFinishCheckEvent 回调读取
    self._AchievedTaskIds = {}
    if not XTool.IsTableEmpty(canRecieveTaskDataList) then
        for _, taskData in ipairs(canRecieveTaskDataList) do
            table.insert(self._AchievedTaskIds, taskData.Id)
        end
    end

    if not XTool.IsTableEmpty(taskDataList) then
        self.DynamicTable:SetDataSource(taskDataList)
        self.DynamicTable:ReloadDataASync(1)
        self.ImgEmpty.gameObject:SetActiveEx(false)
        return
    end

    self.DynamicTable:SetDataSource(nil)
    self.DynamicTable:RecycleAllTableGrid()
    self.ImgEmpty.gameObject:SetActiveEx(true)
end

---@param grid XUiDyeMergeTaskGridTask
function XUiDyeMergeTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.DynamicTable.DataSource[index]

        if XTool.IsNumberValidEx(taskData) then
            taskData = XDataCenter.TaskManager.GetTaskDataById(taskData)
        end

        grid:ResetData(taskData)
    end
end

function XUiDyeMergeTask:_OnRecievedAll()
    local achievedTaskIds = self._AchievedTaskIds
    if XTool.IsTableEmpty(achievedTaskIds) then
        return true
    end

    -- 装备背包容量校验
    local weaponCount = 0
    local chipCount = 0
    for _, taskId in pairs(achievedTaskIds) do
        local taskTemplate = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        if not taskTemplate then
            goto continue
        end
        local rewards = XRewardManager.GetRewardList(taskTemplate.RewardId)
        if rewards then
            for i = 1, #rewards do
                local rewardsId = rewards[i].TemplateId
                if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
                    weaponCount = weaponCount + 1
                elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
                    chipCount = chipCount + 1
                end
            end
        end
        ::continue::
    end
    if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
            chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return false
    end

    -- 批量领取所有可领取任务
    XDataCenter.TaskManager.FinishMultiTaskRequest(achievedTaskIds, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
    return false
end

return XUiDyeMergeTask