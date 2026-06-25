local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
-- 新手任务二期
---@class XUiNewbieTaskMain: XUiNode
---@field Parent XUiTask
local XUiNewbieTaskMain = XClass(XUiNode, "XUiNewbieTaskMain")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiGridNewbieActive = require("XUi/XUiTask/XUiNewbieTask/XUiGridNewbieActive")
local XUiPanelNewbieTaskSuccess = require("XUi/XUiTask/XUiNewbieTask/XUiPanelNewbieTaskSuccess")

local FULL_PROGRESS = 0.9

--region 生命周期

---@param rootUi XLuaUi
function XUiNewbieTaskMain:OnStart(rootUi)
    self.RootUi = rootUi
    self:InitUiDefaultState()
    
    self.BtnDayTab = {}
    self.TotalProgress = {}
    self.RegisterDay = XDataCenter.NewbieTaskManager.GetNewbieTaskRegisterDay()
    self.NewbieActiveness = XTaskConfig.GetNewbieTaskTwoActivenessTemplate()
    self:InitView()

    self.NewbieTaskSuccess = XUiPanelNewbieTaskSuccess.New(self.PlayerTaskSuccess, self)

    self.CurrentIndex = self:GetNewRegisterDay()
end

function XUiNewbieTaskMain:OnEnable()
    self.TabBtnGroup:SelectIndex(self.CurrentIndex or 1)
    self:RefreshBtnDayTabStatus()
    self:RefreshProgress()
    
    -- 保存每日是否进入过
    XDataCenter.NewbieTaskManager.SaveDailyFirstEnter()
    self:CheckRewardReceiveStatus()
    
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED, self.RefreshBtnDayTabStatus, self)
end

function XUiNewbieTaskMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED, self.RefreshBtnDayTabStatus, self)

    self:HideProgress()
end

--endregion

--region Init
function XUiNewbieTaskMain:InitUiDefaultState()
    self.PanelDaily.gameObject:SetActiveEx(true)
    self.PlayerTaskSuccess.gameObject:SetActiveEx(false)
    self.PanelNoneDailyTask.gameObject:SetActiveEx(false)
    self.GridNewbieTaskItem.gameObject:SetActiveEx(false)
    self.PanelNewbieActive.gameObject:SetActiveEx(false)
end

function XUiNewbieTaskMain:InitView()
    self:InitDynamicTable()
    self:InitDayTab()
    self:InitProgress()
end

function XUiNewbieTaskMain:InitDayTab()
    self.BtnNewbieTaskTab.gameObject:SetActiveEx(false)
    self.BtnDayTab = {}
    
    for i = 1, #self.RegisterDay do
        local go = XUiHelper.Instantiate(self.BtnNewbieTaskTab, self.TabBtnGroup.transform)
        local btn = go:GetComponent("XUiButton")
        btn:SetName(XUiHelper.GetText("NewbieDayTab2", XTool.ConvertNumberString(self.RegisterDay[i])))
        self.BtnDayTab[i] = btn
        btn.gameObject:SetActiveEx(true)
    end
    
    self.TabBtnGroup:Init(self.BtnDayTab, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiNewbieTaskMain:InitProgress()
    self.TotalCount = #self.NewbieActiveness.Activeness
    self.MaxProgress = self.NewbieActiveness.Activeness[self.TotalCount]
    local uiName = self.PanelNewbieActive.name
    for i = 1, self.TotalCount do
        local progress = self.TotalProgress[i]
        if not progress then
            local ui = XUiHelper.Instantiate(self.PanelNewbieActive, self.ImgProgress.transform)
            ui.name = string.format("%s%s", uiName, i)
            progress = XUiGridNewbieActive.New(ui, self, self.RootUi, i, self.NewbieActiveness.Activeness[i], self.MaxProgress)
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

function XUiNewbieTaskMain:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self, handler(self, self.OnFinishTaskEvent))
    self.DynamicTable:SetDelegate(self)
end

--endregion

--region EventListener
function XUiNewbieTaskMain:OnClickTabCallBack(tabIndex)
    local day = self.RegisterDay[tabIndex]

    if not XDataCenter.NewbieTaskManager.CheckUnlockPeriod(day) then
        XUiManager.TipMsg(CSXTextManagerGetText("NewbieDayUnlock"))
        return
    end

    self.CurrentIndex = tabIndex
    self.CurrentDay = day

    self:SetupDynamicTable()
    local isSave = XDataCenter.NewbieTaskManager.SaveRegisterDayBtnClick(day)
    if isSave then
        self:RefreshBtnDayTabStatus()
        XEventManager.DispatchEvent(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED)
    end
end

function XUiNewbieTaskMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.Parent
        
        local taskId = self.DynamicTableDataList[index]
        local templateTaskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

        grid:ResetData(templateTaskData)
    end
end

-- 领取完奖励后的操作 如果有自选和非自选礼包直接打开
function XUiNewbieTaskMain:OnRewardTaskFinish(rewards)
    local asynOpenBagItem = asynTask(function(itemData, cb)
        XLuaUiManager.Open("UiBagItemInfoPanel", itemData, nil, nil, cb)
    end)

    local asynOpenSelectGift = asynTask(function(itemId, cb)
        XLuaUiManager.Open("UiNewbieSelectGift", itemId, cb)
    end)

    RunAsyn(function()
        for _, reward in pairs(rewards) do
            if XArrangeConfigs.GetType(reward.TemplateId) ~= XArrangeConfigs.Types.Item then
                -- 是道具
                goto CONTINUE
            end

            local itemData = XDataCenter.ItemManager.GetItem(reward.TemplateId)
            local data = XDataCenter.ItemManager.ConvertToGridData({ itemData })
            local itemId = data[1].Data.Id
            if not XDataCenter.ItemManager.IsUseable(itemId) then
                goto CONTINUE
            end

            if XDataCenter.ItemManager.IsSelectGift(itemId) then
                -- 自选礼包
                asynOpenSelectGift(itemId)
            else
                -- 非自选礼包
                asynOpenBagItem(data[1])
            end

            :: CONTINUE ::
        end
        self:CheckRewardReceiveStatus()
    end)
end

function XUiNewbieTaskMain:OnFinishTaskEvent()
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
-- 显示最新解锁的任务
function XUiNewbieTaskMain:GetNewRegisterDay()
    local index = 1
    for i, day in pairs(self.RegisterDay) do
        if XDataCenter.NewbieTaskManager.CheckUnlockPeriod(day) then
            if i > index then
                index = i
            end
        end
    end
    return index
end

--endregion

function XUiNewbieTaskMain:HideProgress()
    if not XTool.IsTableEmpty(self.TotalProgress) then
        for i, v in pairs(self.TotalProgress) do
            v:Close()
        end
    end
end

function XUiNewbieTaskMain:Refresh()
    if self._IsCloseInHonorRewardGot then
        XLog.Error('新手入门已领取所有奖励，但未受到正确的condition控制进行隐藏或锁定')
        return
    end
    self:SetupDynamicTable()
    if not self:CheckIsShowHonorReward() then
        self:RefreshProgress()
        self:RefreshBtnDayTabStatus()
    end
    self:CheckTabAnimation()
    self:CheckRewardReceiveStatus()
end

function XUiNewbieTaskMain:SetupDynamicTable()
    ---@type XTaskData[]
    self.DynamicTableDataList = XDataCenter.NewbieTaskManager.GetTaskDataList(self.CurrentDay)
    self.PanelNoneDailyTask.gameObject:SetActive(#self.DynamicTableDataList <= 0)

    if not XTool.IsTableEmpty(self.DynamicTableDataList) then
        self.AllCanRecieveTaskIds = {}
        -- 搜集可以领取奖励的任务
        for i, v in pairs(self.DynamicTableDataList) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(v)
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(self.AllCanRecieveTaskIds, v)
            end
        end
    end
    
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiNewbieTaskMain:RefreshBtnDayTabStatus()
    for i, btn in pairs(self.BtnDayTab) do
        local day = self.RegisterDay[i]
        -- 刷新红点 和 按钮锁定状态
        if XDataCenter.NewbieTaskManager.CheckUnlockPeriod(day) then
            if self.CurrentIndex ~= i then
                btn:SetButtonState(CS.UiButtonState.Normal)
            end
            btn:ShowReddot(XDataCenter.NewbieTaskManager.CheckRegisterDayRedPoint(day))
            -- 刷新任务Tag
            btn:ShowTag(XDataCenter.NewbieTaskManager.CheckTaskFinishByDay(day))
        else
            btn:SetButtonState(CS.UiButtonState.Disable)
            btn:ShowReddot(false)
            btn:ShowTag(false)
        end
    end
end

function XUiNewbieTaskMain:RefreshProgressTransform()
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

function XUiNewbieTaskMain:RefreshProgress()
    if self.PanelDaily.gameObject.activeSelf == false then
        return
    end
    -- 刷新进度奖励位置
    self:RefreshProgressTransform()

    local progressNumber = XDataCenter.NewbieTaskManager.GetCurrentTaskProgress()
    -- 当前进度值
    self.TxtCurProgress.text = progressNumber
    local currentProgress = progressNumber * 1.0 / self.MaxProgress * FULL_PROGRESS
    self.ImgProgress.fillAmount = (currentProgress > FULL_PROGRESS) and 1 or currentProgress

    for _, progress in pairs(self.TotalProgress) do
        progress:Open()
        progress:Refresh(progressNumber)
    end
end

-- 判断是否领取所有奖励 以及是否领取了荣誉奖励
function XUiNewbieTaskMain:CheckRewardReceiveStatus()
    if XDataCenter.NewbieTaskManager.CheckNewbieHonorReward() then
        -- 防止因为配置的condition不一致，导致重复触发卡死
        self._IsCloseInHonorRewardGot = true
        -- 刷新页签
        self.Parent:UpdateTabListShow()
    elseif XDataCenter.NewbieTaskManager.CheckTaskAllFinish() and XDataCenter.NewbieTaskManager.CheckProgressRewardAllReceive() then
        -- 开始展示荣誉奖励
        self:HideProgress()
        self.PanelDaily.gameObject:SetActiveEx(false)
        self.TabBtnGroup.transform.parent.gameObject:SetActiveEx(false)
        self.PlayerTaskSuccess.gameObject:SetActiveEx(true)
        self:PlayAnimation("PlayerTaskSuccessEnable")
    else
        -- 有未领取的奖励
        self.PlayerTaskSuccess.gameObject:SetActiveEx(false)
    end
end

function XUiNewbieTaskMain:CheckIsShowHonorReward()
    return XDataCenter.NewbieTaskManager.CheckTaskAllFinish() and XDataCenter.NewbieTaskManager.CheckProgressRewardAllReceive()
end

-- 检测是否播放页签动画
-- 条件是：领取完毕某个页签所有奖励
function XUiNewbieTaskMain:CheckTabAnimation()
    local isTaskFinish = XDataCenter.NewbieTaskManager.CheckTaskFinishByDay(self.CurrentDay)
    if isTaskFinish then

    end
end

return XUiNewbieTaskMain