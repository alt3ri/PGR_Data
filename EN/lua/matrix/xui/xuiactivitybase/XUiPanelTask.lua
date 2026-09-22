local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local BtnGoRedPointConditions = {
    [XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_Qu] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_LuNa] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.ChrismasTree_Dress] = { XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE },
    [XActivityConfigs.TaskPanelSkipType.Couplet_Game] = { XRedPointConditions.Types.CONDITION_COUPLET_GAME },
    [XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_SP] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.InvertCard_Game] = { XRedPointConditions.Types.CONDITION_INVERTCARDGAME_RED },
    [XActivityConfigs.TaskPanelSkipType.LivWarmPop_Game] = { XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY},
    [XActivityConfigs.TaskPanelSkipType.DiceGame] = {XRedPointConditions.Types.CONDITION_DICEGAME_RED},
    [XActivityConfigs.TaskPanelSkipType.BodyCombineGame] = {XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_MAIN},
    [XActivityConfigs.TaskPanelSkipType.InvertCardGame2] = {XRedPointConditions.Types.CONDITION_INVERTCARDGAME_RED},
}

---@class XUiPanelTask:XUiNode
local XUiPanelTask = XClass(XUiNode, "XUiPanelTask")

function XUiPanelTask:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskActivityList)
    self.DynamicTable:SetProxy(require("XUi/XUiActivityBase/XUiDynamicDailyTask"), self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelTask:OnDisable()
    self:RemoveTimer()
end

function XUiPanelTask:OnDestroy()
    self:RemoveTimer()
    self:RemoveRedPoint()
end

function XUiPanelTask:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelTask:RemoveRedPoint()
    if XTool.IsTableEmpty(self.BtnGoRedPointIdDic) then
        return
    end
    for _, redId in pairs(self.BtnGoRedPointIdDic) do
        XRedPointManager.RemoveRedPointEvent(redId)
    end
end

---@param activityCfg XTableActivity
function XUiPanelTask:Refresh(activityCfg)
    if not activityCfg then return end
    self.ActivityCfg = activityCfg
    self.TxtContentTimeTask.text = self:GetTxtContentTimeTask(activityCfg)
    self.TxtContentTitleTask.text = activityCfg.ActivityTitle
    self.TxtContentTask.text = XUiHelper.ConvertLineBreakSymbol(activityCfg.ActivityDes)

    local skipId = activityCfg.Params[1]
    if skipId and skipId ~= 0 then
        self.BtnGo.gameObject:SetActiveEx(true)
        CsXUiHelper.RegisterClickEvent(self.BtnGo, function()
            if XFunctionManager.CheckSkipInDuration(skipId) then
                if not XMVCA.XSubPackage:CheckSubpackage() then
                    return
                end
                XFunctionManager.SkipInterface(skipId)
            else
                XUiManager.TipText("ActivityBaseTaskSkipNotInDuring")
            end
        end)
        if not self.BtnGoRedPointIdDic then self.BtnGoRedPointIdDic = {} end
        if self.BtnGoRedPointIdDic[skipId] then
            XRedPointManager.Check(self.BtnGoRedPointIdDic[skipId])
        else
            if BtnGoRedPointConditions[skipId] and XFunctionManager.IsCanSkip(skipId) then
                self.BtnGoRedPointIdDic[skipId] = XRedPointManager.AddRedPointEvent(self.BtnGo, self.OnRedPointEvent, self, BtnGoRedPointConditions[skipId], nil, true)
            else
                self.BtnGo:ShowReddot(false)
            end
        end
    else
        self.BtnGo.gameObject:SetActiveEx(false)
    end

    self:UpdateDynamicTable()
    self:UpdateTimer()
end

function XUiPanelTask:UpdateTimer()
    self:RemoveTimer()
    self.Timer = XScheduleManager.ScheduleForeverEx(function()
        self:UpdateMultiReward()
        ---@type XUiDynamicDailyTask[]
        local grids = self.DynamicTable:GetGrids()
        for _, grid in pairs(grids) do
            if grid:GetTaskState() ~= XDataCenter.TaskManager.TaskState.Finish then
                grid:UpdateTimes()
                grid:UpdateMultiReward()
            end
        end
    end, XScheduleManager.SECOND)
end

function XUiPanelTask:UpdateMultiReward()
    self.Tag.gameObject:SetActiveEx(false)

    local isMultiRewardOpen = XDataCenter.FubenRepeatChallengeManager.IsMultiRewardOpen()
    if isMultiRewardOpen then
        local multiRewardCfg = XDataCenter.FubenRepeatChallengeManager.GetMultiRewardActivityCfg()
        if self.TaskIdDict and self.TaskIdDict[multiRewardCfg.TaskId] then
            local countStr = XTool.ConvertChineseNumberString(multiRewardCfg.Multiple)
            self.Tag.gameObject:SetActiveEx(true)
            self.TxtTag.text = XUiHelper.GetText("ActivityRepeatChallengeMultiRewardTag1", countStr)
            return
        end
    end
end

function XUiPanelTask:GetTxtContentTimeTask(activityCfg)
    local taskGroupId = 0
    local beginTime = 0
    local endTime = 0
    
    for index, id in ipairs(activityCfg.Params) do
        if index ~= 1 then -- 参数1为跳转ID
            if XTaskConfig.IsTimeLimitTaskInTime(id) then
                taskGroupId = id
            end
            local tmpBeginTime, tmpEndTime = XTaskConfig.GetTimeLimitTaskTime(taskGroupId)
            if beginTime == 0 or tmpBeginTime < beginTime then
                beginTime = tmpBeginTime
            end
            if endTime == 0 or tmpBeginTime > endTime then
                tmpEndTime = endTime
            end
        end
    end

    if taskGroupId ~= 0 then
        beginTime, endTime = XTaskConfig.GetTimeLimitTaskTime(taskGroupId)
    else
        beginTime, endTime = XTaskConfig.GetTimeLimitTaskTime(activityCfg.Params[2])
    end
    
    return XActivityConfigs.GetActivityTimeStr(activityCfg.Id, beginTime, endTime)
end

function XUiPanelTask:UpdateDynamicTable()
    self.TaskDatas = XDataCenter.ActivityManager.GetActivityTaskData(self.ActivityCfg.Id)
    self.TaskIdDict = {}
    for _, taskData in pairs(self.TaskDatas) do
        self.TaskIdDict[taskData.Id] = true
    end
    self.ImgEmpty.gameObject:SetActive(#self.TaskDatas <= 0)
    self.DynamicTable:SetDataSource(self.TaskDatas)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self.Parent
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskDatas[index]
        grid:ResetData(data)
        grid:UpdateMultiReward()
    end
end

function XUiPanelTask:OnRedPointEvent(count)
    self.BtnGo:ShowReddot(count >= 0)
end

function XUiPanelTask:UpdateTask()
    self:UpdateDynamicTable()
end

return XUiPanelTask