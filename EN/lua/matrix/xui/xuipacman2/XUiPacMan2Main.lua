local XUiPacMan2StageGrid = require("XUi/XUiPacMan2/XUiPacMan2StageGrid")

---@class XUiPacMan2Main : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2Main = XLuaUiManager.Register(XLuaUi, "UiPacMan2Main")

function XUiPacMan2Main:OnAwake()
    self:BindExitBtns()
    self.GridChapter.gameObject:SetActiveEx(false)
    self:BindHelpBtn(self.BtnHelp, "PacMan2Help")
    ---@type XUiPacMan2StageGrid[]
    self._GridStages = {}
    self._IsAnimation = true
    self._LastStageId = false
    self._IsAutoSelect = true
end

function XUiPacMan2Main:OnStart()
    -- 清除今日红点
    local redPoint = require("XRedPoint/XRedPointConditions/XPacMan2/XRedPointPacMan2")
    redPoint.ClearTodayRed()

    self:UpdateTime()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, 1000)
    end
end

function XUiPacMan2Main:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPacMan2Main:OnEnable()
    self:Update()
    self:PlayAnimationAndAutoSelect()
end

function XUiPacMan2Main:PlayAnimationTweenStage(selectedIndex)
    local beginIndex = 1

    if selectedIndex then
        if selectedIndex == #self._GridStages then
            beginIndex = selectedIndex - 2
        else
            beginIndex = selectedIndex - 1
        end
    end

    for i = beginIndex, #self._GridStages do
        local grid = self._GridStages[i]
        if grid then
            local timer
            timer = XScheduleManager.ScheduleOnce(function()
                grid:PlayAnimation("Enable")
                self:_RemoveTimerIdAndDoCallback(timer)
            end, 200 * (i - beginIndex + 1))
            self:_AddTimerId(timer)
        end
    end
end

function XUiPacMan2Main:Update()
    local dataArray = self._Control:GetStageList()
    local gridArray = self._GridStages
    local uiObject = self.GridChapter
    if #gridArray == 0 and uiObject then
        uiObject.gameObject:SetActiveEx(false)
    end
    local dataCount = dataArray and #dataArray or 0
    ---@type UnityEngine.RectTransform
    local content = self.Content
    for i = 1, dataCount do
        local grid = gridArray[i]
        if not grid then
            local uiChapter = content:Find("Chapter" .. i)
            if not uiChapter then
                XLog.Error("[XUiPacMan2Main] 关卡数量超出ui制作的节点上限, 请增加Chapter节点的数量")
                break
            end
            local ui = CS.UnityEngine.Object.Instantiate(uiObject, uiChapter)
            ui.transform.localPosition = Vector3.zero
            grid = XUiPacMan2StageGrid.New(ui, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = dataCount + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiPacMan2Main:UpdateTime()
    local timeId = self._Control:GetTimeId()

    if XMain.IsZlbDebug then
        if (not timeId) or (not XFunctionManager.CheckInTimeByTimeId(timeId)) then
            timeId = 36701
        end
    end

    if (not timeId) or (not XFunctionManager.CheckInTimeByTimeId(timeId)) then
        XUiManager.TipText("ActivityAlreadyOver")
        XLuaUiManager.SafeClose("UiPacMan2Game")
        XLuaUiManager.SafeClose("UiPacMan2PopupStageDetail")
        XLuaUiManager.SafeClose("UiPacMan2PopupSettlement")
        self:Close()
        return
    end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime - currentTime
    remainTime = math.max(1, remainTime)
    local str = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = str

    local isChange = false
    for i = 1, #self._GridStages do
        local grid = self._GridStages[i]
        isChange = grid:CheckInTime()
        if isChange then
            break
        end
    end
    if isChange then
        self:Update()
    else
        for i = 1, #self._GridStages do
            local grid = self._GridStages[i]
            grid:UpdateTime()
        end
    end
end

function XUiPacMan2Main:ScrollToChapter(index)
    if index <= 0 or index > #self._GridStages then
        XLog.Warning("[XUiPacMan2Main] 索引超出范围")
        return
    end

    local grid = self._GridStages[index]
    local chapterTransform = grid.Transform.parent

    local scrollRect = self.PanelChapter:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    local content = scrollRect.content

    -- 计算滚动位置
    local x = chapterTransform.localPosition.x
    local halfViewportWidth = scrollRect.viewport.rect.width / 2
    local offset = halfViewportWidth - x
    content.anchoredPosition = Vector2(offset, content.anchoredPosition.y)
end

function XUiPacMan2Main:PlayAnimationAndAutoSelect()
    local isAnimation = false
    local currentStageId = self._Control:GetCurrentStageId()
    if self._LastStageId ~= currentStageId then
        self._IsAutoSelect = true
        if self._LastStageId ~= false then
            isAnimation = true
        end
        self._LastStageId = currentStageId
    end

    if isAnimation then
        local index
        for i = 1, #self._GridStages do
            local grid = self._GridStages[i]
            if grid:GetStageId() == currentStageId then
                index = i
            end
        end
        --index = index - 1
        --XLog.Error("要播放的line是" .. index)
        if index then
            --为什么"-1"? 因为不存在line0，第一关没有line动画，所以通关2的时候，关卡已经到3了，此时应该亮的是line1，所以要减2
            local line = self["Line" .. index - 1]
            if line then
                local animationObj = line.transform:Find("Animation/LightEffectEnable")
                if animationObj then
                    animationObj:PlayTimelineAnimation()
                end
            else
                XLog.Warning("[XUiPacMan2Main] 找不到line:" .. index)
            end

            local grid = self._GridStages[index]
            grid:Tween(0.5, function()
                grid:PlayAnimation("Enable")
            end)

            local preGrid = self._GridStages[index - 1]
            if preGrid then
                preGrid:PlayAnimationStar()
            end
        end
    end

    -- 进入到主界面需要定位到当前未通关关卡
    local selectedIndex = 1
    if self._IsAutoSelect then
        self._IsAutoSelect = false
        local stageId = self._Control:GetCurrentStageId()
        if stageId then
            local index = 0
            for i = 1, #self._GridStages do
                local grid = self._GridStages[i]
                if grid:GetStageId() == stageId then
                    index = i
                end
            end
            if index > 0 then
                selectedIndex = index
                -- 滚动到第几关
                self:ScrollToChapter(index)
            end
        else
            --全通关定位到最后一关
            local index = #self._GridStages
            if index > 0 then
                selectedIndex = index
            end
            self:ScrollToChapter(index)
        end
    end

    if self._IsAnimation then
        self:PlayAnimationTweenStage(selectedIndex)
        self._IsAnimation = false
    end
end

return XUiPacMan2Main