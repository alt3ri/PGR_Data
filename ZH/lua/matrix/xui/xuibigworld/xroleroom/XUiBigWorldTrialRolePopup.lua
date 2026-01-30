
---@class XUiBigWorldTrialRolePopup : XBigWorldUi
---@field BtnClose XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
---@field ImgRole UnityEngine.UI.RawImage
---@field TxtRole UnityEngine.UI.Text
local XUiBigWorldTrialRolePopup = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTrialRolePopup")

function XUiBigWorldTrialRolePopup:OnAwake()
    self._AutoCloseTimer = false
    self._Time = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("TrialRolePopupShowTime")

    self:_RegisterButtonClicks()
end

function XUiBigWorldTrialRolePopup:OnStart(characterId)
    self:_Refresh(characterId)
end

function XUiBigWorldTrialRolePopup:OnEnable()
    self:_RegisterAutoClose()
end

function XUiBigWorldTrialRolePopup:OnDisable()
    self:_RemoveAutoClose()
end

function XUiBigWorldTrialRolePopup:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldTrialRolePopup:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiBigWorldTrialRolePopup:_RegisterAutoClose()
    self:_RemoveAutoClose()

    self._AutoCloseTimer = XScheduleManager.ScheduleOnce(function()
        self._AutoCloseTimer = false
        self:Close()
    end, self._Time * XScheduleManager.SECOND)
end

function XUiBigWorldTrialRolePopup:_RemoveAutoClose()
    if self._AutoCloseTimer then
        XScheduleManager.UnSchedule(self._AutoCloseTimer)
        self._AutoCloseTimer = false
    end
end

function XUiBigWorldTrialRolePopup:_Refresh(characterId)
    self.TxtRole.text = XMVCA.XBigWorldCharacter:GetCharacterLogName(characterId)
    self.ImgRole:SetImage(XMVCA.XBigWorldCharacter:GetHalfBodyImage(characterId))
end

return XUiBigWorldTrialRolePopup
