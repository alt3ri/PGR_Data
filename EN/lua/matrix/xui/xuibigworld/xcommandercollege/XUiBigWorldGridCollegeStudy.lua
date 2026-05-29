local XUiBigWorldGridCollegeStudy = XClass(nil, "XUiBigWorldGridCollegeStudy")
local IsThisTransformPlayAnim = false

function XUiBigWorldGridCollegeStudy:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetHasPlay(false)
    self.Grid:AddEventListener(handler(self, self.OnClickGrid))
end

function XUiBigWorldGridCollegeStudy:PlayEnableAnime(index)
    if self:GetHasPlay() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local rect = self.UseGrid
    local beforePlayPosY = rect.anchoredPosition.y
    local canvasGroup = self.UseGrid:GetComponent("CanvasGroup")
    canvasGroup.alpha = 0
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self.Transform) and self.GameObject.activeInHierarchy then
            self.Transform:Find("Animation/GridEnable"):PlayTimelineAnimation(function()
                canvasGroup.alpha = 1
                rect:SetAnchoredPosition(rect.anchoredPosition.x, beforePlayPosY) -- 播放完的回调也强设一遍目标值
            end)
            self:SetHasPlay(true)
        end
    end, (index - 1) * 95)
end

function XUiBigWorldGridCollegeStudy:SetHasPlay(flag)
    IsThisTransformPlayAnim = flag
end

function XUiBigWorldGridCollegeStudy:GetHasPlay()
    return IsThisTransformPlayAnim
end

function XUiBigWorldGridCollegeStudy:UpdateGrid(manager, index, currUseMinIndex)
    currUseMinIndex = currUseMinIndex or 1
    self:PlayEnableAnime(index - (currUseMinIndex - 1))
    self.Manager = manager
    self.TxtName.text = manager:ExGetName()
    self.RImgBg:SetRawImage(manager:ExGetIcon())
    self.PanelLock.gameObject:SetActiveEx(manager:ExGetIsLocked())
    self.TxtLock.text = manager:ExGetLockTip()

    local isShowTag, textTag = manager:ExGetTagInfo()
    self.PanelTag.gameObject:SetActiveEx(isShowTag)
    self.TextTag.text = textTag

    self:RefreshRedPoint()
end

function XUiBigWorldGridCollegeStudy:RefreshRedPoint()
    self.UiBigWorldRed.gameObject:SetActiveEx(self.Manager:ExCheckIsShowRedPoint())
end

function XUiBigWorldGridCollegeStudy:OnClickGrid()
    self.Manager:ExOpenMainUi()
end

return XUiBigWorldGridCollegeStudy
