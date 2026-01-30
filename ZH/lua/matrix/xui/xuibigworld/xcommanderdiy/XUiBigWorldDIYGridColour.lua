---@class XUiBigWorldDIYGridColour : XUiNode
---@field BtnClick XUiComponent.XUiButton
---@field ImgColour UnityEngine.UI.Image
---@field PanelNow UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field ImgSelect UnityEngine.UI.Image
---@field _Control XBigWorldCommanderDIYControl
---@field Parent XUiSkyGardenDIY
local XUiBigWorldDIYGridColour = XClass(XUiNode, "XUiBigWorldDIYGridColour")

-- region 生命周期

function XUiBigWorldDIYGridColour:OnStart()
    ---@type XBWCommanderDIYColorEntity
    self._Entity = false
    self.GridEnable = self.Transform:FindTransform("GridEnable")
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self:_RegisterButtonClicks()
end

function XUiBigWorldDIYGridColour:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldDIYGridColour:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldDIYGridColour:OnDestroy()

end

-- endregion

---@param entity XBWCommanderDIYColorEntity
function XUiBigWorldDIYGridColour:Refresh(entity, partId)
    if not entity or entity:IsNil() then
        return
    end

    self._Entity = entity
    self.ImgColour:SetSprite(entity:GetIcon())
    self.PanelNow.gameObject:SetActiveEx(self._Control:CheckColorEntityIsNow(entity))
    self:SetSelect(self._Control:CheckColorEntityIsUse(entity))
end

function XUiBigWorldDIYGridColour:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiBigWorldDIYGridColour:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiBigWorldDIYGridColour:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    self.CanvasGroup.alpha = 0
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        if self:IsNodeShow() then
            self.GridEnable:PlayTimelineAnimation()
        end
        self:StopAnimationTimer()
    end, 50 * index)
end

-- region 按钮事件

function XUiBigWorldDIYGridColour:OnBtnClickClick()
    self._Control:SetUsePartColorEntity(self._Entity)
    self.Parent:ChangeSelectColor(self, self._Entity)
    self:SetSelect(true)
end
-- endregion

-- region 私有方法

function XUiBigWorldDIYGridColour:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldDIYGridColour:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldDIYGridColour:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldDIYGridColour:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldDIYGridColour:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldDIYGridColour:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

return XUiBigWorldDIYGridColour
