---@class XUiSoloReformMain: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformMain = XLuaUiManager.Register(XLuaUi, 'UiSoloReformMain')
local XUiSoloReformChapterItem = require("XUi/XUiSoloReform/XUiSoloReformMain/XUiSoloReformChapterItem")
-- local XUiSoloReformChapterKillItem = require("XUi/XUiSoloReform/XUiSoloReformMain/XUiSoloReformChapterKillItem")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiSoloReformMain:OnAwake()
    self._ChapterCellList = {}
    self._TimerId = nil
    self:RegisterClickEvent(self.BtnBack, self.OnclickClose, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnReturnMain, true)
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask, true)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpString())
end

function XUiSoloReformMain:OnStart()
    self:InitReddot()
end

function XUiSoloReformMain:OnEnable()
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.SoloReform)
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_CHAPTER, self.OnClickChapter, self)
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_KILL_CHAPTER, self.OnClickKillChapter, self)
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD, self.OnGainTaskReward, self)
    self:UpdateChapterList()
    self:RefreshActivityTime()
    self:RefreshRewardsShow()
    self:RefreshTaskProcess()
    self:RefreshReddot()
    self._Control:StartActivityEndCheckTimer()
end

function XUiSoloReformMain:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_CHAPTER, self.OnClickChapter, self)
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_KILL_CHAPTER, self.OnClickKillChapter, self)
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD, self.OnGainTaskReward, self)
    self:StopTimer()
    self._Control:StopActivityEndCheckTimer()
end

function XUiSoloReformMain:InitReddot()
    self._TaskReddotId = self:AddRedPointEvent(self.BtnTask, self.OnTaskReddotEvent, self, 
        { XRedPointConditions.Types.CONDITION_SOLO_REFORM_TASK, XRedPointConditions.Types.CONDITION_SOLO_REFORM_CHALLENGE_TASK}, nil, false)
end

function XUiSoloReformMain:OnTaskReddotEvent(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiSoloReformMain:RefreshReddot()
    XRedPointManager.Check(self._TaskReddotId)
end

function XUiSoloReformMain:RefreshActivityTime()
    local activityCfg = self._Control:GetActivityCfg()
    local isOpen = XFunctionManager.CheckInTimeByTimeId(activityCfg.OpenTime)
    if not isOpen then
        return
    end
    self:StopTimer()
    self:UpdateActivityTime()
    self._TimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateActivityTime), XScheduleManager.SECOND)
end

function XUiSoloReformMain:UpdateActivityTime()
    local activityCfg = self._Control:GetActivityCfg()
    local endTime = XFunctionManager.GetEndTimeByTimeId(activityCfg.OpenTime)
    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)
    --self.TxtTime.text = XUiHelper.GetText("ReformBaseStageUnlockText", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    if leftTime <= 0 then
        self:StopTimer()
    end    
end

function XUiSoloReformMain:UpdateChapterList()
    local showChapterList = self._Control:GetAllShowChapterCfgs()
    local chapterGoCount = self.PanelChapter.transform.childCount
    if not XTool.IsNumberValid(chapterGoCount) then
        return
    end    
    for i = 1, chapterGoCount do
        local cell = self._ChapterCellList[i]
        if not cell then
            local go = self.PanelChapter.transform:GetChild(i - 1).gameObject
            -- if i == 1 then
            --     cell = XUiSoloReformChapterKillItem.New(go, self)
            -- else
                cell = XUiSoloReformChapterItem.New(go, self)
            -- end
            self._ChapterCellList[i] = cell
        end
        if showChapterList[i] then
            cell:Open()
            cell:Update(showChapterList[i], i)
        else
            cell:Close()
        end    
    end
    --XTool.UpdateDynamicItem(self._ChapterCellList, showChapterList, self.GridChapter, XUiSoloReformChapterItem, self) 
end

function XUiSoloReformMain:RefreshRewardsShow()
    local rewardDatas = self._Control:GetShowRewardDatas()
    self._RewardCellList = XUiHelper.RefreshUiObjectList(self._RewardCellList, self.Grid256New.transform.parent, self.Grid256New, #rewardDatas, function(index, grid)
        ---@type XUiGridCommon
        local cell = XUiGridCommon.New(self, grid.GameObject)
        cell:Refresh(rewardDatas[index])
        cell:SetName("")
        cell:ShowCount(false)
    end)
end

function XUiSoloReformMain:RefreshTaskProcess()
   local completedCount, totalCount = self._Control:GetCompletedTaskCountAndTotal()
   self.TxtTaskNum.text = string.format("<color=%s>%d</color>/%d", self._Control:GetColor(), completedCount, totalCount)
   local process = 0
   if totalCount > 0 then
        process = completedCount/totalCount
   end
   self.ImgBar.fillAmount = process    
end

function XUiSoloReformMain:OnClickChapter(chapterId)
    self:PlayAnimationWithMask("Entry", function()
        self:ClickChapter(chapterId)
    end)
end

function XUiSoloReformMain:OnClickKillChapter(chapterId)
    self:PlayAnimationWithMask("Entry", function()
        self:ClickKillChapter(chapterId)
    end)
end

function XUiSoloReformMain:OnGainTaskReward()
    self:RefreshReddot()
end

function XUiSoloReformMain:ClickChapter(chapterId)
    XLuaUiManager.Open("UiSoloReformChapterDetail", chapterId)
    self._Control:MarkLocalChapterReddot(chapterId)
end

function XUiSoloReformMain:ClickKillChapter(chapterId)
    XLuaUiManager.Open("UiSoloReformKillChapterDetail", chapterId)
    self._Control:MarkLocalChapterReddot(chapterId)
end



function XUiSoloReformMain:StopTimer()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
end

function XUiSoloReformMain:OnclickClose()
    self:PlayAnimationWithMask("Disable", function()
        XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.SoloReform)
        self:Close()
    end)
end

function XUiSoloReformMain:OnReturnMain()
    XLuaUiManager.RunMain()
end

function XUiSoloReformMain:OnClickTask()
    XLuaUiManager.Open("UiSoloReformPopupReward")
end

function XUiSoloReformMain:OnDestroy()
    self:StopTimer()
    self._ChapterCellList = nil
    self._TaskReddotId = nil
end

return XUiSoloReformMain