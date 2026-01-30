---@class XUiRiftChooseChapter : XLuaUi
---@field _Control XRiftControl
local XUiRiftChooseChapter = XLuaUiManager.Register(XLuaUi, "UiRiftChooseChapter")

function XUiRiftChooseChapter:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "ChooseChapterHelp")
    self.BtnTask.CallBack = handler(self, self.OnBtnTaskClick)
    self.BtnMopup.CallBack = handler(self, self.OnBtnMopupClick)
    self.BtnAttribute.CallBack = handler(self, self.OnBtnAttributeClick)
    self.BtnPluginBag.CallBack = handler(self, self.OnBtnPluginBagClick)
    self.BtnCharacter.CallBack = handler(self, self.OnBtnCharacterClick)
    self.BtnAttributeRedEventId = XRedPointManager.AddRedPointEvent(self.BtnAttribute, self.OnCheckAttribute, self, { XRedPointConditions.Types.CONDITION_RIFT_ATTRIBUTE })
end

function XUiRiftChooseChapter:OnStart(param)
    self._Param = param
    local activityConfig = self._Control:GetCurrentConfig()
    self._GainRewardLuckyValue = activityConfig.GainRewardLuckyValue
    self._TimeAddValueToLucky = activityConfig.TimeAddValueToLucky
    self._TimeIntervalToLucky = activityConfig.TimeIntervalToLucky

    self:InitChapterGrid()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:UpdateLucky()
        end
    end, nil, 0)
end

function XUiRiftChooseChapter:OnEnable()
    self:UpdateRedPoint()
    -- 点击前往下一关时自动打开章节详情弹框
    local autoChapterId = self._Control:GetAutoOpenChapterDetail()
    if XTool.IsNumberValid(autoChapterId) then
        self._AutoOpenTimer = XScheduleManager.ScheduleOnce(function()
            self._Chapters[autoChapterId]:TryEnterChapter()
        end, 50)
    end
    self._Control:SetAutoOpenChapterDetail(nil)
    -- 刷新章节
    for _, grid in pairs(self._Chapters) do
        grid:Update()
    end

    if self._Param and self._Param.IsPlayScreenTween then
        self._Param.IsPlayScreenTween = false
        self:PlayAnimationWithMask("Enable")
    end
end

function XUiRiftChooseChapter:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.BtnAttributeRedEventId)
end

function XUiRiftChooseChapter:InitChapterGrid()
    ---@type XUiGridRiftChapter[]
    self._Chapters = {}
    local datas = self._Control:GetEntityChapter()
    local i = 1
    for _, chapter in pairs(datas) do
        local root = self[string.format("Chapter%s", i)]
        if XTool.UObjIsNil(root) then
            XLog.Error(string.format("节点Chapter%s不存在", i))
        else
            local isEndless = chapter:IsEndless()
            local grid = isEndless and self.GridEndlessChapter or self.GridChapter
            if i == 1 or isEndless then
                grid:SetParent(root, false)
            else
                grid = XUiHelper.Instantiate(grid, root)
            end
            local lastChapter = i > 1 and datas[i - 1] or nil
            self._Chapters[chapter:GetChapterId()] = require("XUi/XUiRift/Grid/XUiGridRiftChapter").New(grid, self, chapter, lastChapter, i)
        end
        i = i + 1
    end
end

function XUiRiftChooseChapter:UpdateLucky()
    local value = self._Control:GetLuckValue()
    local maxValue = self._Control:GetMaxLuckyValue()
    local progress = math.min(1, math.max(0, value / maxValue))
    self._RewardCount = math.floor(value / self._GainRewardLuckyValue)
    self.ImgRewardBar.fillAmount = progress
    self.RewardRed.gameObject:SetActiveEx(true)
    self.TxtRewardCount.text = string.format("%s/%s", value, maxValue)
    if progress >= 1 then
        self.TxtRewardTips.text = XUiHelper.GetText("RiftLuckyTip2")
    else
        local keepTime = XTime.GetServerNowTimestamp() - self._Control:GetSweepTick()
        local leftSeconds = self._TimeIntervalToLucky - keepTime % self._TimeIntervalToLucky
        local leftMinute = math.ceil(leftSeconds / 60) -- 秒转成分钟，不足一分钟显示为【1分钟后】，如果是1分30秒显示为【2分钟后】
        self.TxtRewardTips.text = XUiHelper.GetText("RiftLuckyTip1", leftMinute, self._TimeAddValueToLucky)
    end
    if (not self._LastProgress or self._LastProgress < 1) and progress >= 1 then
        -- 能量未满 → 能量满
        self:PlayAnimation("BtnMopupTiosEnable")
    elseif self._LastProgress and self._LastProgress >= 1 and progress < 1 then
        -- 能量满 → 能量未满
        self:PlayAnimation("BtnMopupTiosDisable")
    end
    self._LastProgress = progress
end

function XUiRiftChooseChapter:UpdateRedPoint()
    -- 任务按钮
    local isShowRed = self._Control:CheckTaskCanReward()
    self.BtnTask:ShowReddot(isShowRed)
    -- 属性加点按钮
    local isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    self.BtnAttribute:SetDisable(not isUnlock)
    XRedPointManager.Check(self.BtnAttributeRedEventId)
    -- 插件背包按钮
    local isPluginRed = self._Control:IsPluginBagRed()
    self.BtnPluginBag:ShowReddot(isPluginRed)
    -- 角色按钮
    self.BtnCharacter:ShowReddot(self._Control:GetCharacterRedPoint())
end

function XUiRiftChooseChapter:OnCheckAttribute(count)
    self.BtnAttribute:ShowReddot(count >= 0)
end

function XUiRiftChooseChapter:OnBtnTaskClick()
    XLuaUiManager.Open("UiRiftTask")
end

function XUiRiftChooseChapter:OnBtnPluginBagClick()
    XLuaUiManager.Open("UiRiftPluginBag")
end

function XUiRiftChooseChapter:OnBtnCharacterClick()
    XLuaUiManager.Open("UiRiftCharacter", nil, nil, nil, true)
end

function XUiRiftChooseChapter:OnBtnAttributeClick()
    local isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    if isUnlock then
        XLuaUiManager.Open("UiRiftAttribute")
    else
        local funcUnlockCfg = self._Control:GetFuncUnlockById(XEnumConst.Rift.FuncUnlockId.Attribute)
        XUiManager.TipError(funcUnlockCfg.Desc)
    end
end

function XUiRiftChooseChapter:OnBtnMopupClick()
    if self._RewardCount <= 0 then
        XUiManager.TipError(XUiHelper.GetText("RiftSweepTimesLimit"))
        return
    end

    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftSweepConfirm")
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:RiftSweepLayerRequest()
    end)
end

return XUiRiftChooseChapter