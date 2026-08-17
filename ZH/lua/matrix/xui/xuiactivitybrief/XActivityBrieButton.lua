local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
---@class XActivityBrieButton
local XActivityBrieButton = XClass(nil, "XActivityBrieButton", true)


local ACTIVITYBRIEBUTTONISFIRSTTIMECLICK = "ActivityBrieButtonIsFirstTimeClick"

function XActivityBrieButton:Ctor(ui, uiRoot, activityGroupId)
    self.BtnCom = ui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.activityGroupId = activityGroupId
    self.IsAlwaysCheck = false
    self.Offset = 0
    self.BtnCom:ShowTag(false)
    self.BtnCom:ShowReddot(false)
    self:InitUnlockAnim()
end

function XActivityBrieButton:OnDisable()
    self:_ReleaseRedPoint()
    self:_ReleaseTagRedPoint()
    self:_CancelUnlockAnimTimer()
end

function XActivityBrieButton:Refresh(args)
    local isOpen, str, timeStr = XActivityBrieIsOpen.Get(self.activityGroupId, args)
    self.args = args

    if not string.IsNilOrEmpty(timeStr) then
        self.BtnCom:SetNameByGroup(0, timeStr)
    else
        local config = XActivityBriefConfigs.GetActivityGroupConfig(self.activityGroupId)
        self.BtnCom:SetNameByGroup(0, "")
    end
    local isWaitLockAnim = XTool.IsNumberValid(XActivityBriefConfigs.GetActivityBriefGroupIsRemindWhenOpen(self.activityGroupId))
        and not XDataCenter.ActivityBriefManager.GetIsPlayedUnlockAnim(self.activityGroupId)

    self:ShowBtnCom(isOpen, isWaitLockAnim)
end

function XActivityBrieButton:ShowBtnCom(isOpen, isWaitLockAnim)
    self.BtnCom:SetDisable(not isOpen or isOpen and isWaitLockAnim)   
end

function XActivityBrieButton:ShowActivityTag()
    self:SetActivityTagVisible(false)

    if XDataCenter.FubenRepeatChallengeManager.IsMultiRewardOpen() then
        local multiRewardCfg = XDataCenter.FubenRepeatChallengeManager.GetMultiRewardActivityCfg()
        if multiRewardCfg.ActivityBriefGroupId == self.activityGroupId then
            local countStr = XTool.ConvertChineseNumberString(multiRewardCfg.Multiple)
            self:SetActivityTagVisible(true)
            self:SetActivityTagText(XUiHelper.GetText("ActivityRepeatChallengeMultiRewardTag2", countStr))
            return
        end
    end
end

function XActivityBrieButton:SetActivityTagVisible(isShow)
    for i = 1, 3 do
        local tag = self[string.format("Tag%s", i)]
        if not XTool.UObjIsNil(tag) then
            tag.gameObject:SetActiveEx(isShow)
        end
    end
end

function XActivityBrieButton:SetActivityTagText(words)
    for i = 1, 3 do
        local tagText = self[string.format("TextTag%s", i)]
        if not XTool.UObjIsNil(tagText) then
            tagText.text = words
        end
    end
end

--region Ui - Anim
---初始化解锁动画状态
function XActivityBrieButton:InitUnlockAnim()
    self.PanelEffectLock = self.PanelEffectLock or XUiHelper.TryGetComponent(self.Transform, "PanelEffectLock")
    if self.PanelEffectLock then
        self.PanelEffectLock.gameObject:SetActiveEx(false)
    end
end

---播放解锁动画
---@param cb function 动画结束回调
function XActivityBrieButton:PlayUnlockAnim(cb)
    XDataCenter.ActivityBriefManager.SetIsPlayedUnlockAnim(self.activityGroupId)
    if self.PanelEffectLock then
        self.PanelEffectLock.gameObject:SetActiveEx(false)
        self.PanelEffectLock.gameObject:SetActiveEx(true)
        self.BtnCom:SetDisable(false)
        self._UnlockAnimTimer = XScheduleManager.ScheduleOnce(function()
            self._UnlockAnimTimer = nil
            -- 关闭特效防止跳转其他界面返回时出现特效
            if not XTool.UObjIsNil(self.PanelEffectLock) then
                self.PanelEffectLock.gameObject:SetActiveEx(false)
            end
            if cb then cb() end
        end, 800)
    else
        if cb then cb() end
    end
end

function XActivityBrieButton:_CancelUnlockAnimTimer()
    if self._UnlockAnimTimer then
        XScheduleManager.UnSchedule(self._UnlockAnimTimer)
        self._UnlockAnimTimer = nil
    end
end
--endregion

--region Ui - Tag
---可挑战Tag,第一次点击后消失
---@param conditionGroup table<number, string>XRedPointConditions.Conditions
---@param args any XRedPointConditions.Conditions用的参数
---@param isAlwaysCheck boolean 为true时未点击前恒显示tag
---@param offset number|nil 时间戳数据,不填时默认服务器下次刷新时间刷新tag,不为0时服务器下次刷新时间+offset时刷新tag
function XActivityBrieButton:AddNewTagEvent(conditionGroup, args, isAlwaysCheck,offset)
    self:_ReleaseTagRedPoint()
    self.IsAlwaysCheck = isAlwaysCheck
    if self:CheckFirstClicked(offset) or isAlwaysCheck then
        self._TagRedPointEventId = XRedPointManager.AddRedPointEvent(self.BtnCom, self.OnNewTagEvent, self, conditionGroup, args, true)
    else
        self.BtnCom:ShowTag(false)
    end
end

function XActivityBrieButton:OnNewTagEvent(count)
    self:ShowTag(count > -1)
end

---刷新tag
---@param isShow boolean
---@param offset number|nil 时间戳数据,不填时默认服务器下次刷新时间刷新tag,不为0时服务器下次刷新时间 + offset时刷新tag
function XActivityBrieButton:ShowTag(isShow,offset)
    local isOpen = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)
    if (self:CheckFirstClicked(offset) or self.IsAlwaysCheck) and isOpen then
        self.BtnCom:ShowTag(isShow)
    else
        self.BtnCom:ShowTag(false)
    end
end

function XActivityBrieButton:_ReleaseTagRedPoint()
    if XTool.IsNumberValid(self._TagRedPointEventId) then
        XRedPointManager.RemoveRedPointEvent(self._TagRedPointEventId)
    end
end
--endregion

--region Ui - RedPoint
function XActivityBrieButton:CheckFirstClicked(offset)
    self.Offset = offset or 0
    return not XSaveTool.GetData(self:GetPlayerPrefsKey())
end

---红点刷新事件注册
---@param conditionGroup table<number, string>XRedPointConditions.Conditions
---@param args any XRedPointConditions.Conditions用的参数
function XActivityBrieButton:AddRedPointEvent(conditionGroup, args)
    self:_ReleaseRedPoint()
    self._RedPointEventId = XRedPointManager.AddRedPointEvent(self.BtnCom, self.OnRedPointEvent, self, conditionGroup, args, true)
end

function XActivityBrieButton:OnRedPointEvent(count)
    self:ShowReddot(count >= 0)
end

---刷新红点
---@param value boolean
function XActivityBrieButton:ShowReddot(value)
    local isOpen = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)
    if not isOpen then
        value = false
    end

    local isWaitLockAnim = XTool.IsNumberValid(XActivityBriefConfigs.GetActivityBriefGroupIsRemindWhenOpen(self.activityGroupId))
        and not XDataCenter.ActivityBriefManager.GetIsPlayedUnlockAnim(self.activityGroupId)
    if isWaitLockAnim then
        value = false
    end

    self.BtnCom:ShowReddot(value)
end

function XActivityBrieButton:SetOnClick(func)
    self.BtnCom.CallBack = function()
        local isOpen, str = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)
        if isOpen then
            XSaveTool.SaveData(self:GetPlayerPrefsKey(), true)
            func()
        else
            if string.IsNilOrEmpty(str) then
                XLog.Error("没有返回未开放的点击提示，activityGroupId：" .. self.activityGroupId)
            else
                XUiManager.TipMsg(str)
            end
        end
    end
end

---是否第一次点击缓存的key
function XActivityBrieButton:GetPlayerPrefsKey()
    local dayRefreshTime = XTime.GetSeverTodayFreshTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local severNextRefreshTime = XTime.GetSeverNextRefreshTime()
    local timeOffset = self.Offset
    if nowTime > dayRefreshTime + self.Offset then
        timeOffset = severNextRefreshTime + self.Offset
    else
        timeOffset = dayRefreshTime + self.Offset
    end
    return string.format("%s_%s_%s_%s", XPlayer.Id, ACTIVITYBRIEBUTTONISFIRSTTIMECLICK, timeOffset, self.activityGroupId)
end

function XActivityBrieButton:_ReleaseRedPoint()
    if XTool.IsNumberValid(self._RedPointEventId) then
        XRedPointManager.RemoveRedPointEvent(self._RedPointEventId)
    end
end
--endregion

function XActivityBrieButton:GetButtonCom()
    return self.BtnCom
end

function XActivityBrieButton:IsLock()
    if self.BtnCom then
        return self.BtnCom.ButtonState == CS.UiButtonState.Disable
    end
    return true
end

return XActivityBrieButton