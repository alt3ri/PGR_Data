local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldPhotographPopupAlbumGridSet : XUiNode
local XUiBigWorldPhotographPopupAlbumGridSet = XClass(XUiNode, "XUiBigWorldPhotographPopupAlbumGridSet")

function XUiBigWorldPhotographPopupAlbumGridSet:Ctor()
    self.BtnCheckBox:AddEventListener(handler(self, self.OnBtnCheckBoxClick))
    self.Slider.onValueChanged:AddListener(handler(self, self.OnSliderValueChanged))
end

function XUiBigWorldPhotographPopupAlbumGridSet:OnBtnCheckBoxClick()
    self._isSelect = not self._isSelect
    self.TagRecommend.gameObject:SetActive(self._IsRecommend and not self._isSelect)
    self.UiBigWorldRed.gameObject:SetActive(false)
    self._config.IsRedDot = false
    if self._cb then self._cb(self._isSelect, self) end
end

function XUiBigWorldPhotographPopupAlbumGridSet:OnSliderValueChanged(value)
    if self._silderCb then self._silderCb(value) end
end

function XUiBigWorldPhotographPopupAlbumGridSet:ShowSlider(value, isOn)
    if self.Slider then
        self.Slider.gameObject:SetActive(isOn)
        if isOn then
            self.Slider.value = value
        end
    end
end

function XUiBigWorldPhotographPopupAlbumGridSet:ResetData(config, i)
    self._config = config
    self._cb = config.Callback
    self._silderCb = config.SilderCallback
    self.TxtName.text = config.Name
    self._isSelect = config.IsOn
    self._IsRecommend = config.IsRecommend
    self.TagRecommend.gameObject:SetActive(self._IsRecommend and not self._isSelect)

    local isShowSlider = config.IsSlider or false
    self.PanelSliderDegree.gameObject:SetActive(isShowSlider)
    if isShowSlider then
        self.Slider.gameObject:SetActive(self._isSelect)
        self.Slider:SetValueWithoutNotify(config.BaseValue or 0.5)
    else
        self.Slider.gameObject:SetActive(false)
    end
    self.BtnCheckBox:SetButtonState(self._isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.UiBigWorldRed.gameObject:SetActive(config.IsRedDot or false)
end

return XUiBigWorldPhotographPopupAlbumGridSet
