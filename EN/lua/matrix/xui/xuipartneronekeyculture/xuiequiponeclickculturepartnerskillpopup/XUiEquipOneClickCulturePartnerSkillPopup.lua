local PanelState = {
    MainSkill = 1,
    PassiveSkill = 2,
    Element = 3,
}

---@class XUiEquipOneClickCulturePartnerSkillPopup : XLuaUi
---@field _Control XPartnerControl
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field PanelElement UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field GoMainSkill UnityEngine.RectTransform
---@field GoPassiveSkill UnityEngine.RectTransform
---@field BtnMainSkill XUiComponent.XUiButton
---@field BtnPassiveSkill XUiComponent.XUiButton
---@field GoSkillsTab UnityEngine.RectTransform
---@field GoTitle UnityEngine.RectTransform
---@field GoLine UnityEngine.RectTransform
local XUiEquipOneClickCulturePartnerSkillPopup = XLuaUiManager.Register(XLuaUi, "UiEquipOneClickCulturePartnerSkillPopup")

function XUiEquipOneClickCulturePartnerSkillPopup:OnAwake()
    self:InitComponents()
end

function XUiEquipOneClickCulturePartnerSkillPopup:InitComponents()
    self.BtnTanchuangClose:AddEventListener(function()
        self:OnBtnTanchuangCloseClick()
    end)
    self.BtnClose:AddEventListener(function()
        self:OnBtnCloseClick()
    end)
    self.BtnMainSkill:AddEventListener(function()
        self:OnBtnMainSkillClick()
    end)
    self.BtnPassiveSkill:AddEventListener(function()
        self:OnBtnPassiveSkillClick()
    end)
end

---@param partner XPartner|number
---@param initialSkillType number|nil
function XUiEquipOneClickCulturePartnerSkillPopup:OnStart(partner, initialSkillType)
    local XUiEquipOneClickCulturePartnerMainSkill = require("XUi/XUiPartnerOneKeyCulture/XUiEquipOneClickCulturePartnerSkillPopup/XUiEquipOneClickCulturePartnerMainSkill")
    local XUiEquipOneClickCulturePartnerPassiveSkill = require("XUi/XUiPartnerOneKeyCulture/XUiEquipOneClickCulturePartnerSkillPopup/XUiEquipOneClickCulturePartnerPassiveSkill")
    local XUiPanelElement = require("XUi/XUiPartner/PartnerSkillInstall/MainSkill/XUiPanelElement")

    self._SkillSelectControl = self._Control:GetSkillSelectViewControl()

    local partnerId = type(partner) == "number" and partner or partner and partner:GetId()
    if not partnerId or not self._SkillSelectControl:SetPartnerId(partnerId) then
        self:Close()
        return
    end

    self._MainSkillView = XUiEquipOneClickCulturePartnerMainSkill.New(self.GoMainSkill, self)
    self._PassiveSkillView = XUiEquipOneClickCulturePartnerPassiveSkill.New(self.GoPassiveSkill, self)
    self._MainSkillView:Open()
    self._PassiveSkillView:Open()
    self._ElementPanel = XUiPanelElement.New(self.PanelElement, self._MainSkillView)
    self._ElementPanel:HidePanel()

    XDataCenter.PartnerManager.MarkedNewSkillRed(partnerId)
    XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED)

    local skillType = self._Control:GetConfigControl():GetSkillType()
    self:_SwitchPanel(initialSkillType == skillType.PassiveSkill and PanelState.PassiveSkill or PanelState.MainSkill)
end

function XUiEquipOneClickCulturePartnerSkillPopup:OnEnable()
    self:_SetEvent(true)
end

function XUiEquipOneClickCulturePartnerSkillPopup:OnDisable()
    self:_SetEvent(false)
    self:_SetRequesting(false)
end

function XUiEquipOneClickCulturePartnerSkillPopup:OnDestroy()
end

---region ui event

function XUiEquipOneClickCulturePartnerSkillPopup:OnBtnTanchuangCloseClick()
    self:_CloseOrBack()
end

function XUiEquipOneClickCulturePartnerSkillPopup:OnBtnCloseClick()
    self:_CloseOrBack()
end

function XUiEquipOneClickCulturePartnerSkillPopup:OnBtnMainSkillClick()
    self:_SwitchPanel(PanelState.MainSkill)
end

function XUiEquipOneClickCulturePartnerSkillPopup:OnBtnPassiveSkillClick()
    self:_SwitchPanel(PanelState.PassiveSkill)
end

---endregion

---region event

function XUiEquipOneClickCulturePartnerSkillPopup:_SetEvent(flag)
    local eventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(eventId.EVENT_REPLY_PARTNER_SKILL_WEAR, self._OnSkillWearReply, self)
    else
        self._Control:RemoveEventListener(eventId.EVENT_REPLY_PARTNER_SKILL_WEAR, self._OnSkillWearReply, self)
    end
end

---@param isSuccess boolean
function XUiEquipOneClickCulturePartnerSkillPopup:_OnSkillWearReply(isSuccess)
    self:_SetRequesting(false)
    self:_Refresh()
end

---endregion

function XUiEquipOneClickCulturePartnerSkillPopup:_Refresh()
    if self._MainSkillView then
        self._MainSkillView:Refresh()
    end
    if self._PassiveSkillView then
        self._PassiveSkillView:Refresh()
    end

    self:_RefreshTabCount()
end

function XUiEquipOneClickCulturePartnerSkillPopup:_RefreshTabCount()
    local partner = self._SkillSelectControl:GetPartnerEntity()
    if not partner then
        return
    end

    local mainCount = #partner:GetCarryMainSkillGroupList()
    local passiveCount = #partner:GetCarryPassiveSkillGroupList()
    local passiveLimit = partner:GetQualitySkillColumnCount()

    self.BtnMainSkill:SetNameByGroup(1, string.format("%d/%d", mainCount, 1))
    self.BtnPassiveSkill:SetNameByGroup(1, string.format("%d/%d", passiveCount, passiveLimit))
    self.BtnPassiveSkill:ShowReddot(passiveCount < passiveLimit)
end



---@param panelState number
function XUiEquipOneClickCulturePartnerSkillPopup:_SwitchPanel(panelState)
    local isMain = panelState == PanelState.MainSkill
    local isPassive = panelState == PanelState.PassiveSkill
    self:_SetBtnStatusPro(self.BtnMainSkill, isMain and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self:_SetBtnStatusPro(self.BtnPassiveSkill, isPassive and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    if self._PanelState == panelState then
        return
    end

    self._PanelState = panelState

    self.GoSkillsTab.gameObject:SetActiveEx(true)
    self.GoTitle.gameObject:SetActiveEx(true)
    self.GoLine.gameObject:SetActiveEx(true)

    if isMain then
        self._MainSkillView:Open()
    else
        self._MainSkillView:Close()
    end

    if isPassive then
        self._PassiveSkillView:Open()
    else
        self._PassiveSkillView:Close()
    end

    self._ElementPanel:HidePanel()
    self:_RefreshTabCount()
end

function XUiEquipOneClickCulturePartnerSkillPopup:OpenElementView()
    self._PanelState = PanelState.Element
    self._MainSkillView:Close()
    self._PassiveSkillView:Close()
    self.GoSkillsTab.gameObject:SetActiveEx(false)
    self.GoTitle.gameObject:SetActiveEx(false)
    self.GoLine.gameObject:SetActiveEx(false)
    self._ElementPanel:UpdatePanel()
end

function XUiEquipOneClickCulturePartnerSkillPopup:SetRequesting(isRequesting)
    self:_SetRequesting(isRequesting)
end

function XUiEquipOneClickCulturePartnerSkillPopup:_SetRequesting(isRequesting)
    if isRequesting then
        if not self._IsRequesting then
            XLuaUiManager.SetMask(true)
            self._IsRequesting = true
        end
    elseif self._IsRequesting then
        XLuaUiManager.SetMask(false)
        self._IsRequesting = false
    end
end

function XUiEquipOneClickCulturePartnerSkillPopup:_CloseOrBack()
    if self._PanelState == PanelState.Element then
        self:_SwitchPanel(PanelState.MainSkill)
        return
    end

    self:Close()
end

function XUiEquipOneClickCulturePartnerSkillPopup:_SetBtnStatusPro(btnInstance, status)
    if btnInstance.ButtonState == status and btnInstance.TempState == status then
        return
    end

    btnInstance:SetButtonState(status)
    btnInstance.TempState = status
end

return XUiEquipOneClickCulturePartnerSkillPopup
