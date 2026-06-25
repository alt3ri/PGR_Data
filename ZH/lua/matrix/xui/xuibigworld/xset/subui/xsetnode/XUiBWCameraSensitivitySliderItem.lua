---@class XUiBWCameraSensitivitySliderItem : XUiNode
---@field _Control XBigWorldSetControl
---@field Parent XUiBigWorldSetPanelFightPC
local XUiBWCameraSensitivitySliderItem = XClass(XUiNode, "XUiBWCameraSensitivitySliderItem")

---@param config XTableControllerMap
function XUiBWCameraSensitivitySliderItem:OnStart(config)
    self:InitUi(config)
end

function XUiBWCameraSensitivitySliderItem:OnSliderValueChanged(value)
    local lastValue = self.Parent:GetCameraMoveSensitivity(self._ViewType)
    if lastValue == value then
        return
    end
    self.Parent:SetCameraMoveSensitivity(value, self._ViewType)
end

function XUiBWCameraSensitivitySliderItem:Update(config)
    if not self.Slider then
        self:InitUi(config)
    end
    if not self.Slider then
        return
    end
    local value = self.Parent:GetCameraMoveSensitivity(self._ViewType)
    self.Slider.value = value
end

---@param config XTableControllerMap
function XUiBWCameraSensitivitySliderItem:InitUi(config)
    local viewType = config.DefaultKeyMapIds[1] or XMVCA.XBigWorldGamePlay.PerspectiveType.ThirdPerson
    self._ViewType = CS.CameraViewType.__CastFrom(viewType)
    self.Slider = XUiHelper.TryGetComponent(self.Transform, "SliderCameraMoveSensitivityPc", typeof(CS.UnityEngine.UI.Slider))
    if not self.Slider then
        self.Slider = XUiHelper.TryGetComponent(self.Transform, "SliderCameraMoveSensitivity", typeof(CS.UnityEngine.UI.Slider))
    end
    self.TxtTitle = XUiHelper.TryGetComponent(self.Transform, "TxtMusic", "Text")
    if self.Slider then
        XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSliderValueChanged)
    end
    if self.TxtTitle then
        self.TxtTitle.text = config.Title
    end
end

return XUiBWCameraSensitivitySliderItem