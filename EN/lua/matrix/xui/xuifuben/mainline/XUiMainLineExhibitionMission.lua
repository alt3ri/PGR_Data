---@class XUiMainLineExhibitionMission:XLuaUi
---@field TaskStoryModule XUiPanelTaskStory
local XUiMainLineExhibitionMission = XLuaUiManager.Register(XLuaUi, "UiMainLineExhibitionMission")

function XUiMainLineExhibitionMission:OnAwake()
    self.PanelTaskStory.gameObject:SetActiveEx(false)
    self.PanelTreasure.gameObject:SetActiveEx(false)
    self.GridTreasureList = {}
    
    self:InitButtonGroup()
    self:RegisterUiEvents()
end

function XUiMainLineExhibitionMission:OnStart(chapterId)
    self.ChapterId = chapterId
    self.ChapterConfig = XFubenMainLineConfigs.GetChapterCfg(chapterId)

    ---@type XUiPanelTaskStory
    local XUiPanelTaskStory = require("XUi/XUiTask/XUiPanelTaskStory")
    self.TaskStoryModule = XUiPanelTaskStory.New(self.PanelTaskStory, self, chapterId)

    self:InitTaskStory()
    self:InitTreasure()
    if self.IsShowTaskStoryTab then
        self.PanelTab:SelectIndex(1)
    else
        self.PanelTab:SelectIndex(2)
    end
end

function XUiMainLineExhibitionMission:OnEnable()
    
end

function XUiMainLineExhibitionMission:OnDisable()
    
end

function XUiMainLineExhibitionMission:OnDestroy()
    
end

function XUiMainLineExhibitionMission:OnGetEvents()
    return {
        XEventId.EVENT_TASK_SYNC,
    }
end

--事件监听
function XUiMainLineExhibitionMission:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self.TaskStoryModule:Refresh()
    end
end

function XUiMainLineExhibitionMission:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiMainLineExhibitionMission:OnBtnBackClick()
    self:Close()
end

function XUiMainLineExhibitionMission:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMainLineExhibitionMission:InitButtonGroup()
    self.Buttons = {self.BtnTab1, self.BtnTab2}
    self.PanelTab:Init(self.Buttons, function(index) self:OnSelectBtnTab(index) end)
end

function XUiMainLineExhibitionMission:OnSelectBtnTab(index)
    if self.TabIndex and self.TabIndex ~= index then
        self:PlayAnimation("QieHuan")
    end
    self.TabIndex = index
    if index == 1 then
        self:CloseTreasure()
        self:OpenTaskStory()
    else
        self:CloseTaskStory()
        self:OpenTreasure()
    end
    self:RefreshRed()
end

-- 刷新红点
function XUiMainLineExhibitionMission:RefreshRed()
    if self.TabIndex == 1 then
        self.BtnTab1:ShowReddot(false)
        
        local isRed = self:IsTreasureRed()
        self.BtnTab2:ShowReddot(isRed)
    else
        local isRed = self:IsTaskStoryRed()
        self.BtnTab1:ShowReddot(isRed)
        self.BtnTab2:ShowReddot(false)
    end
end

--region 任务界面

function XUiMainLineExhibitionMission:InitTaskStory()
    local taskGroupId = XFubenMainLineConfigs.GetConfigChapterTaskGroupId(self.ChapterId)
    local tasks = XDataCenter.TaskManager.GetStoryTaskListByGroupId(taskGroupId)
    self.IsShowTaskStoryTab = #tasks > 0
    self.BtnTab1.gameObject:SetActiveEx(self.IsShowTaskStoryTab)
end

-- 打开任务
function XUiMainLineExhibitionMission:OpenTaskStory()
    self.TaskStoryModule:ShowPanel(false)
    self.TaskStoryModule:RefreshCourse()
end

-- 关闭任务
function XUiMainLineExhibitionMission:CloseTaskStory()
    self.TaskStoryModule:HidePanel()
end

function XUiMainLineExhibitionMission:IsTaskStoryRed()
    -- 主线任务奖励未领取蓝点
    local taskGroupId = XFubenMainLineConfigs.GetConfigChapterTaskGroupId(self.ChapterId)
    if XTool.IsNumberValidEx(taskGroupId) and XDataCenter.TaskManager.CheckStoryTaskCanGet(taskGroupId) then
        return true
    end
    -- 主线进度奖励未领取蓝点
    if XDataCenter.TaskManager.CheckChapterCourseCanGet(self.ChapterId) then
        return true
    end
    return false
end

--endregion

--region 挑战目标

function XUiMainLineExhibitionMission:InitTreasure()
    local targetList = self.ChapterConfig.TreasureId
    self.IsShowTreasureTab = #targetList > 0
    self.BtnTab2.gameObject:SetActiveEx(self.IsShowTreasureTab)
end

-- 打开挑战目标
function XUiMainLineExhibitionMission:OpenTreasure()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    local targetList = self.ChapterConfig.TreasureId
    if #targetList == 0 then return end

    -- 先把所有的格子隐藏
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end

    local gridTreasureGrade = self.PanelTreasure:GetObject("GridTreasureGrade")
    local panelGradeContent = self.PanelTreasure:GetObject("PanelGradeContent")
    gridTreasureGrade.gameObject:SetActiveEx(false)
    local XUiGridTreasureGrade = require("XUi/XUiFubenMainLineChapter/XUiGridTreasureGrade")
    for i = 1, #targetList do
        ---@type XUiGridTreasureGrade
        local grid = self.GridTreasureList[i]
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(gridTreasureGrade)  -- 复制一个item
            grid = XUiGridTreasureGrade.New(self, item)
            grid.Transform:SetParent(panelGradeContent, false)
            self.GridTreasureList[i] = grid
        end
        local treasureCfg = XDataCenter.FubenMainLineManager.GetTreasureCfg(targetList[i])
        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(self.ChapterId)
        grid:SetShowStarProgress()
        grid:UpdateGradeGrid(chapterInfo.Stars, treasureCfg, self.ChapterId)
        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

-- 关闭挑战目标
function XUiMainLineExhibitionMission:CloseTreasure()
    self.PanelTreasure.gameObject:SetActiveEx(false)
end

function XUiMainLineExhibitionMission:IsTreasureRed()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MAINLINE_TREASURE, self.ChapterId)
end
--endregion

return XUiMainLineExhibitionMission