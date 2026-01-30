---@class XUiGridRiftChapter : XUiNode 章节节点
---@field Parent XUiRiftChooseChapter
---@field _Control XRiftControl
local XUiGridRiftChapter = XClass(XUiNode, "XUiGridRiftChapter")

---@param chapter XRiftChapter
---@param lastChapter XRiftChapter
function XUiGridRiftChapter:OnStart(chapter, lastChapter, index)
    self._Index = index
    self._Chapter = chapter
    self._LastChapter = lastChapter
    self.GridChapter.CallBack = handler(self, self.TryEnterChapter)
    self.Transform.localPosition = CS.UnityEngine.Vector3.zero
end

function XUiGridRiftChapter:OnEnable()
    
end

function XUiGridRiftChapter:OnDestroy()
    self:RemoveTimer()
end

function XUiGridRiftChapter:Update()
    self:RemoveTimer()
    self._IsLock = self._Chapter:CheckHasLock()
    if self._IsLock then
        self.GridChapter:SetButtonState(CS.UiButtonState.Disable)
        if self._Chapter:IsEndless() then
            self.GridChapter:ShowReddot(false)
            return
        end
        if self._Chapter:CheckTimeLock() then
            self:CountDown()
            self._Timer = XScheduleManager.ScheduleForever(function()
                self:CountDown()
            end, XScheduleManager.SECOND, 0)
        elseif self._Chapter:CheckPreLock() then
            self.GridChapter:SetNameByGroup(2, XUiHelper.GetText("RiftChapterPreLimit"))
        end
        self.GridChapter:SetNameByGroup(3, string.format("0%s", self._Index))
    else
        local isPassed = self._Chapter:CheckHasPassed()
        local passTime = self._Chapter:GetPassTime()
        self.GridChapter:SetButtonState(CS.UiButtonState.Normal)
        self.GridChapter:SetNameByGroup(0, self._Chapter:GetConfig().Name)
        if isPassed then
            if self._Chapter:IsEndless() then
                self.GridChapter:SetNameByGroup(1, self._Chapter:GetScore())
            else
                self.GridChapter:SetNameByGroup(1, XUiHelper.GetTime(passTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
            end
        else
            self.GridChapter:SetNameByGroup(1, XUiHelper.GetText("RiftChapterUnpass"))
        end
        if self.Imgcomplete then
            self.Imgcomplete.gameObject:SetActiveEx(isPassed)
        end
        self.GridChapter:SetNameByGroup(3, XUiHelper.GetText("RiftChapterTimeDesc", self._Index))
    end
    self.GridChapter:SetSprite(self._Chapter:GetConfig().Icon)
    self.ImgNow.gameObject:SetActiveEx(self._Control:GetNewUnlockChapterId() == self._Chapter:GetChapterId())
    self:RefreshRedPoint()
end

function XUiGridRiftChapter:CountDown()
    local leftTime = self._Chapter:GetOpenLeftTime()
    if leftTime > 0 then
        local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
        local leftText = XUiHelper.GetText("RiftCountDownDesc4", leftTimeStr)
        self.GridChapter:SetNameByGroup(2, leftText)
    else
        self:Update()
    end
end

function XUiGridRiftChapter:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiGridRiftChapter:RefreshRedPoint()
    local isRed = self._Chapter:CheckRedPoint()
    self.GridChapter:ShowReddot(isRed)
end

function XUiGridRiftChapter:TryEnterChapter()
    if self._Chapter:CheckHasLock() then
        if self._Chapter:CheckPreLock() then
            XUiManager.TipError(XUiHelper.GetText("RiftChapterPreLimit"))
            return
        end
        if self._Chapter:CheckTimeLock() then
            XUiManager.TipError(XUiHelper.GetText("RiftChapterTimeLimit"))
            return
        end
    end

    XLuaUiManager.Open("UiRiftPopupChapterDetail", self._Chapter)
    self._Chapter:SaveFirstEnter()
    self:RefreshRedPoint()
end

return XUiGridRiftChapter