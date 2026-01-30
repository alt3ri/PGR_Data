local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldPhotographPopupAlbumGridFilter : XUiNode
local XUiBigWorldPhotographPopupAlbumGridFilter = XClass(XUiNode, "XUiBigWorldPhotographPopupAlbumGridFilter")

function XUiBigWorldPhotographPopupAlbumGridFilter:Ctor()
    self.GridFilter.CallBack = function() self:OnBtnGridFilterClick() end
end

function XUiBigWorldPhotographPopupAlbumGridFilter:OnBtnGridFilterClick()
    if not self._IsUnlock then
        return
    end
    local cb = self.Parent.OnFilterSetClick
    if cb then cb(self.Parent, self._selectIndex) end
    self._Control:ReadUnlock(3, self._config.Id)
    self.GridFilter:ShowReddot(false)
end

function XUiBigWorldPhotographPopupAlbumGridFilter:ResetData(config, i)
    self._selectIndex = i
    self._config = config
    local isSelect = self.Parent:GetFilterSelectIndex() == i

    self._IsUnlock, self._LockDesc = XMVCA.XBigWorldAlbum:IsUnlockFilterId(config.Id)

    self.GridFilter:SetName(config.Name)
    if self._IsUnlock then
        self.GridFilter:SetButtonState(isSelect and XUiButtonState.Select or XUiButtonState.Normal)
        local _, isShowRedDot = self._Control:IsShowRedDotContent(3, config.Id)
        self.GridFilter:ShowReddot(isShowRedDot and i ~= 1)
        if i == 1 then
            self._Control:ReadUnlock(3, self._config.Id)
        end
    else
        self.GridFilter:SetButtonState(XUiButtonState.Disable)
        self.GridFilter:ShowReddot(false)
        if self.TxtFilterLock then
            self.TxtFilterLock.text = self._LockDesc
        end
    end

    local isShowImage = not string.IsNilOrEmpty(config.Icon)
    if isShowImage then
        self.GridFilter:SetRawImage(config.Icon)
    end
end

return XUiBigWorldPhotographPopupAlbumGridFilter
