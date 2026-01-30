---@class XUiCollectionTeachGrid : XUiNode
---@field BtnFirst XUiComponent.XUiButton
---@field TeachRed UnityEngine.RectTransform
---@field Parent XUiBigWorldTeachMain
---@field _Control XHelpCourseControl
local XUiCollectionTeachGrid = XClass(XUiNode, "XUiCollectionTeachGrid")

function XUiCollectionTeachGrid:OnStart()
    self._Id = 0
    self._Index = 0

    self:_RegisterButtonClicks()
end

---@param config XTableHelpCourse
function XUiCollectionTeachGrid:Refresh(config, index, isSelect, searchKey)
    local name = config.Name

    self.BtnFirst:SetNameByGroup(0, name)

    self._Index = index
    self._Id = config.Id

    self:SetIsSelect(isSelect)
    -- 默认隐藏，目前没有蓝点需求
    self:_ShowReddot(false)

    if isSelect then
        self.Parent:ChangeSelect(index, self._Id)
    end
end

function XUiCollectionTeachGrid:OnDisable()
    self:StopAnimationTimer()
end

function XUiCollectionTeachGrid:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiCollectionTeachGrid:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    self.CanvasGroup.alpha = 0
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        self.BtnFirstEnable:PlayTimelineAnimation()
        self:StopAnimationTimer()
    end, 100 * index)
end

function XUiCollectionTeachGrid:SetIsSelect(isSelect)
    if isSelect then
        self.BtnFirst:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnFirst:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiCollectionTeachGrid:OnBtnFirstClick()
    self:SetIsSelect(true)
    self:_ShowReddot(false)
    self.Parent:ChangeSelect(self._Index, self._Id)
end

function XUiCollectionTeachGrid:_RegisterButtonClicks()
    self.BtnFirst.CallBack = Handler(self, self.OnBtnFirstClick)
end

function XUiCollectionTeachGrid:_ShowReddot(isActive)
    self.TeachRed.gameObject:SetActiveEx(isActive)
end

return XUiCollectionTeachGrid
