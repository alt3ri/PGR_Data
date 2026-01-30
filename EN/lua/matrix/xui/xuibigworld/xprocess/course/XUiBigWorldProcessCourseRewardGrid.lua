local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldProcessCourseRewardGrid : XUiNode
---@field Effect UnityEngine.RectTransform
---@field PanelReceive UnityEngine.RectTransform
---@field GridCommon UnityEngine.RectTransform
---@field BtnClick XUiComponent.XUiButton
---@field Parent XUiBigWorldProcessCourseReward
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessCourseRewardGrid = XClass(XUiNode, "XUiBigWorldProcessCourseRewardGrid")

function XUiBigWorldProcessCourseRewardGrid:OnStart()
    ---@type XBWCourseTaskProgressEntity
    self._Entity = false
    ---@type XUiGridBWItem
    self._Grid = false
    self._SpecialEffect = self.GridCommon:FindTransform("Effect")
    self._ClickHandler = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCourseRewardGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
    self:PlayAnimation("SpecialRewardGridEnable", Handler(self, self._RefreshSpecialEffect))
end

function XUiBigWorldProcessCourseRewardGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCourseRewardGrid:OnDestroy()
end

function XUiBigWorldProcessCourseRewardGrid:OnRewardClick()
    if self._Entity then
        if not self._Entity:IsAcquired() and self._Entity:IsComplete() then
            self._Control:RequestBigWorldCourseTaskCntGetReward(self._Entity:GetVersionId())
        else
            self._Control:TryOpenRewardTips(self._Entity:GetRewardId())
        end
    end
end

---@param progressEntity XBWCourseTaskProgressEntity
function XUiBigWorldProcessCourseRewardGrid:Refresh(progressEntity, reward)
    self._Entity = progressEntity
    self:_RefreshReward(reward)
    self:_RefreshState(progressEntity)
end

function XUiBigWorldProcessCourseRewardGrid:PlayDisableAnimation()
    if self:IsNodeShow() then
        self:PlayAnimation("SpecialRewardGridDisable")
    end
end

function XUiBigWorldProcessCourseRewardGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnClick:AddEventListener(handler(self, self.OnRewardClick))
end

function XUiBigWorldProcessCourseRewardGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCourseRewardGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCourseRewardGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCourseRewardGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCourseRewardGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCourseRewardGrid:_InitUi()
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiBigWorldProcessCourseRewardGrid:_RefreshReward(reward)
    if not self._Grid then
        self._Grid = XUiGridBWItem.New(self.GridCommon, self, Handler(self, self.OnRewardClick))
    end

    self._Grid:Open()
    self._Grid:Refresh(reward)
end

---@param entity XBWCourseTaskProgressEntity
function XUiBigWorldProcessCourseRewardGrid:_RefreshState(entity)
    local isAcquired = entity:IsAcquired()

    self.Effect.gameObject:SetActiveEx(entity:IsComplete() and not isAcquired)
    self.PanelReceive.gameObject:SetActiveEx(isAcquired)
    self:_RefreshSpecialEffect()
end

function XUiBigWorldProcessCourseRewardGrid:_RefreshSpecialEffect()
    if self._SpecialEffect then
        if self._Entity then
            local isAcquired = self._Entity:IsAcquired()

            self._SpecialEffect.gameObject:SetActiveEx(not isAcquired)
        end
    end
end

return XUiBigWorldProcessCourseRewardGrid
