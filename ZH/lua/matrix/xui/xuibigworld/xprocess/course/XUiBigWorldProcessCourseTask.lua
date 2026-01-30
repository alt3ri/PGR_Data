local XUiBWProcessAnimationBase = require("XUi/XUiBigWorld/XProcess/XUiBWProcessAnimationBase")

---@class XUiBigWorldProcessCourseTask : XUiBWProcessAnimationBase
---@field RImgIcon UnityEngine.UI.RawImage
---@field TxtRewardCount UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TxtCondition UnityEngine.UI.Text
---@field TxtDescribe UnityEngine.UI.Text
---@field TxtProgress UnityEngine.UI.Text
---@field BtnGo XUiComponent.XUiButton
---@field BtnFinish XUiComponent.XUiButton
---@field BtnOngoing XUiComponent.XUiButton
---@field ImgComplete UnityEngine.UI.Image
---@field TxtComplete UnityEngine.UI.Text
---@field TagNew UnityEngine.RectTransform
---@field PanelCondition UnityEngine.RectTransform
---@field TaskReceive UnityEngine.RectTransform
---@field BtnAllReceive XUiComponent.XUiButton
---@field Parent XUiBigWorldProcessCourse
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessCourseTask = XClass(XUiBWProcessAnimationBase, "XUiBigWorldProcessCourseTask")

function XUiBigWorldProcessCourseTask:OnStart()
    ---@type XBWCourseTaskEntity
    self._Entity = false
    ---@type XBWCourseContentEntity
    self._Content = false

    self:_InitUi()
    self:_RegisterButtonClicks()
    self:SetEnableAnimationName("GridTaskEnable")
end

function XUiBigWorldProcessCourseTask:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCourseTask:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCourseTask:OnDestroy()
end

function XUiBigWorldProcessCourseTask:OnBtnGoClick()
    if self._Entity:IsSkip() then
        local skipId = self._Entity:GetSkipId()

        XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
    end
end

function XUiBigWorldProcessCourseTask:OnBtnFinishClick()
    if self._Content then
        self._Control:FinishMultiTask(self._Content:GetTaskEntitys())
    end
end

function XUiBigWorldProcessCourseTask:OnBtnOngoingClick()
    XMVCA.XBigWorldUI:TipText("BigWorldCourseTaskSkipUnableTip")
end

function XUiBigWorldProcessCourseTask:OnBtnAllReceiveClick()
end

function XUiBigWorldProcessCourseTask:OnBtnRewardClick()
    self._Control:TryOpenRewardTips(self._Entity:GetRewardId())
end

---@param entity XBWCourseTaskEntity
---@param content XBWCourseContentEntity
function XUiBigWorldProcessCourseTask:Refresh(entity, content)
    self._Entity = entity
    self._Content = content
    self:_RefreshReward(entity:GetDisplayRewardData())
    self.TxtName.text = entity:GetTitle()
    self.TxtDescribe.text = entity:GetDescription()
    self.TxtProgress.text = entity:GetProgressText()
    self:_RefreshNewTag(entity)
    self:_RefreshState(entity)
    self:_RefreshUnlockText(entity:GetUnlockText())
end

function XUiBigWorldProcessCourseTask:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
    self.BtnFinish:AddEventListener(handler(self, self.OnBtnFinishClick))
    self.BtnOngoing:AddEventListener(handler(self, self.OnBtnOngoingClick))
    self.BtnAllReceive:AddEventListener(handler(self, self.OnBtnAllReceiveClick))
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, self.OnBtnRewardClick, true)
end

function XUiBigWorldProcessCourseTask:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCourseTask:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCourseTask:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCourseTask:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCourseTask:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCourseTask:_InitUi()
end

function XUiBigWorldProcessCourseTask:_RefreshReward(rewardData)
    if rewardData then
        local icon = rewardData.Icon
        local count = rewardData.Count

        if not string.IsNilOrEmpty(icon) then
            self.RImgIcon.gameObject:SetActiveEx(true)
            self.RImgIcon:SetImage(icon)
        else
            self.RImgIcon.gameObject:SetActiveEx(false)
        end

        self.TxtRewardCount.text = count
    else
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.TxtRewardCount.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldProcessCourseTask:_RefreshUnlockText(unlockText)
    if string.IsNilOrEmpty(unlockText) then
        if self.PanelCondition then
            self.PanelCondition.gameObject:SetActiveEx(false)
        end
    else
        if self.PanelCondition then
            self.PanelCondition.gameObject:SetActiveEx(true)
        end
        self.TxtCondition.text = unlockText
    end
end

---@param entity XBWCourseTaskEntity
function XUiBigWorldProcessCourseTask:_RefreshState(entity)
    local isFinish = entity:IsFinish()
    local isSkip = entity:IsSkip()
    local isActive = entity:IsActive()
    local isAchieved = entity:IsAchieved()
    
    self.ImgComplete.gameObject:SetActiveEx(isFinish)
    self.BtnOngoing.gameObject:SetActiveEx(isActive and not isSkip)
    self.BtnFinish.gameObject:SetActiveEx(isAchieved)
    self.BtnGo.gameObject:SetActiveEx(isActive and isSkip)
end

---@param entity XBWCourseTaskEntity
function XUiBigWorldProcessCourseTask:_RefreshNewTag(entity)
    self.TagNew.gameObject:SetActiveEx(entity:IsNew())
    entity:Record()
end

return XUiBigWorldProcessCourseTask
