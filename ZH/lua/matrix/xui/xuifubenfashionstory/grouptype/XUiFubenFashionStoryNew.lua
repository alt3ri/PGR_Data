local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridFashionStoryGroup = require("XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryGroup")
---@class XUiFubenFashionStoryNew : XLuaUi
local XUiFubenFashionStoryNew = XLuaUiManager.Register(XLuaUi, "UiFubenFashionStoryNew")

--region 生命周期
function XUiFubenFashionStoryNew:OnAwake()
    self:Init()
    self:InitChapterGroup()
end

function XUiFubenFashionStoryNew:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XMVCA.XFashionStory:GetActivityTime(XMVCA.XFashionStory:GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionStoryNew:OnEnable()
    self:UpdateGroupGridUi()
    self:UpdateLeftTime(XMVCA.XFashionStory:GetLeftTimeStamp(XMVCA.XFashionStory:GetCurrentActivityId()) <= 0)
    XRedPointManager.Check(self.TaskRedPointId)
    XRedPointManager.Check(self.RewardRedPointId)
    self:RefreshRewardState()
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskSync, self)
end

function XUiFubenFashionStoryNew:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskSync, self)
end

function XUiFubenFashionStoryNew:OnTaskSync()
    XRedPointManager.Check(self.RewardRedPointId)
    self:RefreshRewardState()
end

function XUiFubenFashionStoryNew:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.TaskRedPointId)
    XRedPointManager.RemoveRedPointEvent(self.RewardRedPointId)
end
--endregion

--region 初始化
function XUiFubenFashionStoryNew:Init()
    self.BtnBack:AddEventListener(Handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(Handler(self, self.OnBtnMainUiClick))
    --试衣间
    self.BtnSkipFitting:AddEventListener(Handler(self, self.OnBtnSkipFittingClick))
    --任务
    self.BtnSkipTask:AddEventListener(Handler(self, self.OnBtnSkipTaskClick))
    --前往v4.7土豆兄弟活动界面
    self.BtnSkinGo:AddEventListener(Handler(self, self.OnBtnSkinGoClick))

    self.TaskRedPointId = XRedPointManager.AddRedPointEvent(self.BtnSkipTask, self.TaskBtnReddot, self, { XRedPointConditions.Types.CONDITION_FASHION_STORY_TASK }, nil, false)
    self.RewardRedPointId = XRedPointManager.AddRedPointEvent(self.BtnSkinGo, self.RewardBtnReddot, self, { XRedPointConditions.Types.CONDITION_FASHION_STORY_REWARD }, nil, false)
end

function XUiFubenFashionStoryNew:InitChapterGroup()
    self.GroupCtrl = {}
    for i = 1, 5 do
        local panel = self["PanelSummer" .. string.format("%02d", i)]
        if panel then
            self.GroupCtrl[i] = XUiGridFashionStoryGroup.New(self, panel)
        end
    end
end
--endregion

--region 事件处理
function XUiFubenFashionStoryNew:OnBtnBackClick()
    self:Close()
end

function XUiFubenFashionStoryNew:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenFashionStoryNew:OnBtnSkipFittingClick()
    XLuaUiManager.Open("UiFubenFashionFittingNew")
end

function XUiFubenFashionStoryNew:OnBtnSkipTaskClick()
    XLuaUiManager.Open("UiFingerFashionTask")
end

function XUiFubenFashionStoryNew:OnBtnSkinGoClick()
    local activityId = self.ActivityId
    local state = self.RewardState
    local RewardState = XMVCA.XFashionStory.RewardState

    if state == RewardState.Locked or state == RewardState.Ended then
        local timeId = XMVCA.XFashionStory:GetRewardActivityTimeId(activityId)
        local tipText = XMVCA.XFashionStory:GetRewardActivityLockText(timeId)
        XUiManager.TipMsg(tipText)
        return
    end
    if state == RewardState.None then
        XLog.Error(string.format("[XUiFubenFashionStoryNew] RewardTaskId 未配置, activityId=%s", tostring(activityId)))
        return
    end

    local skipId = XMVCA.XFashionStory:GetRewardSkipId(activityId)
    XFunctionManager.SkipInterface(skipId)
end
--endregion

--region 数据更新
function XUiFubenFashionStoryNew:UpdateGroupGridUi()
    --读取组id
    local groupIds = XMVCA.XFashionStory:GetSingleLines(XMVCA.XFashionStory:GetCurrentActivityId())
    for i, groupId in ipairs(groupIds) do
        if self.GroupCtrl[i] then
            self.GroupCtrl[i]:Refresh(groupId)
        end
    end
end

function XUiFubenFashionStoryNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    else
        --UI更新
        local leftTimeStamp = XMVCA.XFashionStory:GetLeftTimeStamp(XMVCA.XFashionStory:GetCurrentActivityId())
        local leftTime = XUiHelper.GetTime(leftTimeStamp, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtChapterLeftTime.text = leftTime
        for _, ctrl in ipairs(self.GroupCtrl) do
            ctrl:RefreshLockCountDown()
        end
        -- 奖励入口状态可能随活动开始/结束翻转，非终态时每秒刷一次以驱动倒计时与状态切换
        local RewardState = XMVCA.XFashionStory.RewardState
        if self.RewardState ~= RewardState.Ended and self.RewardState ~= RewardState.None then
            self:RefreshRewardState()
        end
    end
end

function XUiFubenFashionStoryNew:RefreshRewardState()
    local activityId = XMVCA.XFashionStory:GetCurrentActivityId()
    local state = XMVCA.XFashionStory:GetRewardClaimState(activityId)
    local RewardState = XMVCA.XFashionStory.RewardState

    self.ActivityId = activityId

    if self.RewardState ~= state then
        self.RewardState = state
        -- 锁定/结束态共用按钮 Disable，表现差异由 RefreshSkinGoLockView 的子对象负责
        if state == RewardState.Locked or state == RewardState.Ended then
            self.BtnSkinGo:SetDisable(true)
        else
            self.BtnSkinGo:SetDisable(false)
            self.BtnSkinGo:SetButtonState(state == RewardState.Received and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        end
        self:RefreshSkinGoLockView(state)
        self:RefreshRewardLoopAnim(state == RewardState.CanReceive)
        if self.RewardRedPointId then
            XRedPointManager.Check(self.RewardRedPointId)
        end
        if state == RewardState.None then
            XLog.Error(string.format("[XUiFubenFashionStoryNew] RewardTaskId 未配置, activityId=%s", tostring(activityId)))
        end
    end

    local text
    if state == RewardState.Locked or state == RewardState.Ended then
        local timeId = XMVCA.XFashionStory:GetRewardActivityTimeId(activityId)
        text = XMVCA.XFashionStory:GetRewardActivityLockText(timeId)
    elseif state == RewardState.CanReceive then
        text = XUiHelper.GetText("FashionStoryRewardGo")
    elseif state == RewardState.Received then
        text = XUiHelper.GetText("FashionStoryRewardReceived")
    else
        text = ""
    end
    if self._LastRewardText ~= text then
        self._LastRewardText = text
        self.BtnSkinGo:SetNameByGroup(0, text)
    end
end

function XUiFubenFashionStoryNew:RefreshSkinGoLockView(state)
    local RewardState = XMVCA.XFashionStory.RewardState
    -- 锁定态与结束态共用按钮 Disable：各自一个子对象负责表现，按状态二选一显隐
    if self.SkinGoLock then
        self.SkinGoLock.gameObject:SetActiveEx(state == RewardState.Locked)
    end
    if self.SkinGoEnded then
        self.SkinGoEnded.gameObject:SetActiveEx(state == RewardState.Ended)
    end
end

function XUiFubenFashionStoryNew:RefreshRewardLoopAnim(isPlay)
    if isPlay then
        self.Loop:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    else
        self.Loop:StopTimelineAnimation()
    end
end
--endregion

--region 红点
function XUiFubenFashionStoryNew:TaskBtnReddot(count)
    self.BtnSkipTask:ShowReddot(count >= 0)
end

function XUiFubenFashionStoryNew:RewardBtnReddot(count)
    self.BtnSkinGo:ShowReddot(count >= 0)
end
--endregion

return XUiFubenFashionStoryNew
