local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldPhotographPopupAlbumGridAnimation : XUiNode
local XUiBigWorldPhotographPopupAlbumGridAnimation = XClass(XUiNode, "XUiBigWorldPhotographPopupAlbumGridAnimation")

function XUiBigWorldPhotographPopupAlbumGridAnimation:Ctor()
    self.GridAction.CallBack = function() self:OnBtnGridActionClick() end
end

function XUiBigWorldPhotographPopupAlbumGridAnimation:OnBtnGridActionClick()
    if not self._IsUnlock then
        return
    end
    local cb = self.Parent.OnAnimSetClick
    if cb then cb(self.Parent, self._selectIndex) end
    self._Control:ReadUnlock(2, self._config.Id)
    self.GridAction:ShowReddot(false)
end

function XUiBigWorldPhotographPopupAlbumGridAnimation:ResetData(config, i)
    local isSelect = self.Parent:GetAnimationSelectIndex() == i
    self._selectIndex = i
    self._config = config
    self._IsUnlock, self._LockDesc = XMVCA.XBigWorldAlbum:IsUnlockCharacterActionId(config.Id)

    self.GridAction:SetName(config.Name)
    if self._IsUnlock then
        self.GridAction:SetButtonState(isSelect and XUiButtonState.Select or XUiButtonState.Normal)
        local _, isShowRedDot = self._Control:IsShowRedDotContent(2, config.Id)
        self.GridAction:ShowReddot(isShowRedDot and i ~= 1)
        if i == 1 then
            self._Control:ReadUnlock(2, self._config.Id)
        end
    else
        self.GridAction:SetButtonState(XUiButtonState.Disable)
        self.GridAction:ShowReddot(false)
        if self.TxtFilterLock then
            self.TxtFilterLock.text = self._LockDesc
        end
    end
end

return XUiBigWorldPhotographPopupAlbumGridAnimation
