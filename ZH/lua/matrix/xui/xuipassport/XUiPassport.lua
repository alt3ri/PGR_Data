local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPassportPanel = require("XUi/XUiPassport/XUiPassportPanel")
local XUiPassportPanelTask = require("XUi/XUiPassport/XUiPassportPanelTask")
local XUiPassport3D = require("XUi/XUiPassport/XUiPassport3D")

---@field _Control XPassportControl
---@class XUiPassport:XLuaUi
local XUiPassport = XLuaUiManager.Register(XLuaUi, "UiPassport")

local PassportSingleAnimaTime = CS.XGame.ClientConfig:GetFloat("PassportSingleAnimaTime")

local MainTabIndex = {
    Passport = 1,
    Task = 2,
}

--战斗通行证主界面
function XUiPassport:OnAwake()
    self.CurWeeklyGroupId = self._Control:GetPassportTaskGroupIdByType(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)
end

function XUiPassport:OnStart(params)
    local isFirstOpenInThisActivity = false
    local activityId = tostring(self._Control:GetDefaultActivityId())

    if params and params.OpenPassportCard and params.WithStartEnableAnimation then
        params.WithStartEnableAnimation = false
    end

    if params and params.WithStartEnableAnimation then
        local saveKey = "XUiPassport.OnStart.saveKey_" .. XPlayer.Id
        local prevActivityId = XSaveTool.GetData(saveKey)

        if prevActivityId ~= activityId then
            XSaveTool.SaveData(saveKey, activityId)
            isFirstOpenInThisActivity = true
        end
    end

    self.Model3D = XUiPassport3D.New(
        self.UiModelGo.transform,
        self,
        self.UiModel,
        isFirstOpenInThisActivity and params and params.WithStartEnableAnimation)

    self:InitData()
    self:InitPanel()
    self:RegisterButtonEvent()
    self:InitUi()
    self:InitTab()
    self:InitRedPoint()

    if params then
        self.Params = params
        if params.OpenLastPassport then
            self.PassportPanel:OpenLastPassport()
        end

        if params.OpenPassportCard then
            self:OnBtnBuyPassportClick()
        end
    end

    self:RefreshCoating()

    XLuaUiManager.SetMask(true)

    self.AnimationSchedule = XScheduleManager.ScheduleNextFrame(function()
        local function afterAnimation()
            self:CheckOpenAutoGetTaskRewardListView(
                handler(self, self.CheckAndGetSupplyReward))
        end

        XScheduleManager.UnSchedule(self.AnimationSchedule)
        self.AnimationSchedule = nil

        XLuaUiManager.SetMask(false)

        if not params or not params.WithStartEnableAnimation then
            self:PlayAnimationWithMask("NoAnimationEnable", afterAnimation)
        elseif isFirstOpenInThisActivity then
            self:PlayAnimationWithMask("Start", afterAnimation)
        else
            self:PlayAnimationWithMask("Enable", afterAnimation)
        end
    end)
end


function XUiPassport:OnDestroy()
    if self.Params and self.Params.OnClose then
        self.Params.OnClose()
    end
end

function XUiPassport:RefreshCoating()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    if XTool.IsTableEmpty(typeInfoIdList) then
        return
    end

    local _, maxTypeInfoId = XTool.MaxBy(typeInfoIdList, function(_, v)
        return self._Control:GetPassportTypeInfoCostItemCount(v)
    end)

    local fashionId = self._Control:GetPassportBuyFashionShowFashionId(maxTypeInfoId)
    if not XTool.IsNumberValid(fashionId) then
        return
    end

    local fashionShowConfig = self._Control:GetPassportBuyFashionShowConfig(maxTypeInfoId)
    local fashionType = fashionShowConfig.FashionType  -- 0=普通时装, 1=武器投影, 2=FashionColor
    self.Model3D:SetModel(fashionId, fashionType)
end

function XUiPassport:CheckAndGetSupplyReward()
    if not self._Control:GetIsGetSupplyReward() and self._Control:GetPassportActivityHasSupplyReward() then
        self._Control:RequestPassportGetSupplyReward(handler(self, self.Refresh))
    end
end

function XUiPassport:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true

    if not self._Control:CheckActivityIsOpen() then
        self:StartTimer()
        return
    end

    self.IsKeepUpdateTaskPanel = false
    self.ImgLevelEffect.gameObject:SetActiveEx(false)

    XEventManager.AddEventListener(XEventId.EVENT_BUY_EXP_COMPLEATE, self.UpdateMainPanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.CheckPlayExpAddAnima, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST, self.CheckOpenAutoGetTaskRewardListView, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.PassportExp, self.CheckPlayExpAddAnima, self)

    self:Refresh()
    self:StartTimer()
end

function XUiPassport:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false

    self:StopDelayUpdateTaskPanelTimer()
    self:StopTimer()
    for _, panel in ipairs(self.MainPanelViews) do
        if not XTool.IsTableEmpty(panel) then
            panel:Hide()
        end
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_BUY_EXP_COMPLEATE, self.UpdateMainPanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.CheckPlayExpAddAnima, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST, self.CheckOpenAutoGetTaskRewardListView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.PassportExp, self.CheckPlayExpAddAnima, self)
end

--未按时领取的任务奖励，等打开该界面再弹出提示
function XUiPassport:CheckOpenAutoGetTaskRewardListView(cb)
    local rewardList = self._Control:GetCookieAutoGetTaskRewardList()
    if not XTool.IsTableEmpty(rewardList) then
        local title = CS.XTextManager.GetText("PassportAutoGetTipsTitle")
        local desc = CS.XTextManager.GetText("PassportAutoGetTipsDesc")
        XLuaUiManager.Open("UiPassportTips", rewardList, title, desc, cb)

        self._Control:ClearCookieAutoGetTaskRewardList()
    else
        if cb then cb() end
    end
end

function XUiPassport:InitData()
    local itemId = XDataCenter.ItemManager.ItemId.PassportExp
    self.OldExp = XDataCenter.ItemManager.GetCount(itemId)

    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    self.OldLevel = passportBaseInfo:GetLevel()

    self.IsPlayingExpAddAnima = false
    self.IsRePlayExpAddAnima = false
end

function XUiPassport:InitRedPoint()
    self:AddRedPointEvent(self.BtnPassport, self.OnCheckRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_PANEL_REWARD_RED })
    self:AddRedPointEvent(self.BtnTask, self.OnCheckTaskRedPoint, self,
            { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED,
              XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED,
              XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED })
end

function XUiPassport:InitPanel()
    ---@type XUiPassportPanel
    self.PassportPanel = XUiPassportPanel.New(
        self.PanelPassport,
        self,
        handler(self, self.UpdateBtnTongBlack))

    ---@type XUiPassportPanelTask
    self.TaskPanel = XUiPassportPanelTask.New(self.PanelTaskMain, self, self.Model3D)

    self.MainPanelViews = {
        [MainTabIndex.Passport] = self.PassportPanel,
        [MainTabIndex.Task] = self.TaskPanel,
    }
end

function XUiPassport:InitTab()
    self.CurrMainTabIndex = 0

    self.InitTabInProgress = true
    self.PanelTopTab:Init({ self.BtnPassport, self.BtnTask }, function(index)
        self:OnSelectedMainTab(index, self.InitTabInProgress)
    end)
    self.PanelTopTab:SelectIndex(MainTabIndex.Passport, true)
    self.InitTabInProgress = nil
end

function XUiPassport:OnSelectedMainTab(index, noAnimation)
    if self.CurrMainTabIndex == index then
        return
    end
    self.CurrMainTabIndex = index
    self:UpdateMainPanel(not noAnimation)
end

function XUiPassport:InitUi()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiPassport:Refresh()
    if self.GameObject.activeInHierarchy then
        self:UpdateActivityTime()
        self:UpdateLevel()
        self:UpdateCoatingName()
        self:UpdateArchivesName()
        self:CheckPlayExpAddAnima()
        self:UpdateMainPanel()
    end
end

function XUiPassport:UpdateArchivesName()
    self.TextArchives.text = self._Control:GetPassportActivityName()
end

function XUiPassport:UpdateCoatingName()
    if not self.TxtCoatingName then
        return
    end
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for _, typeInfoId in ipairs(typeInfoIdList) do
        local name = self._Control:GetPassportBuyFashionName(typeInfoId)
        if name and name ~= "" then
            self.TxtCoatingName.text = name
            return
        end
    end
    self.TxtCoatingName.text = ""
end

function XUiPassport:UpdateMainPanel(withAnimation)
    local isPassport = self.CurrMainTabIndex == MainTabIndex.Passport
    self.Model3D:ShowTaskCamera(not isPassport)

    if withAnimation then
        if isPassport then
            self:PlayAnimation("QieHuanLtoR")
        else
            self:PlayAnimation("QieHuanRtoL")
        end
    end

    -- PanelPassportMain 是 PanelPassport 的父节点，需要单独控制显隐
    self.PanelPassportMain.gameObject:SetActiveEx(isPassport)

    for i, panel in ipairs(self.MainPanelViews) do
        if i == self.CurrMainTabIndex then
            panel:Show()
        elseif not XTool.IsTableEmpty(panel) then
            if not withAnimation then
                panel:Hide()
            end
        end
    end

    self:UpdateBtnTongBlack()
end

function XUiPassport:UpdateBtnTongBlack()
    local hasReward
    if self.CurrMainTabIndex == MainTabIndex.Passport then
        hasReward = self._Control:HasClaimablePassportReward()
    elseif self.CurrMainTabIndex == MainTabIndex.Task then
        hasReward = self._Control:HasAchievedPassportTask()
    else
        hasReward = false
    end
    self.BtnTongBlack.gameObject:SetActiveEx(hasReward)
end

function XUiPassport:UpdateTaskPanel()
    self.TaskPanel:Refresh()
    self:UpdateBtnTongBlack()
end

function XUiPassport:UpdateLevel(isPlayEffect)
    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    self.TxtLevel.text = level

    if isPlayEffect then
        self.ImgLevelEffect.gameObject:SetActiveEx(false)
        self.ImgLevelEffect.gameObject:SetActiveEx(true)
    end
end

function XUiPassport:UpdateActivityTime()
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

function XUiPassport:RegisterButtonEvent()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(function()
        XLuaUiManager.RunMain()
    end)
    self.BtnGet:AddEventListener(handler(self, self.OnBtnGetClick))
    self.BtnBuyLevel:AddEventListener(handler(self, self.OnBtnBuyLevelClick))
    self.BtnBuyBp:AddEventListener(handler(self, self.OnBtnBuyPassportClick))
    self.BtnTongBlack:AddEventListener(handler(self, self.OnBtnTongBlackClick))
    self.BtnExchange:AddEventListener(handler(self, self.OnBtnExchangeClick))
    self.BtnOpen:AddEventListener(handler(self, self.OnBtnOpenClick))
    self:BindHelpBtn(self.BtnHelp, "Passport")
end

--跳转至任务页签
function XUiPassport:OnBtnGetClick()
    self.PanelTopTab:SelectIndex(MainTabIndex.Task)
end

--购买等级
function XUiPassport:OnBtnBuyLevelClick()
    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    local maxLevel = self._Control:GetPassportMaxBuyableLevel()
    if level >= maxLevel then
        XUiManager.TipText("PassportBuyLevelMaxDesc")
        return
    end
    XLuaUiManager.Open("UiPassportUpLevel", handler(self, self.UpdateBtnTongBlack))
end

--一键领取/完成，根据当前页签切换行为
function XUiPassport:OnBtnTongBlackClick()
    if self.CurrMainTabIndex == MainTabIndex.Passport then
        self._Control:RequestPassportRecvAllReward(handler(self, self.Refresh), self)
    elseif self.CurrMainTabIndex == MainTabIndex.Task then
        self.TaskPanel:FinishMultiTask()
    end
end

--购买通行证（统一入口）
function XUiPassport:OnBtnBuyPassportClick()
    XLuaUiManager.Open(
        "UiPassportCard",
        handler(self, self.Refresh),
        self)
end

--打开兑换商店
function XUiPassport:OnBtnExchangeClick()
    CS.XRecord.Record("20027", "OnEnterShopFromBP")
    XFunctionManager.SkipInterface(10039)
end

function XUiPassport:OnBtnOpenClick()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for _, typeInfoId in ipairs(typeInfoIdList) do
        local fashionId = self._Control:GetPassportBuyFashionShowFashionId(typeInfoId)
        if XTool.IsNumberValid(fashionId) then
            local fashionType = self._Control:GetPassportBuyFashionShowType(typeInfoId)
            local buyData = self._Control:GetPassportFashionBuyData(
                typeInfoId,
                function()
                    XLuaUiManager.CloseWithCallback(
                        "UiPassportFashionDetail",
                        function()
                            self:OnBtnBuyPassportClick()
                        end)
                end)
            XLuaUiManager.Open("UiPassportFashionDetail", fashionId, fashionType, buyData)
            return
        end
    end
end

function XUiPassport:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiPassport:OnNotify(event)
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

function XUiPassport:StopDelayUpdateTaskPanelTimer()
    if self.DelayUpdateTaskPanelTimer then
        XScheduleManager.UnSchedule(self.DelayUpdateTaskPanelTimer)
        self.DelayUpdateTaskPanelTimer = nil
    end
end

function XUiPassport:OnCheckRewardRedPoint(count)
    self.BtnPassport:ShowReddot(count >= 0)
end

function XUiPassport:OnCheckTaskRedPoint(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiPassport:StartTimer()
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

        self.TaskPanel:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiPassport:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--检查是否需要播放增加经验的动画
function XUiPassport:CheckPlayExpAddAnima()
    if self.IsPlayingExpAddAnima then
        if not self.IsRePlayExpAddAnima then
            self.IsRePlayExpAddAnima = true
        end
        return
    end

    self.IsPlayingExpAddAnima = true

    local passportBaseInfo = self._Control:GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    local maxLevel = self._Control:GetPassportMaxLevel()
    local itemId = XDataCenter.ItemManager.ItemId.PassportExp
    local curExp = XDataCenter.ItemManager.GetCount(itemId)
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
    local oldLevelOfNextLevelTotalExp = oldLevelOfNextLevelId and self._Control:GetPassportLevelTotalExp(oldLevelOfNextLevelId)
    local changeExp = level > oldLevel and oldLevelOfNextLevelTotalExp - oldExp or curExp - oldExp
    local oldLevelId = XTool.IsNumberValid(oldLevel) and self._Control:GetPassportLevelId(oldLevel)
    local oldLevelTotalExp = oldLevelId and self._Control:GetPassportLevelTotalExp(oldLevelId) or 0

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
        self.TxtPointNum.text = CS.XTextManager.GetText("PassportExp", curExpTemp, nextLevelShowTotalExp)
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

function XUiPassport:OnShowCard()
    self.SafeAreaContentPane.gameObject:SetActive(false)
    self.Model3D:ShowCardCamera(true)
end

function XUiPassport:OnHideCard()
    self.SafeAreaContentPane.gameObject:SetActive(true)
    self.Model3D:ShowCardCamera(false)
end
