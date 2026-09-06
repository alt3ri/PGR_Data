local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiSignWeekCardGridDay:XUiNode
local XUiSignWeekCardGridDay = XClass(XUiNode, "XUiSignWeekCardGridDay")

-- 购买礼包预览态固定表现:第 1 天高亮、第 2 天"明日获得"(此时无真实签到进度,按卡位模拟)
local PREVIEW_HIGHLIGHT_DAY = 1
local PREVIEW_TOMORROW_DAY = 2

function XUiSignWeekCardGridDay:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitComponent()
    self:InitAddListen()
end

function XUiSignWeekCardGridDay:InitComponent()
    self.PanelNext.gameObject:SetActiveEx(false)
end

function XUiSignWeekCardGridDay:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiSignWeekCardGridDay:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiSignWeekCardGridDay:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiSignWeekCardGridDay:InitAddListen()
    if not self.BtnCard then
        return
    end
    self:RegisterClickEvent(self.BtnCard, self.OnBtnCardClick)
end

function XUiSignWeekCardGridDay:OnBtnCardClick()
    XDataCenter.AutoWindowManager.StopAutoWindow()
    XDataCenter.PurchaseManager.OpenYKPackageBuyUi()
end

function XUiSignWeekCardGridDay:OnEnable()
    self:AnimaStart()
end

function XUiSignWeekCardGridDay:OnDisable()

end

function XUiSignWeekCardGridDay:OnDestroy()
    self:RemoveRewardTimer()
end

function XUiSignWeekCardGridDay:RefreshByRewardInfo(rewardInfo, index)
    self.PanelHaveGroup.alpha = 0
    self.PanelHaveReceive.gameObject:SetActiveEx(false)
    self.PanelCheck.gameObject:SetActiveEx(false)
    self:SetEffectActive(false)
    -- 预览态无真实进度,用卡位模拟:第 1 天高亮底图,第 2 天显示"明日获得"
    local isFirstCard = index == PREVIEW_HIGHLIGHT_DAY
    local isSecondCard = index == PREVIEW_TOMORROW_DAY
    self:RefreshBaseImg(isFirstCard)
    self.PanelNext.gameObject:SetActiveEx(isSecondCard)

    local rewardList = XRewardManager.GetRewardList(rewardInfo)
    self.TxtDay.text = string.format("%02d", index)

    self:RefreshRewardGrids(rewardList)
end

-- 按 rewardList 动态渲染多个道具格子:以 self.GridCommon 为模板,实例化到 ItemGroup 下,复用缓存
function XUiSignWeekCardGridDay:RefreshRewardGrids(rewardList)
    self.GridList = self.GridList or {}
    local parent = self.GridCommon.transform.parent
    local count = rewardList and #rewardList or 0
    for i = 1, count do
        local grid = self.GridList[i]
        if not grid then
            local go = (i == 1) and self.GridCommon
                or CS.UnityEngine.GameObject.Instantiate(self.GridCommon.gameObject, parent)
            grid = XUiGridCommon.New(self.RootUi, go)
            self.GridList[i] = grid
        end
        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridList do
        self.GridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiSignWeekCardGridDay:Refresh(weekCardData, roundIndex, index, isShow, forceSetTomorrow)
    self.IsShow = isShow
    ---@type XPurchaseWeekCardData
    self.WeekCardData = weekCardData
    self.RoundIndex = roundIndex
    self.Index = index
    self.RewardId = weekCardData.RewardInfos[index]
    self.IsToday = self.RoundIndex == self.WeekCardData:GetCurRound() and self.Index == self.WeekCardData:GetCurRoundDay()

    self.ForceSetTomorrow = forceSetTomorrow
    self.PanelNext.gameObject:SetActiveEx(false)
    self.TxtDay.text = string.format("%02d", index)
    self:SetTomorrow()

    local isAlreadyGet = self.WeekCardData:CheckIsGotByRoundAndDay(roundIndex, index)
    local isPreviousDay = self.WeekCardData:CheckIsPreviousDay(roundIndex, index)
    self.PanelHaveGroup.alpha = isPreviousDay and 1 or 0
    self.PanelHaveReceive.gameObject:SetActiveEx(isPreviousDay)
    self.PanelCheck.gameObject:SetActiveEx(isAlreadyGet)
    self:SetEffectActive(false)
    self:RefreshBaseImg(self.IsToday and not isAlreadyGet)

    local rewardList = XRewardManager.GetRewardList(self.RewardId)
    if not rewardList or #rewardList <= 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    self:RefreshRewardGrids(rewardList)
end

-- 当日可领时显示高亮底图,否则(未到/往日/已领)显示普通底图。ImgNormal/ImgHighlight 仅部分预制注册,故判空
function XUiSignWeekCardGridDay:RefreshBaseImg(canReceiveToday)
    if self.ImgNormal then
        self.ImgNormal.gameObject:SetActiveEx(not canReceiveToday)
    end
    if self.ImgHighlight then
        self.ImgHighlight.gameObject:SetActiveEx(canReceiveToday)
    end
end

function XUiSignWeekCardGridDay:SetTomorrow()
    local isTomorrow = (self.WeekCardData:GetCurDay() + 1) == ((self.RoundIndex - 1) * self.WeekCardData:GetOneRoundDayCount() + self.Index)
    self.PanelNext.gameObject:SetActiveEx(isTomorrow)
end

function XUiSignWeekCardGridDay:AnimaStart()
    if not self.IsShow then
        return
    end

    local isGot = self.WeekCardData:CheckIsGotByRoundAndDay(self.RoundIndex, self.Index)
    if not self.IsToday then
        return
    end

    if self.IsToday and isGot then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true, self.Config)
        return
    end

    self:GetWeekCardReward()
end

function XUiSignWeekCardGridDay:SetEffectActive(active)
    self.PanelEffect.gameObject:SetActiveEx(active)
end

function XUiSignWeekCardGridDay:GetWeekCardReward()
    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(self.WeekCardData:GetId(), function(rewards)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        self:RemoveRewardTimer()
        XLuaUiManager.SetMask(true)
        self._RewardTimerId = XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
            self:HandlerReward(rewards)
            self.WeekCardData:SetWeekCardGotToday()
        end, 700)
    end)
end

function XUiSignWeekCardGridDay:RemoveRewardTimer()
    if self._RewardTimerId then
        XScheduleManager.UnSchedule(self._RewardTimerId)
        self._RewardTimerId = nil
    end
end

function XUiSignWeekCardGridDay:HandlerReward(rewardItems)
    if rewardItems and #rewardItems > 0 then
        self:SetReward(rewardItems)
    else
        self:SetNoReward()
    end
end

function XUiSignWeekCardGridDay:SetReward(rewardItems)
    self.PanelHaveGroup.alpha = 1
    self.PanelHaveReceive.gameObject:SetActiveEx(true)
    self.PanelCheck.gameObject:SetActiveEx(true)
    self.GameObject:PlayTimelineAnimation(function()
        XUiManager.OpenUiObtain(rewardItems)
        self:SetEffectActive(false)
        self:RefreshBaseImg(false)
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true, self.Config)
    end, function()
        self:SetEffectActive(true)
    end)
end

function XUiSignWeekCardGridDay:SetNoReward()
    self:SetEffectActive(false)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

return XUiSignWeekCardGridDay