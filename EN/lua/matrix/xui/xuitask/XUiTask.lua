local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelTaskDaily = require("XUi/XUiTask/XUiPanelTaskDaily")
local XUiPanelTaskActivity = require("XUi/XUiTask/XUiPanelTaskActivity")
local XUiPanelTaskWeekly = require("XUi/XUiTask/XUiPanelTaskWeekly")
local XUiPanelTaskCanLiver = require("XUi/XUiTask/XUiPanelTaskCanLiver")
local XUiNewbieTaskMain = require('XUi/XUiTask/XUiNewbieTask/XUiNewbieTaskMain')
local XUiNewPlayerTask = require('XUi/XUiTask/XUiNewPlayerTask/XUiNewPlayerTask')
---@class XUiTask:XLuaUi
local XUiTask = XLuaUiManager.Register(XLuaUi, "UiTask")
local MaintainerActionIcon = CS.XGame.ClientConfig:GetString("MaintainerActionIconInTaskUI")

-- 页签类型，用于确定每个页签打开什么界面
-- 一般每个页签独立，不会复用，主要是Id涉及排序和页签折叠关系，因此用type来关联逻辑
local TabType = {
    Daily = 1, -- 每日任务
    Weekly = 2, -- 每周任务
    Activity = 3, -- 活动任务
    NewbieStart = 4, -- 新手入门任务
    NewbieTarget = 5, -- 新手目标任务
    CanLiver = 6, -- 新手目标任务
}

local ShowTypeInHideFunc = {
    None = 0,
    AlwaysShow = 1,
    AlwaysHide = 2,
}

function XUiTask:OnAwake()
    self:InitBtnSound()
end

function XUiTask:OnStart(skipIndex)
    local lastSelectTab = XDataCenter.TaskManager.GetNewPlayerHint(XDataCenter.TaskManager.TaskLastSelectTab, 1)
    self.SkipIndex = skipIndex -- 这个是tabCfg的顺序下标 不是动态的btnList数量下标
    self.CurTabIndex = lastSelectTab

    if self.CurTabIndex == nil then
        self.CurTabIndex = 1
    end

    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_TAB_CHANGE, self.OnTaskChangeTab, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)

    self:Init()
    -- self.IsStartAnimation = true
end

function XUiTask:OnEnable()
    self:UpdateTabListShow()
    self:SetupBountyTask()
    self:PlayAnimation("AnimStartEnable")
end

function XUiTask:Init()

    ---@type XUiPanelAsset
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end

    
    self.BtnMoneyReward.CallBack = function() self:OnBtnMoneyRewardClick() end

    self.PanelNewbieTask.gameObject:SetActiveEx(false)
    self.PanelTargetTask.gameObject:SetActiveEx(false)
    
    ---@type XUiPanelTaskDaily
    self.TaskDailyModule = XUiPanelTaskDaily.New(self.PanelTaskDaily, self)
    ---@type XUiPanelTaskWeekly
    self.TaskWeeklyModule = XUiPanelTaskWeekly.New(self.PanelTaskWeekly, self)
    ---@type XUiPanelTaskActivity
    self.TaskActivityModule = XUiPanelTaskActivity.New(self.PanelTaskActivity, self)
    ---@type XUiNewbieTaskMain
    self.TaskNewbieModule = XUiNewbieTaskMain.New(self.PanelNewbieTask, self, self)
    ---@type XUiNewPlayerTaskNew
    self.TaskNewPlayerTarget = XUiNewPlayerTask.New(self.PanelTargetTask, self, self)
    ---@type XUiPanelTaskCanLiver
    self.TaskCanLiver = XUiPanelTaskCanLiver.New(self.PanelTaskDrawCanLiver, self, self)

    self:InitTabList()

end

function XUiTask:InitTabList()
    self.TabReddotIds = {}

    self.TabSortedCfgs = XTaskConfig.GetMainTaskTabControlTemplateSortList()
    -- 遍历并构建父子关系映射
    self._TabSubDict = {}
    self._SubTab2FirstTabDict = {}

    for i, v in ipairs(self.TabSortedCfgs) do
        local subIndex = math.fmod(v.Id, 100)

        if XTool.IsNumberValidEx(subIndex) then
            local parentId = v.Id - subIndex

            local map = self._TabSubDict[parentId] or {}

            map[v.Id] = true
            
            self._TabSubDict[parentId] = map
            self._SubTab2FirstTabDict[v.Id] = parentId
        end
    end
    
    -- 初始化页签实体映射字典
    ---@type table<number, XUiComponent.XUiButton>
    self._TabGridDict = {}
    
    -- 初始化页签实时索引对应配置的映射字典
    ---@type table<number, XTableMainTaskTabControl>
    self._TabIndex2Cfg = {}
    self._CfgIndex2TabIndex = {}

    --- 记录各个页签的解锁状态，用于辅助红点显示
    ---@type table<number, boolean>
    self._TabId2UnlockState = {}
    
    --- 记录各个页签的红点显示状态，用于二级页签红点穿透到一级页签
    ---@type table<number, boolean>
    self._TabId2ReddotShowState = {}
end

--- 实例化页签UI节点
---@param cfg XTableMainTaskTabControl
function XUiTask:InitTabByCfg(cfg, isParent, subIndex, curFirstTabCount)
    -- 如果没有实例化，先判断它的显示是否满足条件
    local isCanShow = true
    
    if XTool.IsNumberValidEx(cfg.ShowCondition) and not XConditionManager.CheckCondition(cfg.ShowCondition) then
        isCanShow = false
    elseif XTool.IsNumberValidEx(cfg.FunctionId) and XFunctionManager.CheckFunctionFitter(cfg.FunctionId) then
        isCanShow = false    
    end
    
    -- 判断提审模式下的特殊处理
    if XUiManager.IsHideFunc then
        if cfg.ShowTypeInHideFunc == ShowTypeInHideFunc.AlwaysShow then
            isCanShow = true
        elseif cfg.ShowTypeInHideFunc == ShowTypeInHideFunc.AlwaysHide then
            isCanShow = false    
        end
    end

    if not isCanShow then
        return
    end

    -- 如果要显示，根据它的类型克隆对应的预制体
    ---@type UnityEngine.GameObject
    local go = nil

    if isParent then
        -- 一级页签，判断其下是否有二级页签
        if XTool.IsTableEmpty(self._TabSubDict[cfg.Id]) then
            go = CS.UnityEngine.Object.Instantiate(self.BtnFirst, self.BtnContent.transform)
        else
            go = CS.UnityEngine.Object.Instantiate(self.BtnFirstHasSnd, self.BtnContent.transform)
        end
    else
        -- 二级页签，需要判断自己是第一个还是最后一个
        local parentId = cfg.Id - subIndex
        local subCount = XTool.GetTableCount(self._TabSubDict[parentId])

        if subCount == 1 then
            -- 只有一个二级页签
            go = CS.UnityEngine.Object.Instantiate(self.BtnSecondAll, self.BtnContent.transform)
        elseif subIndex == 1 then
            -- 二级页签中的第一个
            go = CS.UnityEngine.Object.Instantiate(self.BtnSecondTop, self.BtnContent.transform)
        elseif subIndex == subCount then
            -- 二级页签中的最后一个
            go = CS.UnityEngine.Object.Instantiate(self.BtnSecondBottom, self.BtnContent.transform)
        else
            -- 二级页签夹在中间的位置
            go = CS.UnityEngine.Object.Instantiate(self.BtnSecond, self.BtnContent.transform)
        end
    end

    go.gameObject:SetActiveEx(true)
    go.transform:SetAsLastSibling()

    local uiButton = go:GetComponent("XUiButton")
    -- 因为一级页签和二级页签是相邻的，所以二级页签所属一级索引，直接等于当前累计出现的一级页签
    if not isParent then
        uiButton.SubGroupIndex = curFirstTabCount
    end
    uiButton:SetName(cfg.TagName)

    self._TabGridDict[cfg.Id] = uiButton
    go.name = cfg.Id
    
    -- 刷新锁定状态
    self:_CheckTogLockStatus(uiButton, cfg)
    
    -- 注册红点事件
    if not XTool.IsTableEmpty(cfg.RedPointConditions) then
        local reddotId = self:AddRedPointEvent(uiButton, function(count)
            local isShowReddot = count >= 0

            if not self._TabId2UnlockState[cfg.Id] then
                isShowReddot = false
            end
            
            self._TabId2ReddotShowState[cfg.Id] = isShowReddot
            
            -- 刷新自己的显示
            self:_CheckTabRealReddotShow(cfg.Id)
            
            -- 如果是子页签，则需要刷新父页签的红点显示
            if not isParent then
                local parentTabId = self._SubTab2FirstTabDict[cfg.Id]

                if XTool.IsNumberValidEx(parentTabId) then
                    self:_CheckTabRealReddotShow(parentTabId)
                end
            end
        end, nil, cfg.RedPointConditions, table.unpack(cfg.RedPointArgs))

        self.TabReddotIds[cfg.Id] = reddotId
    end

    return uiButton
end

function XUiTask:UpdateTabListShow()
    local firstTabCount = 0
    
    local buttonList = {}
    
    -- 根据父子映射选择克隆对应的页签预制
    for i, v in ipairs(self.TabSortedCfgs) do
        local subIndex = math.fmod(v.Id, 100)
        local isParent = subIndex == 0
        
        -- 先判断是否已经实例化页签了
        local btn = self._TabGridDict[v.Id]

        if btn then
            -- 如果已经实例化了，那么根据条件判断它是否显示
            local isShow = false

            if XTool.IsNumberValidEx(v.FunctionId) and XFunctionManager.CheckFunctionFitter(v.FunctionId) then
                isShow = false
            elseif not XTool.IsNumberValidEx(v.ShowCondition) or XConditionManager.CheckCondition(v.ShowCondition) then
                isShow = true
            end

            -- 判断提审模式下的特殊处理
            if XUiManager.IsHideFunc then
                if v.ShowTypeInHideFunc == ShowTypeInHideFunc.AlwaysShow then
                    isShow = true
                elseif v.ShowTypeInHideFunc == ShowTypeInHideFunc.AlwaysHide then
                    isShow = false
                end
            end

            if isShow then
                btn.gameObject:SetActiveEx(true)
                btn.transform:SetAsLastSibling()

                if isParent then
                    btn.IsFold = false
                    firstTabCount = firstTabCount + 1
                else
                    btn.SubGroupIndex = firstTabCount
                end

                table.insert(buttonList, btn)
                self._TabIndex2Cfg[#buttonList] = v
                self._CfgIndex2TabIndex[i] = #buttonList
            else
                btn.gameObject:SetActiveEx(false)

                if not isParent then
                    btn.SubGroupIndex = -1
                end
            end
        else
            local uiButton = self:InitTabByCfg(v, isParent, subIndex, firstTabCount)

            if uiButton then
                if isParent then
                    firstTabCount = firstTabCount + 1
                end
                table.insert(buttonList, uiButton)
                self._TabIndex2Cfg[#buttonList] = v
                self._CfgIndex2TabIndex[i] = #buttonList
            end
        end
    end
    
    self.TabList = buttonList

    -- 初始化选项组
    self.BtnContent:Init(buttonList, function(index) self:OnTaskPanelSelect(index) end)
    
    -- 刷新节点锁定状态
    local firstEnableIndex = self:CheckTogLockStatus()
    
    -- 修正当前选中页签
    if self.SkipIndex and self._CfgIndex2TabIndex[self.SkipIndex] then
        self.CurTabIndex = self._CfgIndex2TabIndex[self.SkipIndex]
    end
    self.CurTabIndex = math.min(#buttonList, self.CurTabIndex)
    
    local cfg = self._TabIndex2Cfg[self.CurTabIndex]
    
    if cfg and not self:_CheckTogLockStatus(nil, cfg) then
        self.CurTabIndex = firstEnableIndex 
    end
    
    -- 重新选中
    self.PreToggleType = nil
    self.BtnContent:SelectIndex(math.min(#buttonList, self.CurTabIndex))
end

function XUiTask:CheckTogLockStatus()
    local firstEnableIndex = nil
    
    if not XTool.IsTableEmpty(self.TabList) then
        for i, v in pairs(self.TabList) do
            local cfg = self._TabIndex2Cfg[i]
            
            local isEnable = self:_CheckTogLockStatus(v, cfg)

            if isEnable and not firstEnableIndex then
                firstEnableIndex = i
            end
        end
    end
    
    return firstEnableIndex or 1
end

function XUiTask:_CheckTogLockStatus(btn, cfg)
    local btnStatus = CS.UiButtonState.Normal

    if cfg then
        if XTool.IsNumberValidEx(cfg.FunctionId) then
            btnStatus = XFunctionManager.JudgeCanOpen(cfg.FunctionId) and CS.UiButtonState.Normal or CS.UiButtonState.Disable
        elseif XTool.IsNumberValidEx(cfg.UnlockCondition) then
            btnStatus = XConditionManager.CheckCondition(cfg.UnlockCondition) and CS.UiButtonState.Normal or CS.UiButtonState.Disable
        end

        -- 判断提审模式下的特殊处理
        if XUiManager.IsHideFunc then
            if cfg.ShowTypeInHideFunc == ShowTypeInHideFunc.AlwaysShow then
                -- 提审模式下不能有锁定状态，所以强制显示则强制解锁
                btnStatus = CS.UiButtonState.Normal
            end
        end

        self._TabId2UnlockState[cfg.Id] = btnStatus ~= CS.UiButtonState.Disable
    end

    if btn then
        btn:SetButtonState(btnStatus)
    end
    
    return btnStatus ~= CS.UiButtonState.Disable
end

function XUiTask:OnTaskChangeSync(isMulti)
    -- 把索引转换为对应的配置
    local cfg = self._TabIndex2Cfg[self.CurTabIndex]

    if cfg then
        if cfg.TagType == TabType.Daily then
            self.TaskDailyModule:Refresh(isMulti)
        elseif cfg.TagType == TabType.Weekly then
            self.TaskWeeklyModule:Refresh(isMulti)
        elseif cfg.TagType == TabType.Activity then
            self.TaskActivityModule:Refresh(isMulti)
        elseif cfg.TagType == TabType.NewbieStart then
            if self.TaskNewbieModule:IsNodeShow() then
                self.TaskNewbieModule:Refresh()
            end
        elseif cfg.TagType == TabType.NewbieTarget then
            if self.TaskNewPlayerTarget:IsNodeShow() then
                self.TaskNewPlayerTarget:Refresh()
            end
        elseif cfg.TagType == TabType.CanLiver then
            if self.TaskCanLiver:IsNodeShow() then
                self.TaskCanLiver:Refresh(isMulti)
            end
        else
            XLog.Error('未知的页签类型：'..tostring(cfg.TagType))
        end
    else
        XLog.Error('对应索引不存在配置：'..tostring(self.CurTabIndex))
    end
end

--赏金
function XUiTask:SetupBountyTask()
    self.BtnMoneyRewardImage:SetSprite(MaintainerActionIcon)
    local IsOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.MaintainerAction) and
    XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.MaintainerAction) and
    not XUiManager.IsHideFunc
    self.BtnMoneyReward.gameObject:SetActiveEx(IsOpen)
    self.ImgCompleted.gameObject:SetActiveEx(false)
    local IsStart = XDataCenter.MaintainerActionManager.IsStart()
    local IsShowRed = false
    if IsStart then
        local IsActionPointOver = XDataCenter.MaintainerActionManager.CheckIsActionPointOver()
        local IsAllComplete = XDataCenter.MaintainerActionManager.CheckIsAllComplete()
        IsShowRed = not IsAllComplete and not IsActionPointOver
    end
    self.ImgRedTag.gameObject:SetActiveEx(IsShowRed)
end

function XUiTask:OnDisable()
    self.PreToggleType = nil
    self.TaskDailyModule:HidePanel()
    self.TaskWeeklyModule:HidePanel()
end

function XUiTask:OnDestroy()
    if self.TaskDailyModule then
        self.TaskDailyModule:OnDestroy()
    end
    XDataCenter.TaskManager.UpdateViewCallback = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_TAB_CHANGE, self.OnTaskChangeTab, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
    self.TaskDailyModule:StopSchedule()
end

function XUiTask:CheckDailyTask()
    local cfg = self:GetCfgByType(TabType.Daily)

    if cfg then
        if self.TabReddotIds and self.TabReddotIds[cfg.Id] then
            -- 主界面任务红点检查
            XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)

            -- 任务界面红点检查
            XRedPointManager.Check(self.TabReddotIds[cfg.Id], XDataCenter.TaskManager.TaskType.Daily)
        end
    end
end

--- 根据二级页签刷新一级页签的红点
function XUiTask:_CheckTabRealReddotShow(tabId)
    local button = self._TabGridDict[tabId]

    if button then
        -- 先判断自己是否有红点
        if self._TabId2ReddotShowState[tabId] then
            button:ShowReddot(true)
            return
        end
        
        -- 判断自己是否有子页签
        local map = self._TabSubDict[tabId]

        if not XTool.IsTableEmpty(map) then
            -- 如果子页签任意有红点，则自己有红点
            for subTabId, v in pairs(map) do
                if self._TabId2ReddotShowState[subTabId] then
                    button:ShowReddot(true)
                    return
                end
            end
        end
        
        -- 否则没有红点
        button:ShowReddot(false)
    end
end

--日常标签红点
function XUiTask:RefreshDailyTabRedDot(count)
    local isShow = count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.TaskDay)
    self.ImgDailyNewTag.gameObject:SetActive(isShow)
end

-- 每周标签红点
function XUiTask:RefreshWeeklyTabRedDot(count)
    local isShow = count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.TaskWeekly)
    self.ImgWeeklyNewTag.gameObject:SetActive(isShow)
end

--活动标签红点
function XUiTask:RefreshActivityTabRedDot(count)
    self.ImgActivetyNewTag.gameObject:SetActive(count >= 0)
end

function XUiTask:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiTask:OnBtnMoneyRewardClick()
    XDataCenter.MaintainerActionManager.OnOpenMaintainerAction()
end

function XUiTask:InitBtnSound()
    self.SpecialSoundMap = {}
    self.SpecialSoundMap[self:GetAutoKey(self.BtnBack, "onClick")] = XLuaAudioManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnMainUi, "onClick")] = XLuaAudioManager.UiBasicsMusic.Return
end

function XUiTask:OnTaskChangeTab(skipIndex)
    local targetTabIndex = self._CfgIndex2TabIndex[skipIndex] or skipIndex

    -- 越界修正：保持和生成标签时一致
    local maxIndex = #self.TabList
    local fixedIndex = math.min(maxIndex, math.max(1, targetTabIndex))

    -- 触发选择
    self.BtnContent:SelectIndex(fixedIndex)
end

function XUiTask:OnTaskPanelSelect(index)
    if self.PreToggleType == index then
        return
    end

    if self.IsFirstAnimation == nil then
        self.IsFirstAnimation = true
    else
        self.IsFirstAnimation = false
    end

    local cfg = self._TabIndex2Cfg[index]

    if not cfg then
        XLog.Error('对应索引不存在配置：'..tostring(index))
        return
    end
    
    local isForceOpen = false

    -- 判断提审模式下的特殊处理
    if XUiManager.IsHideFunc then
        if cfg.ShowTypeInHideFunc == ShowTypeInHideFunc.AlwaysShow then
            -- 提审模式下不能有锁定状态，所以强制显示则强制解锁
            isForceOpen = true
        end
    end

    if not isForceOpen then
        if XTool.IsNumberValidEx(cfg.UnlockCondition) and not XConditionManager.CheckCondition(cfg.UnlockCondition) then
            XUiManager.TipMsg(XConditionManager.GetConditionDescById(cfg.UnlockCondition))
            return
        end

        if XTool.IsNumberValidEx(cfg.FunctionId) and not XFunctionManager.DetectionFunction(cfg.FunctionId) then
            return
        end
    end

    self.PreToggleType = index
    self.CurTabIndex = index

    -- 先隐藏所有面板
    self.TaskDailyModule:HidePanel()
    self.TaskWeeklyModule:HidePanel()
    self.TaskActivityModule:HidePanel()
    self.TaskNewbieModule:Close()
    self.TaskNewPlayerTarget:Close()
    self.TaskCanLiver:Close()

    if cfg.TagType == TabType.Daily then
        if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskDay) then
            self.TaskDailyModule:HidePanel()
            return
        end

        if not isForceOpen and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TaskDay) then
            return
        end

        self.TaskDailyModule:ShowPanel(self.IsFirstAnimation)

        self:PlayAnimation("TaskDailyQieHuan", function()
            self.TaskDailyModule:UpdateActiveness()
        end)

    elseif cfg.TagType == TabType.Weekly then
        if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskWeekly) then
            self.TaskWeeklyModule:HidePanel()
            return
        end

        if not isForceOpen and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TaskWeekly) then
            return
        end

        self.TaskWeeklyModule:ShowPanel()
        self:PlayAnimation("TaskWeeklyQieHuan")

    elseif cfg.TagType == TabType.Activity then
        if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskActivity) then
            self.TaskActivityModule:HidePanel()
            return
        end

        if not isForceOpen and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TaskActivity) then
            return
        end

        self.TaskActivityModule:ShowPanel()
        self:PlayAnimation("TaskActivityQieHuan")
    elseif cfg.TagType == TabType.NewbieStart then
        if XFunctionManager.CheckFunctionFitter(cfg.FunctionId) then
            self.TaskNewbieModule:Close()
            return
        end

        if not isForceOpen and not XFunctionManager.DetectionFunction(cfg.FunctionId) then
            return
        end

        self.TaskNewbieModule:Open()
    elseif cfg.TagType == TabType.NewbieTarget then
        if XFunctionManager.CheckFunctionFitter(cfg.FunctionId) then
            self.TaskNewPlayerTarget:Close()
            return
        end

        if not isForceOpen and not XFunctionManager.DetectionFunction(cfg.FunctionId) then
            return
        end

        self.TaskNewPlayerTarget:Open()
    elseif cfg.TagType == TabType.CanLiver then
        if XFunctionManager.CheckFunctionFitter(cfg.FunctionId) then
            self.TaskCanLiver:Close()
            return
        end

        if not isForceOpen and not XFunctionManager.DetectionFunction(cfg.FunctionId) then
            return
        end

        self.TaskCanLiver:Open()
    end

    XDataCenter.TaskManager.SaveNewPlayerHint(XDataCenter.TaskManager.TaskLastSelectTab, index)
end

function XUiTask:GetCfgByType(type)
    for i, v in pairs(self.TabSortedCfgs) do
        if v.TagType == type then
            return v
        end
    end
end
