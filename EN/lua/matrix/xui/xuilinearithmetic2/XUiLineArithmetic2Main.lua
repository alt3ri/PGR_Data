local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiLineArithmetic2MainChapterGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2MainChapterGrid")

---@class XUiLineArithmetic2Main : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2Main = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2Main")

function XUiLineArithmetic2Main:Ctor()
    self._Timer = false
    self._GridChapters = {}
    self._TimerReward = false
    self._DurationShowReward = 5 * XScheduleManager.SECOND
end

function XUiLineArithmetic2Main:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnClickTask)
    self:BindHelpBtn(self.BtnHelp, "LineArithmeticHelp")
end

function XUiLineArithmetic2Main:OnStart()
    self:UpdateReward()
end

function XUiLineArithmetic2Main:OnEnable()
    if not self:UpdateTime() then
        return
    end
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
    self:ShowReward()
    self:UpdateChapter()
    self:UpdateRoleAnimation()
    self:UpdateTask()

    if not self._TimerLock then
        if not self:CheckUnlockAll() then
            -- 固定时间刷新一次, 以解锁
            self._TimerLock = XScheduleManager.ScheduleForever(function()
                self:UpdateChapter()
                self:CheckUnlockAll()
            end, XScheduleManager.SECOND * 30)
        end
    end
end

function XUiLineArithmetic2Main:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    if self._TimerLock then
        XScheduleManager.UnSchedule(self._TimerLock)
        self._TimerLock = false
    end
    if self._TimerReward then
        XScheduleManager.UnSchedule(self._TimerReward)
        self._TimerReward = false
    end
end

function XUiLineArithmetic2Main:UpdateTime()
    if self._Control:UpdateTime() then
        local uiData = self._Control:GetUiData()
        self.TxtTime.text = uiData.Time
        return true
    end
    return false
end

function XUiLineArithmetic2Main:UpdateChapter()
    self._Control:UpdateChapter()
    local chapters = self._Control:GetUiData().Chapter
    for i = 1, #chapters do
        ---@type XUiLineArithmetic2MainChapterGrid
        local grid = self._GridChapters[i]
        if not grid then
            local ui = self["GridChapter" .. i]
            if not ui then
                XLog.Error("[XUiLineArithmetic2Main] 章节节点不够了， 加多个吧:", i)
                break
            end
            grid = XUiLineArithmetic2MainChapterGrid.New(ui, self)
            self._GridChapters[i] = grid
        end
        grid:Open()
        grid:Update(chapters[i])
    end
    for i = #chapters + 1, #self._GridChapters do
        local grid = self._GridChapters[i]
        grid:Close()
    end
end

function XUiLineArithmetic2Main:UpdateReward()
    self._Control:UpdateReward()
    local rewards = self._Control:GetUiData().RewardOnMainUi
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, #rewards, function(index, grid)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, grid)
        grid:Refresh(rewards[index])
        grid:SetName("")
    end)
end

function XUiLineArithmetic2Main:UpdateTask()
    local taskDatas = XMVCA.XLineArithmetic2:GetTaskList()
    local isShowRedDot = false
    for i = 1, #taskDatas do
        local taskData = taskDatas[i]
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            isShowRedDot = true
            break
        end
    end
    self.BtnReward:ShowReddot(isShowRedDot)
end

function XUiLineArithmetic2Main:OnClickTask()
    XLuaUiManager.Open("UiLineArithmetic2Task")
end

function XUiLineArithmetic2Main:ShowReward()
    self.PanelItem.gameObject:SetActiveEx(true)
    self._TimerReward = XScheduleManager.ScheduleOnce(function()
        self._TimerReward = false
        self.PanelItem.gameObject:SetActiveEx(false)
    end, self._DurationShowReward)
end

function XUiLineArithmetic2Main:CheckUnlockAll()
    local chapters = self._Control:GetUiData().Chapter
    local isUnlockAll = true
    for i = 1, #chapters do
        if not chapters[i].IsOpen then
            isUnlockAll = false
        end
    end
    if isUnlockAll then
        if self._TimerLock then
            XScheduleManager.UnSchedule(self._TimerLock)
            self._TimerLock = false
        end
    end
    return isUnlockAll
end

function XUiLineArithmetic2Main:UpdateRoleAnimation()
    local index = XSaveTool.GetData("LineArithmetic2RoleAnimation" .. XPlayer.Id) or 0
    
    local unlockChapters = self._Control:GetUiData().UnlockChapters
    index = index % #unlockChapters + 1
    --print("index:", index)
    
    XSaveTool.SaveData("LineArithmetic2RoleAnimation" .. XPlayer.Id, index)
    local chapterIndex = unlockChapters[index]
    for i = 1, 4 do
        local role = self["Role0" .. i]
        if role then
            role.gameObject:SetActiveEx(chapterIndex == i)
        end
    end
end

return XUiLineArithmetic2Main
