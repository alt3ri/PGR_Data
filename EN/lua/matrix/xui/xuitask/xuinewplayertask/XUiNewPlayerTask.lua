local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
-- 新手任务二期
---@class XUiNewPlayerTaskNew: XUiNode
---@field Parent XUiTask
local XUiNewPlayerTask = XClass(XUiNode, "XUiNewPlayerTask")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiGridNewPlayerTaskActive = require("XUi/XUiTask/XUiNewPlayerTask/XUiGridNewPlayerTaskActive")

local FULL_PROGRESS = 0.9
local ITEM_TASK_PROGRESS_ID = CS.XGame.ClientConfig:GetInt("NewPlayerTaskExpId")

--region 生命周期

---@param rootUi XLuaUi
function XUiNewPlayerTask:OnStart(rootUi)
    self.RootUi = rootUi
    self:InitUiDefaultState()
    
    self.BtnDayTab = {}
    self.TotalProgress = {}
    self.RegisterDay = XTaskConfig.GetNewPlayerTaskGroupTemplate()
    self.NewbieActiveness = XTaskConfig.GetTaskNewbieActivenessTemplate()
    self:InitView()
end

function XUiNewPlayerTask:OnEnable()
    local hintTab = XDataCenter.TaskManager.GetNewPlayerHint(XDataCenter.TaskManager.NewPlayerLastSelectTab, self.RegisterDay[1].OpenDay)

    if not XTool.IsNumberValidEx(hintTab) or hintTab < 0 then
        hintTab = self.CurrentIndex or 1
    end
    
    self.TabBtnGroup:SelectIndex(hintTab)
    self:RefreshBtnDayTabStatus()
    self:RefreshProgress()
    
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED, self.RefreshBtnDayTabStatus, self)
end

function XUiNewPlayerTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED, self.RefreshBtnDayTabStatus, self)
end

--endregion

--region Init
function XUiNewPlayerTask:InitUiDefaultState()
    self.PanelDaily.gameObject:SetActiveEx(true)
    self.PanelNoneDailyTask.gameObject:SetActiveEx(false)
    self.GridNewPlayerTargetTask.gameObject:SetActiveEx(false)
    self.PanelNewbieActive.gameObject:SetActiveEx(false)
end

function XUiNewPlayerTask:InitView()
    self:InitDynamicTable()
    self:InitDayTab()
    self:InitProgress()
end

function XUiNewPlayerTask:InitDayTab()
    self.BtnNewbieTaskTab.gameObject:SetActiveEx(false)
    self.BtnDayTab = {}
    
    for i = 1, #self.RegisterDay do
        local go = XUiHelper.Instantiate(self.BtnNewbieTaskTab, self.TabBtnGroup.transform)
        local btn = go:GetComponent("XUiButton")
        btn:SetName(XUiHelper.GetText("NewbieDayTab1", self.RegisterDay[i].OpenDay))
        self.BtnDayTab[i] = btn
        btn.gameObject:SetActiveEx(true)
    end
    
    self.TabBtnGroup:Init(self.BtnDayTab, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiNewPlayerTask:InitProgress()
    self.TotalCount = #self.NewbieActiveness.Activeness
    self.MaxProgress = self.NewbieActiveness.Activeness[self.TotalCount]
    local uiName = self.PanelNewbieActive.name
    for i = 1, self.TotalCount do
        local progress = self.TotalProgress[i]
        if not progress then
            local ui = XUiHelper.Instantiate(self.PanelNewbieActive, self.ImgProgress.transform)
            ui.name = string.format("%s%s", uiName, i)
            progress = XUiGridNewPlayerTaskActive.New(ui, self, self.RootUi, i, self.NewbieActiveness.Activeness[i], self.MaxProgress)
            progress:Open()
            self.TotalProgress[i] = progress
            ui.gameObject:SetActiveEx(true)
        end
    end

    self.ImgProgressRect = self.ImgProgress:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self.TemplatePosition = self.PanelNewbieActive.transform.localPosition
    self.TemplateRect = self.PanelNewbieActive:GetComponent(typeof(CS.UnityEngine.RectTransform))

    -- 设置总进度值 (读进度奖励配置表的最后的一个值)
    self.TxtTotalProgress.text = string.format("/%d", self.MaxProgress)
end

function XUiNewPlayerTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self, handler(self, self.OnFinishTaskEvent))
    self.DynamicTable:SetDelegate(self)
end

--endregion

--region EventListener
function XUiNewPlayerTask:OnClickTabCallBack(tabIndex)
    local day = self.RegisterDay[tabIndex]

    if self:IsCurrentLock(day.OpenDay) then
        XUiManager.TipMsg(CSXTextManagerGetText("NewbieDayUnlock"))
        return
    end

    self.CurrentIndex = tabIndex
    self.CurrentDay = day.OpenDay

    self:SetupDynamicTable()
    XDataCenter.TaskManager.SaveNewPlayerHint(XDataCenter.TaskManager.NewPlayerLastSelectTab, day)
end

function XUiNewPlayerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.Parent
        
        local taskId = self.CurrentNewbieTasks[index]
        local templateTaskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

        grid:ResetData(templateTaskData)
    end
end

function XUiNewPlayerTask:OnFinishTaskEvent()
    if not XTool.IsTableEmpty(self.AllCanRecieveTaskIds) then
        local weaponCount = 0
        local chipCount = 0

        for key, taskId in pairs(self.AllCanRecieveTaskIds) do --装备上限判断
            local tableData = XDataCenter.TaskManager.GetTaskTemplate(taskId)
            local rewards = XRewardManager.GetRewardList(tableData.RewardId)
            for i = 1, #rewards do
                local rewardsId = rewards[i].TemplateId
                if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
                    weaponCount = weaponCount + 1
                elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
                    chipCount = chipCount + 1
                end
            end
            if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
                    chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
                return
            end
        end

        local taskIds = self.AllCanRecieveTaskIds
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
            local horizontalNormalizedPosition = 0
            XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)

            self:CheckIsNewPlayerTaskOver()
        end)
        -- 表示打断内部流程
        return false
    else
        -- 表示继续内部常规流程
        return true
    end
    
end


--endregion

--region Getter

function XUiNewPlayerTask:IsCurrentLock(day)
    if XPlayer.NewPlayerTaskActiveDay == nil then
        return true
    end

    return day > XPlayer.NewPlayerTaskActiveDay
end
--endregion

function XUiNewPlayerTask:Refresh()
    self:RefreshBtnDayTabStatus()
    self:SetupDynamicTable()
    self:RefreshProgress()
    self:CheckTabAnimation()
end

function XUiNewPlayerTask:SetupDynamicTable()
    local curNewbieTask = XDataCenter.TaskManager.GetNewPlayerTaskListByGroup(self.CurrentDay)
    if curNewbieTask == nil then
        return
    end
    self.CurrentNewbieTasks = {}
    self.AllCanRecieveTaskIds = {}
    for _, v in pairs(curNewbieTask) do
        local stateTask = XDataCenter.TaskManager.GetTaskDataById(v)
        if stateTask.State ~= XDataCenter.TaskManager.TaskState.Finish and stateTask.State ~= XDataCenter.TaskManager.TaskState.Invalid then
            table.insert(self.CurrentNewbieTasks, v)

            if stateTask.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(self.AllCanRecieveTaskIds, v)
            end
        end
    end
    
    self.PanelNoneDailyTask.gameObject:SetActive(#self.CurrentNewbieTasks <= 0)
    self.DynamicTable:SetDataSource(self.CurrentNewbieTasks)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiNewPlayerTask:RefreshBtnDayTabStatus()
    for i, btn in pairs(self.BtnDayTab) do
        local day = self.RegisterDay[i]
        -- 刷新红点 和 按钮锁定状态
        if not self:IsCurrentLock(day.OpenDay) then
            if self.CurrentIndex ~= i then
                btn:SetButtonState(CS.UiButtonState.Normal)
            end
            btn:ShowReddot(XDataCenter.TaskManager.GetNewbiePlayTaskReddotByOpenDay(day.OpenDay))
            -- 刷新任务Tag
            self:_UpdateTaskListTag(btn, day.OpenDay)
        else
            btn:SetButtonState(CS.UiButtonState.Disable)
            btn:ShowReddot(false)
            btn:ShowTag(false)
        end
    end
end

function XUiNewPlayerTask:RefreshProgressTransform()
    -- 异形屏适配需要
    XScheduleManager.ScheduleOnce(function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end

        -- 更新位置
        local totalWidth = self.ImgProgressRect.rect.size.x
        local activeWidthOffset = self.TemplateRect.rect.size.x / 2
        for i = 1, self.TotalCount do
            local currentProgress = self.NewbieActiveness.Activeness[i] * 1.0 / self.MaxProgress * FULL_PROGRESS
            local progress = self.TotalProgress[i]
            if progress then
                progress.Transform:GetComponent(typeof(CS.UnityEngine.RectTransform)).anchoredPosition3D = CS.UnityEngine.Vector3(currentProgress * totalWidth - activeWidthOffset, self.TemplatePosition.y, self.TemplatePosition.z)
            end
        end
    end, 1)
end

function XUiNewPlayerTask:RefreshProgress()
    -- 刷新进度奖励位置
    self:RefreshProgressTransform()

    local progressNumber = XDataCenter.ItemManager.GetCount(ITEM_TASK_PROGRESS_ID) or 0
    -- 当前进度值
    self.TxtCurProgress.text = progressNumber
    local currentProgress = progressNumber * 1.0 / self.MaxProgress * FULL_PROGRESS
    self.ImgProgress.fillAmount = (currentProgress > FULL_PROGRESS) and 1 or currentProgress

    for _, progress in pairs(self.TotalProgress) do
        progress:Refresh(progressNumber)
    end
end

function XUiNewPlayerTask:CheckIsNewPlayerTaskOver()
    if not XDataCenter.TaskManager.CheckNewbieTaskAvailable() then
        self.Parent:UpdateTabListShow()
    end
end

-- 检测是否播放页签动画
-- 条件是：领取完毕某个页签所有奖励
function XUiNewPlayerTask:CheckTabAnimation()

end

function XUiNewPlayerTask:_UpdateTaskListTag(tab, openDay)
    local curNewbieTask = XDataCenter.TaskManager.GetNewPlayerTaskListByGroup(openDay)
    if curNewbieTask == nil then
        tab:ShowTag(true)
        return
    end
    for _, v in pairs(curNewbieTask) do
        local stateTask = XDataCenter.TaskManager.GetTaskDataById(v)
        if stateTask.State ~= XDataCenter.TaskManager.TaskState.Finish and stateTask.State ~= XDataCenter.TaskManager.TaskState.Invalid then
            tab:ShowTag(false)
            return
        end
    end
    tab:ShowTag(true)
end

return XUiNewPlayerTask