---@class XUiRacePopupSkin : XLuaUi 涂装赠送
---@field _Control XRaceControl
local XUiRacePopupSkin = XLuaUiManager.Register(XLuaUi, "UiRacePopupSkin")

function XUiRacePopupSkin:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnReceive.CallBack = handler(self, self.OnBtnReceiveClick)
end

function XUiRacePopupSkin:OnStart()
    self._IsSkinRewardGain = self._Control:IsSkinRewardGain()
    self.BtnReceive:SetButtonState(self._IsSkinRewardGain and XUiButtonState.Disable or XUiButtonState.Normal)
    self.RImgSkin:SetRawImage(self._Control:GetClientConfig("SkinPopupRoleIcon"))
    self.TxtSkinName.text = self._Control:GetClientConfig("SkinPopupRoleDesc", 1)
    self.TxtRoleName.text = self._Control:GetClientConfig("SkinPopupRoleDesc", 2)

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
end

function XUiRacePopupSkin:OnBtnReceiveClick()
    if self._IsSkinRewardGain then
        return
    end
    self._Control:RequestGainSkinReward(function()
        self:Close()
    end)
end

return XUiRacePopupSkin