---@class XUiBWCursorSliderItem : XUiNode
---@field _Control XBigWorldSetControl
---@field Parent XUiBigWorldSetPanelFightPC
local XUiBWCursorSliderItem = XClass(XUiNode, "XUiBWCursorSliderItem")

---@param config XTableControllerMap
function XUiBWCursorSliderItem:OnStart(config)
    self:InitUi(config)
end

function XUiBWCursorSliderItem:OnSliderValueChanged(value)
    self.Parent:SetCursorMoveSensitivity(value)
end

function XUiBWCursorSliderItem:Update(config)
    if not self.Slider then
        self:InitUi(config)
    end
    if not self.Slider then
        return
    end
    local value = self.Parent:GetCursorMoveSensitivity()
    self.Slider.value = value
end

---@param config XTableControllerMap
function XUiBWCursorSliderItem:InitUi(config)
    self.Slider = XUiHelper.TryGetComponent(self.Transform, "CursorMoveSensitivity", "Slider")
    self.TxtTitle = XUiHelper.TryGetComponent(self.Transform, "TxtMusic", "Text")
    if self.Slider then
        XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSliderValueChanged)
    end
    if self.TxtTitle then
        self.TxtTitle.text = config.Title
    end
end

return XUiBWCursorSliderItem