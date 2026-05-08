---@class XUiBigWorldDIYGridPosition : XUiNode
---@field BtnClick XUiComponent.XUiButton
---@field ImgBg UnityEngine.UI.Image
---@field ImgPosition UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field PanelNow UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field ImgSelect UnityEngine.UI.Image
---@field PanelSuit UnityEngine.RectTransform
---@field PanelExclusive UnityEngine.RectTransform
---@field _Control XBigWorldCommanderDIYControl
---@field Parent XUiBigWorldDIY
local XUiBigWorldDIYGridPosition = XClass(XUiNode, "XUiBigWorldDIYGridPosition")

-- region 生命周期
function XUiBigWorldDIYGridPosition:OnStart()
    ---@type XBWCommanderDIYPartEntity
    self._Entity = false
    self._Index = 0
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self.GridEnable = self.Transform:FindTransform("GridEnable")
    self:_RegisterButtonClicks()
end

function XUiBigWorldDIYGridPosition:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldDIYGridPosition:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldDIYGridPosition:OnDestroy()
end
-- endregion

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYGridPosition:Refresh(entity, index)
    if not entity then
        return
    end

    self._Entity = entity
    self._Index = index
    self:_Refresh(entity, self.Parent:IsPlayAnimationsOneByOne())
end

function XUiBigWorldDIYGridPosition:RefreshCurrent()
    local entity = self._Entity
    self:_Refresh(entity, false)
end

function XUiBigWorldDIYGridPosition:SetSelect(isSelect, isPlayEnable)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self._Entity:Dress()
        self.Parent:ShowColor(self._Entity, isPlayEnable)
    end
end

function XUiBigWorldDIYGridPosition:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiBigWorldDIYGridPosition:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    self.CanvasGroup.alpha = 0
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        if self:IsNodeShow() then
            self.GridEnable:PlayTimelineAnimation()
        end
        self:StopAnimationTimer()
    end, 80 * index)
end

-- region 按钮事件

function XUiBigWorldDIYGridPosition:_ApplyDress(isIncompatible)
    self._Entity:Dress()
    self.Parent:ChangeSelect(self._Index, isIncompatible)
end

function XUiBigWorldDIYGridPosition:OnBtnClickClick()
    if self._Entity:IsIncompatible() then
        local currentEntity = self._Control:GetUsePartEntityByTypeId(self._Entity:GetTypeId())

        local outfitType = self._Control:GetCurrentModifiedOutfitType()
        local defaultPartId = XMVCA.XBigWorldCommanderDIY:GetTypeDefaultPartId(XEnumConst.PlayerFashion.PartType.Suit,
            outfitType)
        -- 默认部位为默认套装时，互斥仅提示不可穿戴
        if defaultPartId > 0 then
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("DIYDoNotSupportWearingTips"))
        else
            if currentEntity and currentEntity:IsSuit() then
                self:_ConfirmApplyDress("DIYChangeSuitTip")
            else
                self:_ConfirmApplyDress("DIYConfirmTakeOffToDefaultConflicts")
            end
        end
    else
        self:_ApplyDress()
    end
    self._Entity:Record()
    self:_RefreshRedDot(false)
    self.Parent:RefreshTabRedDot(self._Entity:GetTypeId())
    self.Parent:OpenPreview(self._Entity)
end

-- endregion

-- region 私有方法
function XUiBigWorldDIYGridPosition:_ConfirmApplyDress(textKey)
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText(textKey))
    confirmData:InitSureClick(nil, function()
        self:_ApplyDress(true)
    end)
    confirmData:InitToggleActive(true):InitKey("XUiBigWorldDIYGridPosition")
    if not XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData) then
        self:_ApplyDress(true)
    end
end

function XUiBigWorldDIYGridPosition:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldDIYGridPosition:_RefreshPanelNow(isNow)
    self.PanelNow.gameObject:SetActiveEx(isNow)
end

function XUiBigWorldDIYGridPosition:_RefreshEmpty(isEmpty)
    self.ImgPosition.gameObject:SetActiveEx(not isEmpty)
    self.PanelNone.gameObject:SetActiveEx(isEmpty)
end

function XUiBigWorldDIYGridPosition:_RefreshSuit(isSuit)
    if self.PanelSuit then
        self.PanelSuit.gameObject:SetActiveEx(isSuit)
    end
end

function XUiBigWorldDIYGridPosition:_RefreshExclusive(isExclusive)
    if self.PanelExclusive then
        self.PanelExclusive.gameObject:SetActiveEx(isExclusive)
    end
end

function XUiBigWorldDIYGridPosition:_RefreshPreview(isPreview)
    if self.PanelPreview then
        self.PanelPreview.gameObject:SetActiveEx(isPreview)
    end
end

function XUiBigWorldDIYGridPosition:_RefreshRedDot(isShow)
    if self.Red then
        self.Red.gameObject:SetActiveEx(isShow)
    end
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYGridPosition:_Refresh(entity, isPlayEnable)
    if not entity then
        return
    end

    self.TxtName.text = entity:GetName()
    if not entity:IsTemporary() then
        self.ImgPosition:SetSprite(entity:GetIcon())
    end
    self:SetSelect(entity:IsAttired(), isPlayEnable)
    self:_RefreshEmpty(entity:IsTemporary())
    self:_RefreshPanelNow(entity:IsNow())
    self:_RefreshSuit(entity:IsSuit())
    self:_RefreshExclusive(entity:IsIncompatible())
    self:_RefreshPreview(entity:IsPreview() and not entity:IsUnlock())
    self:_RefreshRedDot(entity:IsNew())
end

function XUiBigWorldDIYGridPosition:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldDIYGridPosition:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldDIYGridPosition:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldDIYGridPosition:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldDIYGridPosition:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end
-- endregion

return XUiBigWorldDIYGridPosition
