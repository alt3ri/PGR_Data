local XUiPassportPanel = require("XCrossVersion/XUi/XUiPassportComb/XUiPassportCombPanel")
local XUiPassportPanelTaskActivity = require("XCrossVersion/XUi/XUiPassportComb/XUiPassportCombPanelTaskActivity")
local XUiPassportPanelTaskDaily = require("XCrossVersion/XUi/XUiPassportComb/XUiPassportCombPanelTaskDaily")
local XUiPassportPanelTaskWeekly = require("XCrossVersion/XUi/XUiPassportComb/XUiPassportCombPanelTaskWeekly")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@field _Control XPassportCombControl
---@class XUiPassportComb:XLuaUi
local XUiPassportComb = XLuaUiManager.Register(XLuaUi, "UiPassportComb")

local tableInsert = table.insert
local BtnTaskChildMaxCount = 3     --任务页签的子页签最大数量
local BtnGetClickDefaultIndex = 3   --点击跳转至挑战任务页签的下标
local PassportSingleAnimaTime = CS.XGame.ClientConfig:GetFloat("PassportSingleAnimaTime")

--战斗通行证主界面
function XUiPassportComb:OnAwake()
    self.CurWeeklyGroupId = self._Control:GetPassportTaskGroupIdByType(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)      --记录当前第几周
end

function XUiPassportComb:OnStart()
    self:InitData()
    self:InitPanel()
    self:RegisterButtonEvent()
    self:InitUi()
    self:InitTab()
    self:InitRedPoint()
end

function XUiPassportComb:OnEnable()
    self:CheckOpenAutoGetTaskRewardListView()

    if not self._Control:CheckActivityIsOpen() then
        --开着一些弹窗打开其他界面，再从其他界面回来会影响活动结束回到主界面
        self:StartTimer()
        return
    end

    self.IsKeepUpdateTaskPanel = false
    self.ImgLevelEffect.gameObject:SetActiveEx(false)

    XEventManager.AddEventListener(XEventId.EVENT_BUY_EXP_COMPLEATE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.CheckPlayExpAddAnima, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST, self.CheckOpenAutoGetTaskRewardListView, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.PassportCombExp, self.CheckPlayExpAddAnima, self)

    self:Refresh()
    self:StartTimer()
end

function XUiPassportComb:OnDisable()
    self:StopDelayUpdateTaskPanelTimer()
    self:StopTimer()
    for _, panel in ipairs(self.PanelViews) do
        if not XTool.IsTableEmpty(panel) then
            panel:Hide()
        end
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_BUY_EXP_COMPLEATE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.CheckPlayExpAddAnima, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST, self.CheckOpenAutoGetTaskRewardListView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.PassportCombExp, self.CheckPlayExpAddAnima, self)
end

--未按时领取的任务奖励，等打开该界面再弹出提示
function XUiPassportComb:CheckOpenAutoGetTaskRewardListView()
    local rewardList = self._Control:GetCookieAutoGetTaskRewardList()
    if not XTool.IsTableEmpty(rewardList) then
        local title = CS.XTextManager.GetText("PassportAutoGetTipsTitle")
        local desc = CS.XTextManager.GetText("PassportAutoGetTipsDesc")
        XLuaUiManager.Open("UiPassportTips", rewardList, title, desc)

        self._Control:ClearCookieAutoGetTaskRewardList()
    end
end

function XUiPassportComb:InitData()
    local itemId = XDataCenter.ItemManager.ItemId.PassportCombExp
    self.OldExp = XDataCenter.ItemManager.GetCount(itemId)

    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    self.OldLevel = passportBaseInfo:GetLevel()

    self.IsPlayingExpAddAnima = false   --是否正在播放升级动画中
    self.IsRePlayExpAddAnima = false    --正在播放升级动画中有新的数据过来，等动画播完了再重新播放一次动画
end

function XUiPassportComb:InitRedPoint()
    self:AddRedPointEvent(self.Btn01, self.OnCheckRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_COMB_PANEL_REWARD_RED })
    self:AddRedPointEvent(self.Btn02, self.OnCheckTaskRedPoint, self,
            { XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_DAILY_RED,
              XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_WEEKLY_RED,
              XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_ACTIVITY_RED })
    self:AddRedPointEvent(self.BtnChild01, self.OnCheckTaskDailyRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_DAILY_RED })
    self:AddRedPointEvent(self.BtnChild02, self.OnCheckTaskWeeklyRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_WEEKLY_RED })
    self:AddRedPointEvent(self.BtnChild03, self.OnCheckTaskActivityRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_ACTIVITY_RED })
end

function XUiPassportComb:InitPanel()
    self.PassportPanel = XUiPassportPanel.New(self.PanelPassport, self)
    self.PassportPanelTaskActivity = XUiPassportPanelTaskActivity.New(self.PanelTaskActivity, self)
    self.PassportPanelTaskDaily = XUiPassportPanelTaskDaily.New(self.PanelTaskDaily, self)
    self.PassportPanelTaskWeekly = XUiPassportPanelTaskWeekly.New(self.PanelTaskWeekly, self)
    self:InitSubPanel()
end

function XUiPassportComb:InitSubPanel()
    self.PanelViews = {}
    tableInsert(self.PanelViews, self.PassportPanel)
    tableInsert(self.PanelViews, {})    --为了和页签数量相同占位用
    tableInsert(self.PanelViews, self.PassportPanelTaskDaily)
    tableInsert(self.PanelViews, self.PassportPanelTaskWeekly)
    tableInsert(self.PanelViews, self.PassportPanelTaskActivity)
end

function XUiPassportComb:InitTab()
    self.BtnGroupList = {}

    tableInsert(self.BtnGroupList, self.Btn01)     --战略补给
    tableInsert(self.BtnGroupList, self.Btn02)     --任务

    --任务下的子页签
    local tagCount = #self.BtnGroupList
    local btn
    for i = 1, BtnTaskChildMaxCount do
        btn = self["BtnChild0" .. i]
        if btn then
            self["BtnChild0" .. i].SubGroupIndex = tagCount
            tableInsert(self.BtnGroupList, btn)
        end
    end

    local defaultTagIndex = self._Control:GetCurrMainViewSelectTagIndex()
    self.PanelNoticeTitleBtnGroup:Init(self.BtnGroupList, function(index)
        self:OnSelectedTag(index)
    end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(defaultTagIndex)
end

function XUiPassportComb:OnSelectedTag(index)
    if self.CurrSelectTagIndex == index then
        return
    end

    self.CurrSelectTagIndex = index
    self._Control:CatchCurrMainViewSelectTagIndex(index)
    self:UpdatePanel()
end

function XUiPassportComb:InitUi()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiPassportComb:Refresh()
    self:UpdateActivityTime()
    self:UpdateLevel()
    self:CheckPlayExpAddAnima()
    self:UpdatePanel()
end

function XUiPassportComb:UpdatePanel()
    local currSelectTagIndex = self:GetCurrSelectTagIndex()
    for i, panel in ipairs(self.PanelViews) do
        if i == currSelectTagIndex then
            panel:Show()
        elseif not XTool.IsTableEmpty(panel) then
            panel:Hide()
        end
    end
end

function XUiPassportComb:UpdateTaskPanel()
    self.PassportPanelTaskDaily:Refresh()
    self.PassportPanelTaskActivity:Refresh()
    self.PassportPanelTaskWeekly:Refresh()
end

function XUiPassportComb:UpdateLevel(isPlayEffect)
    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    self.TxtLevel.text = level

    if isPlayEffect then
        self.ImgLevelEffect.gameObject:SetActiveEx(false)
        self.ImgLevelEffect.gameObject:SetActiveEx(true)
    end
end

function XUiPassportComb:UpdateActivityTime()
    local timeId = self._Control:GetPassportActivityTimeId()
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local startTimeStr = os.date("%m/%d", startTime)
    local endTimeStr = os.date("%m/%d", endTime)
    local totleWeekly, currWeekly = self._Control:GetPassportWeeklyTaskGroupCountAndCurrWeekly()
    self.TxtTime01.text = CS.XTextManager.GetText("PassportActivityTime", startTimeStr, endTimeStr, totleWeekly)
    self.TxtTime02.text = CS.XTextManager.GetText("PassportActivityCurrWeekly", currWeekly)

    local alarmClockId = CS.XGame.ClientConfig:GetInt("BPDailyUpdateTime")
    if alarmClockId and not XTool.UObjIsNil(self.TxtDaily) then
        local alarmClockConfig = self._Control:GetAlarmClockList(alarmClockId)
        local hours = math.floor(alarmClockConfig.EpochTime / 3600)
        self.TxtDaily.text = CS.XTextManager.GetText("BPDailyUpdateText", string.format("%d:00", hours))
    end
end

function XUiPassportComb:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuyClick)
    self:BindHelpBtn(self.BtnHelp, "Passport")
end

--跳转至挑战任务页签
function XUiPassportComb:OnBtnGetClick()
    self.PanelNoticeTitleBtnGroup:SelectIndex(BtnGetClickDefaultIndex)
end

--购买等级
function XUiPassportComb:OnBtnBuyClick()
    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    local maxLevel = self._Control:GetPassportMaxBuyableLevel()
    if level >= maxLevel then
        XUiManager.TipText("PassportBuyLevelMaxDesc")
        return
    end
    XLuaUiManager.Open("UiPassportCombUpLevel")
end

function XUiPassportComb:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiPassportComb:OnNotify(event)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        --一键领取奖励和一键完成任务会频繁刷新，加个延迟防卡顿
        if self.DelayUpdateTaskPanelTimer then
            self.IsKeepUpdateTaskPanel = true
            return
        end

        self:UpdateTaskPanel()
        self.DelayUpdateTaskPanelTimer = XScheduleManager.ScheduleOnce(function()
            if self.IsKeepUpdateTaskPanel then
                self:UpdateTaskPanel()
                self.IsKeepUpdateTaskPanel = false
            end
            self:StopDelayUpdateTaskPanelTimer()
        end, 500)
    end
end

function XUiPassportComb:StopDelayUpdateTaskPanelTimer()
    if self.DelayUpdateTaskPanelTimer then
        XScheduleManager.UnSchedule(self.DelayUpdateTaskPanelTimer)
        self.DelayUpdateTaskPanelTimer = nil
    end
end

function XUiPassportComb:GetCurrSelectTagIndex()
    return self.CurrSelectTagIndex
end

function XUiPassportComb:OnCheckRewardRedPoint(count)
    self.Btn01:ShowReddot(count >= 0)
end

function XUiPassportComb:OnCheckTaskRedPoint(count)
    self.Btn02:ShowReddot(count >= 0)
end

function XUiPassportComb:OnCheckTaskDailyRedPoint(count)
    self.BtnChild01:ShowReddot(count >= 0)
end

function XUiPassportComb:OnCheckTaskWeeklyRedPoint(count)
    self.BtnChild02:ShowReddot(count >= 0)
end

function XUiPassportComb:OnCheckTaskActivityRedPoint(count)
    self.BtnChild03:ShowReddot(count >= 0)
end

function XUiPassportComb:StartTimer()
    self:StopTimer()
    local curWeeklyGroupId
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        if not self._Control:CheckActivityIsOpen() then
            return
        end

        curWeeklyGroupId = self._Control:GetPassportTaskGroupIdByType(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)
        if curWeeklyGroupId ~= self.CurWeeklyGroupId then
            self.CurWeeklyGroupId = curWeeklyGroupId
            self:Refresh()
            return
        end

        self.PassportPanelTaskWeekly:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiPassportComb:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--检查是否需要播放增加经验的动画
function XUiPassportComb:CheckPlayExpAddAnima()
    if self.IsPlayingExpAddAnima then
        if not self.IsRePlayExpAddAnima then
            self.IsRePlayExpAddAnima = true
        end
        return
    end

    self.IsPlayingExpAddAnima = true

    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()                   --当前等级
    local maxLevel = self._Control:GetPassportMaxLevel()     --最大等级
    local itemId = XDataCenter.ItemManager.ItemId.PassportCombExp
    local curExp = XDataCenter.ItemManager.GetCount(itemId)     --当前拥有的经验
    local oldExp = self.OldExp
    local oldLevel = self.OldLevel
    local progress

    local CheckRePlayExpAddAnima = function()
        if self.IsRePlayExpAddAnima then
            self.IsRePlayExpAddAnima = false
            self:CheckPlayExpAddAnima()
        end
    end

    if level == maxLevel and oldLevel == level then
        self.IsPlayingExpAddAnima = false
        self.TxtPoint.text = CS.XTextManager.GetText("PassportMaxExpText")
        self.TxtPointNum.text = curExp
        self.ImgProgress.fillAmount = 1
        self:UpdateLevel()
        CheckRePlayExpAddAnima()
        return
    end

    self.TxtPoint.text = CS.XTextManager.GetText("PassportExpText")

    local oldLevelOfNextLevel = math.min(maxLevel, oldLevel + 1)
    local oldLevelOfNextLevelId = self._Control:GetPassportLevelId(oldLevelOfNextLevel)
    local oldLevelOfNextLevelTotalExp = oldLevelOfNextLevelId and self._Control:GetPassportLevelTotalExp(oldLevelOfNextLevelId)        --等级改变前升至下一级需要的总经验
    local changeExp = level > oldLevel and oldLevelOfNextLevelTotalExp - oldExp or curExp - oldExp          --等级改变前经验的变化量
    local oldLevelId = XTool.IsNumberValid(oldLevel) and self._Control:GetPassportLevelId(oldLevel)
    local oldLevelTotalExp = oldLevelId and self._Control:GetPassportLevelTotalExp(oldLevelId) or 0      --等级改变前的最大经验

    local upperLevel = oldLevel - 1
    local oldLevelShowExp = upperLevel > 0 and oldExp - oldLevelTotalExp or oldExp
    local nextLevelShowTotalExp = (upperLevel > 0 and XTool.IsNumberValid(oldLevelOfNextLevelTotalExp)) and oldLevelOfNextLevelTotalExp - oldLevelTotalExp or oldLevelOfNextLevelTotalExp

    if (curExp == oldExp and level == oldLevel) or changeExp <= 0 then
        progress = XTool.IsNumberValid(nextLevelShowTotalExp) and oldLevelShowExp / nextLevelShowTotalExp or 0
        self.TxtPointNum.text = CS.XTextManager.GetText("PassportExp", oldLevelShowExp, nextLevelShowTotalExp)
        self.ImgProgress.fillAmount = math.min(1, progress)
        self.IsPlayingExpAddAnima = false
        CheckRePlayExpAddAnima()
        return
    end

    local curExpTemp
    XUiHelper.Tween(PassportSingleAnimaTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        curExpTemp = math.min(oldLevelShowExp + math.floor(f * changeExp), nextLevelShowTotalExp)
        progress = curExpTemp / nextLevelShowTotalExp
        self.TxtPointNum.text = CS.XTextManager.GetText("PassportExp", curExpTemp, nextLevelShowTotalExp)    --（玩家总经验-之前等级升级需要经验之和）/ 升至下一等级需要的经验
        self.ImgProgress.fillAmount = math.min(1, progress)

    end, function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        self.IsPlayingExpAddAnima = false
        self.OldLevel = level
        if level > oldLevel then
            self.IsRePlayExpAddAnima = false
            local nextLevelId = self._Control:GetPassportLevelId(level)
            self.OldExp = nextLevelId and self._Control:GetPassportLevelTotalExp(nextLevelId) or 0
            self:UpdateLevel(true)
            self:CheckPlayExpAddAnima()
        else
            self.OldExp = curExp
            CheckRePlayExpAddAnima()
        end
    end)
end