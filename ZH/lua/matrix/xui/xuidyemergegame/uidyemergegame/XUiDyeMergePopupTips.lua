--- 局内弹窗提示
---@class XUiDyeMergePopupTips: XLuaUi
---@field protected _Control XDyeMergeGameControl
local XUiDyeMergePopupTips = XLuaUiManager.Register(XLuaUi, "UiDyeMergePopupTips")

--region Ui生命周期

function XUiDyeMergePopupTips:OnAwake()
    self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.Close))

    if self.BtnTips then
        self.BtnTips:AddEventListener(handler(self, self.OnBtnTipsClick))
    end
end

function XUiDyeMergePopupTips:OnStart(tipsImg)
    self.RImgTips:SetRawImage(tipsImg)

    local isOpen = self._Control.GamingControl:GetIsTipsSmallWindowOpen()

    self:_RefreshBtnTipsState(isOpen)
end

--endregion

function XUiDyeMergePopupTips:OnBtnTipsClick()
    local isOpen = self._Control.GamingControl:GetIsTipsSmallWindowOpen()
    
    isOpen = not isOpen
    
    self._Control.GamingControl:SetIsTipsSmallWindowOpen(isOpen)
    
    self:_RefreshBtnTipsState(isOpen)
    
    self._Control.GamingControl:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_REFRESH_TIPS_WINDOW)
end

function XUiDyeMergePopupTips:_RefreshBtnTipsState(isOpen)
    self.BtnTips:SetButtonState(isOpen and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiDyeMergePopupTips