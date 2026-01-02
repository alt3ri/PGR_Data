---@class XUiGridDlcRelinkChooseBoss : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkChooseBoss
local XUiGridDlcRelinkChooseBoss = XClass(XUiNode, "XUiGridDlcRelinkChooseBoss")

function XUiGridDlcRelinkChooseBoss:OnStart(chapterId)
    self.BtnSelect:AddEventListener(handler(self, self.OnBtnSelectClick))
    self.ChapterId = chapterId
    self.IsShowTime = false
end

function XUiGridDlcRelinkChooseBoss:Refresh()
    local chapterIcon = self._Control:GetChapterIcon(self.ChapterId)
    if not string.IsNilOrEmpty(chapterIcon) then
        self.RImgBoss:SetRawImage(chapterIcon)
    end
    local isUnLock = self._Control:CheckChapterUnlock(self.ChapterId)
    self.BossName.gameObject:SetActiveEx(isUnLock)
    self.RawImgLock.gameObject:SetActiveEx(not isUnLock)
    if isUnLock then
        self.Txt.text = self._Control:GetChapterName(self.ChapterId)
        self.TxtLock.text = ""
        self.IsShowTime = false
        return
    end

    local timeId = self._Control:GetChapterTimeId(self.ChapterId)
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    self.IsShowTime = timeId > 0 and nowTime < startTime

    if self.IsShowTime then
        self:RefreshTime()
    else
        self.TxtLock.text = self._Control:GetChapterConditionDesc(self.ChapterId)
    end
end

function XUiGridDlcRelinkChooseBoss:RefreshTime()
    if not self.IsShowTime then
        return
    end
    local timeId = self._Control:GetChapterTimeId(self.ChapterId)
    if not XTool.IsNumberValid(timeId) then
        self.IsShowTime = false
        return
    end

    local remainTime = XFunctionManager.GetStartTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
    if remainTime <= 0 then
        self.IsShowTime = false
        self:Refresh()
        return
    end

    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self.TxtLock.text = string.format(self._Control:GetClientConfig("ChapterCountDownDesc"), timeStr)
end

function XUiGridDlcRelinkChooseBoss:RefreshRedPoint()
    local isShowRedPoint = self._Control:CheckChapterHasAnyNewLevel(self.ChapterId)
    self.Red.gameObject:SetActiveEx(isShowRedPoint)
end

function XUiGridDlcRelinkChooseBoss:SetSelect(isSelect)
    self.RImgSelect.gameObject:SetActiveEx(isSelect)
    self.Parent.PanelDrag.gameObject:SetActiveEx(not isSelect) --拖动组件会挡住弹框的关闭按钮
end

function XUiGridDlcRelinkChooseBoss:OnBtnSelectClick()
    if not XTool.IsNumberValid(self.ChapterId) then
        return
    end
    self.Parent:OnBtnChapterGridClick(self.ChapterId)
end

return XUiGridDlcRelinkChooseBoss
