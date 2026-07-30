--- 涂装打脸弹窗
---@class XUiPBRPopupSkin: XLuaUi
---@field protected _Control XPBRGameControl
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnReceive XUiComponent.XUiButton
---@field BtnWeaponSkin XUiComponent.XUiButton
local XUiPBRPopupSkin = XLuaUiManager.Register(XLuaUi, "UiPBRPopupSkin")

function XUiPBRPopupSkin:OnAwake()
    self:BindExitBtns(self.BtnTanchuangClose)
    self.BtnReceive:AddEventListener(handler(self, self.OnBtnReceiveClick))
    self.BtnWeaponSkin:AddEventListener(handler(self, self.OnBtnWeaponSkinClick))
end

function XUiPBRPopupSkin:OnStart()
    self._IsRequesting = false
    self:_RefreshState()
end

function XUiPBRPopupSkin:_RefreshState()
    local claimed = self._Control:IsSkinRewardClaimed()
    local achieved = self._Control:IsSkinTaskAchieved()

    if claimed then
        self.BtnReceive:SetButtonState(CS.UiButtonState.Disable)
    elseif achieved then
        self.BtnReceive:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnReceive:SetButtonState(CS.UiButtonState.Disable)
    end

    self.BtnReceive:ShowReddot(achieved)

end

function XUiPBRPopupSkin:OnBtnReceiveClick()
    if self._IsRequesting then
        return
    end
    if self._Control:IsSkinRewardClaimed() then
        return
    end
    if not self._Control:IsSkinTaskAchieved() then
        return
    end
    self._IsRequesting = true
    self._Control:RequestClaimSkinReward(function()
        self._IsRequesting = false
        self:_RefreshState()
    end)
end

function XUiPBRPopupSkin:OnBtnWeaponSkinClick()
    local tabIndex = self._Control:GetClientPBRNumber("PBRSkinTaskTabIndex")
    local focusTaskId = self._Control:GetClientPBRNumber("PBRSkinFocusTaskId")
    XLuaUiManager.Open("UiPBRTask", tabIndex, focusTaskId)
end

return XUiPBRPopupSkin
