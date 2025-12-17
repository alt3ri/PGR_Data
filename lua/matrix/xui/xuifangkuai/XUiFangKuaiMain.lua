local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiFangKuaiMain : XLuaUi 大方块主界面
---@field _Control XFangKuaiControl
local XUiFangKuaiMain = XLuaUiManager.Register(XLuaUi, "UiFangKuaiMain")

function XUiFangKuaiMain:OnAwake()
    ---@type XUiGridFangKuaiChapter[]
    self._Grids = {}
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpId())

    self._GridChapterSelect1 = self.Transform:Find("Animation/GridChapterSelect1")
    self._GridChapterSelect2 = self.Transform:Find("Animation/GridChapterSelect2")
    self._GridChapterSelect3 = self.Transform:Find("Animation/GridChapterSelect3")
    self._GridChapterSelect1Disable = self.Transform:Find("Animation/GridChapterSelect1Disable")
    self._GridChapterSelect2Disable = self.Transform:Find("Animation/GridChapterSelect2Disable")
    self._GridChapterSelect3Disable = self.Transform:Find("Animation/GridChapterSelect3Disable")
end

function XUiFangKuaiMain:OnStart()
    self._IsNormal = true
    self:PlayAnimationWithMask("AnimationStart") -- 播动效时屏蔽点击
    self:InitCompnent()

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:CountDown()
        end
    end, nil, 0)

    local rewards = self._Control:GetBubbleReward()
    XUiHelper.RefreshCustomizedList(self.PanelItem, self.Grid256New, #rewards, function(index, go)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(rewards[index])
        grid:SetName("")
    end, true)
end

function XUiFangKuaiMain:OnEnable()
    self.Super.OnEnable(self)
    self:PlayAnimationWithMask("AnimationEnable")
    self:UpdateTask()
    self:UpdateChapter()
    self:UpdatePlayingAnimation()
end

function XUiFangKuaiMain:OnDestroy()
    self:StopCountDown()
    self:StopBubbleTimer()
end

function XUiFangKuaiMain:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiFangKuaiMain:UpdateTask()
    if self._Control:IsAllTaskFinish() then
        self.PanelItem.gameObject:SetActiveEx(false)
        self.BtnTask:ShowReddot(false)
        return
    end
    
    local keepTime = self._Control:GetBubbleKeepTime()
    self.PanelItem.gameObject:SetActiveEx(true)

    self:StopBubbleTimer()
    self._BubbleTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelItem.gameObject:SetActiveEx(false)
    end, keepTime)

    local isRed = self._Control:CheckTaskRedPoint()
    self.BtnTask:ShowReddot(isRed)
end

function XUiFangKuaiMain:StopBubbleTimer()
    if self._BubbleTimer then
        XScheduleManager.UnSchedule(self._BubbleTimer)
        self._BubbleTimer = nil
    end
end

function XUiFangKuaiMain:UpdateChapter()
    local i = 1
    local activity = self._Control:GetActivityConfig()
    for _, chapterId in pairs(activity.ChapterIds) do
        local grid = self._Grids[i]
        if not grid then
            local chapter = self._Control:GetChapterConfig(chapterId)
            grid = require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiChapter").New(self["GridChapter" .. i], self, chapter)
            self._Grids[i] = grid
        end
        grid:Update()
        i = i + 1
    end

    --if self._CurStageAnimation then
    --    self:StopAnimation(self._CurStageAnimation)
    --    self._CurStageAnimation = nil
    --end
    --if playingStage then
    --    if isPlayingStageNormal then
    --        self._CurStageAnimation = string.format("GridChapterNormal%sLoop", playingStageIndex)
    --    else
    --        self._CurStageAnimation = string.format("GridChapterHard%sLoop", playingStageIndex)
    --    end
    --    self:PlayAnimation(self._CurStageAnimation, nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    --end
end

function XUiFangKuaiMain:UpdatePlayingAnimation()
    for i, v in ipairs(self._Grids) do
        local enableAnim = self[string.format("_GridChapterSelect%s", i)]
        local disableAnim = self[string.format("_GridChapterSelect%sDisable", i)]
        if not XTool.UObjIsNil(enableAnim) and not XTool.UObjIsNil(disableAnim) then
            if v:IsPlaying() then
                enableAnim:PlayTimelineAnimation()
                disableAnim:StopTimelineAnimation()
            else
                enableAnim:StopTimelineAnimation()
                disableAnim:PlayTimelineAnimation()
            end
        end
    end
end

function XUiFangKuaiMain:OnClickTask()
    XLuaUiManager.Open("UiFangKuaiTask")
end

function XUiFangKuaiMain:CountDown()
    local time = self._Control:GetActivityRemainder()
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiFangKuaiMain:StopCountDown()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

return XUiFangKuaiMain