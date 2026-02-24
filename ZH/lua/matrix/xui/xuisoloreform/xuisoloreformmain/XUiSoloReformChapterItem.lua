---@class XUiSoloReformChapterItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterItem = XClass(XUiNode, 'XUiSoloReformChapterItem')

function XUiSoloReformChapterItem:OnStart()
    self._ChapterCfg = nil
    self._IsUnlock = nil
    self._TimerId = nil
    XUiHelper.RegisterClickEvent(self, self.BtnGridChapter, self.OnClickChapter, true, true, 0.5)
end

function XUiSoloReformChapterItem:GetColor()
    return "#6AC5FA"
end

function XUiSoloReformChapterItem:Update(chapterCfg)
    self._ChapterCfg = chapterCfg
    self.BtnGridChapter:SetNameByGroup(0, chapterCfg.Title)
    self.BtnGridChapter:SetNameByGroup(2, XUiHelper.GetText("SoloReformTimeShowNoPass"))
    self.RImgCharacterHead:SetRawImage(chapterCfg.Img)
    local completedCount, totalCount = self._Control:GetChapterCompletedTaskCountAndTotal(chapterCfg.Id)
    local isAllPass = totalCount > 0 and completedCount == totalCount
    
    self.BtnGridChapter:SetNameByGroup(1, string.format("<color=%s>%d</color>/%d", self:GetColor(), completedCount, totalCount))
    local minPassTime = self._Control:GetChapterStageMinPassTime(chapterCfg.Id)
    if not string.IsNilOrEmpty(minPassTime) then
        self.BtnGridChapter:SetNameByGroup(2, minPassTime)
    end
    self._IsUnlock = XFunctionManager.CheckInTimeByTimeId(chapterCfg.OpenTime, true)
    self.ImgClear.gameObject:SetActiveEx(isAllPass)
    self.PressImgClear.gameObject:SetActiveEx(isAllPass)
    --self.PanelLock.gameObject:SetActiveEx(not self._IsUnlock)
    self.BtnGridChapter:SetDisable(not self._IsUnlock)
    if not self._IsUnlock then
        self:StopTimer()
        self:UpdateChapterTime()
        self._TimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateChapterTime), XScheduleManager.SECOND)
    end
    self._ChapterReddotId = self:AddRedPointEvent(self.BtnGridChapter, self.OnChapterReddotEvent, self, 
        { XRedPointConditions.Types.CONDITION_SOLO_REFORM_CHAPTER }, chapterCfg.Id, true)    
end

function XUiSoloReformChapterItem:OnChapterReddotEvent(count)
    self.BtnGridChapter:ShowReddot(count >= 0)
end

function XUiSoloReformChapterItem:UpdateChapterTime()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self._ChapterCfg.OpenTime)
    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(startTime - now, 0)
    local timeText = XUiHelper.GetText("ReformBaseStageUnlockText", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    self.BtnGridChapter:SetNameByGroup(3, timeText)
    if leftTime <= 0 then
        self:StopTimer()
        self:Update(self._ChapterCfg)
    end    
end

function XUiSoloReformChapterItem:StopTimer()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
end

function XUiSoloReformChapterItem:OnClickChapter()
    if not self._IsUnlock then
        return
    end
    self._Control:DispatchEvent(XMVCA.XSoloReform.EventId.EVENT_CLICK_CHAPTER, self._ChapterCfg.Id)    
end

function XUiSoloReformChapterItem:OnDestroy()
    self:StopTimer()
    self._ChapterCfg  = nil
    self._IsUnlock = nil
end

return XUiSoloReformChapterItem