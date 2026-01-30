local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldPhotographPopupAlbumGridSet : XUiNode
local XUiBigWorldPhotographPopupAlbumGridSet = XClass(XUiNode, "XUiBigWorldPhotographPopupAlbumGridSet")

function XUiBigWorldPhotographPopupAlbumGridSet:Ctor()
    self.BtnCheckBox:AddEventListener(handler(self, self.OnBtnCheckBoxClick))
end

function XUiBigWorldPhotographPopupAlbumGridSet:OnBtnCheckBoxClick()
    self._isSelect = not self._isSelect
    if self._cb then self._cb(self._isSelect) end
end

function XUiBigWorldPhotographPopupAlbumGridSet:ResetData(config, i)
    self._cb = config.Callback
    self.TxtName.text = config.Name
    self._isSelect = config.IsOn
    self.BtnCheckBox:SetButtonState(self._isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiBigWorldPhotographPopupAlbumGridSet
