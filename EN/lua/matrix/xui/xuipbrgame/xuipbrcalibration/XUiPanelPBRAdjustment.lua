--- 手动调节子界面节点
---@class XUiPanelPBRAdjustment : XUiNode
---@field protected _Control
---@field Parent
---@field BtnStress XUiComponent.XUiButton 重音按下
---@field BtnSub XUiComponent.XUiButton 偏差手动调节——向负方向调节 单位1
---@field BtnAdd XUiComponent.XUiButton 偏差手动调节——向正方向调节 单位1
---@field BtnSkip XUiComponent.XUiButton 隐藏圆点
---@field Slider XSlider 偏差手动调节——滑动条
---@field PanelRhythm @节拍视图
local XUiPanelPBRAdjustment = XClass(XUiNode, "XUiPanelPBRAdjustment")
local XUiPanelPBRRhythm = require("XUi/XUiPBRGame/XUiPBRCalibration/XUiPanelPBRRhythm")

function XUiPanelPBRAdjustment:OnStart()
    ---@type XUiPanelPBRRhythm
    self._PanelRhythm = XUiPanelPBRRhythm.New(self.PanelRhythm, self)

    self._YuanVisible = true
    self._IsUpdatingSlider = false

    self:InitSlider()
    self:InitButtons()
end

function XUiPanelPBRAdjustment:InitSlider()
    self.Slider.onValueChanged:AddListener(handler(self, self.OnSliderValueChanged))
end

function XUiPanelPBRAdjustment:InitButtons()
    self.BtnStress:AddEventListener(function() self:OnBtnStressClick() end)
    self.BtnAdd:AddEventListener(function() self:AdjustOffset(1) end)
    self.BtnSub:AddEventListener(function() self:AdjustOffset(-1) end)
    self.BtnSkip:AddEventListener(function() self:OnBtnSkipClick() end)
end

function XUiPanelPBRAdjustment:OnEnable()
    local calibrateCtrl = self._Control.CalibrateControl
    -- BGM 已在界面级播放，直接读取缓存数据
    local effectiveRange = calibrateCtrl:GetEffectiveRange()
    self._OffsetMin = -effectiveRange
    self._OffsetMax = effectiveRange

    local currentMs = calibrateCtrl:GetOffsetMs()
    self:UpdateSliderValue(currentMs)
    self._PanelRhythm:SetBaseOffset(currentMs)
    self._PanelRhythm:SetPlaying(true)
    self._PanelRhythm:SetYuanVisible(self._YuanVisible)
    self.BtnSkip:SetButtonState(self._YuanVisible and CS.UiButtonState.Normal or CS.UiButtonState.Select)
end

function XUiPanelPBRAdjustment:OnDisable()
end

--- Slider 值变化回调（value 为 0~1）
function XUiPanelPBRAdjustment:OnSliderValueChanged(value)
    if self._IsUpdatingSlider then
        return
    end
    local ms = XMath.ToInt(self._OffsetMin + value * (self._OffsetMax - self._OffsetMin))
    self._Control.CalibrateControl:SetOffsetMs(ms)
    self._PanelRhythm:SetBaseOffset(ms)

    self:_UpdateSliderValueShow(ms)
end

--- 偏移 ±delta ms
function XUiPanelPBRAdjustment:AdjustOffset(delta)
    local currentMs = self._Control.CalibrateControl:GetOffsetMs()
    local newMs = currentMs + delta
    self._Control.CalibrateControl:SetOffsetMs(newMs)
    -- 读回 clamp 后的实际值
    newMs = self._Control.CalibrateControl:GetOffsetMs()
    self:UpdateSliderValue(newMs)
    self._PanelRhythm:SetBaseOffset(newMs)
end

function XUiPanelPBRAdjustment:OnBtnStressClick()
    self._PanelRhythm:ShowShadow()
    
    -- 辅助日志
    local calibrateCtrl = self._Control.CalibrateControl
    local beatDiff = calibrateCtrl:GetNearestBeatDiff() or 0
    local offsetMs = calibrateCtrl:GetOffsetMs() or 0
    
    XLog.Debug(string.format("[战双兄弟] 手动校准结果. 距离重音的偏差: %sms, 距离校准点的偏差: %sms (校准偏移: %sms)", tostring(beatDiff), tostring(beatDiff - offsetMs), tostring(offsetMs)))
end

function XUiPanelPBRAdjustment:OnBtnSkipClick()
    self._YuanVisible = not self._YuanVisible
    self._PanelRhythm:SetYuanVisible(self._YuanVisible)
    self.BtnSkip:SetButtonState(self._YuanVisible and CS.UiButtonState.Normal or CS.UiButtonState.Select)
end

--- 根据 ms 值更新 Slider 位置（带防重入保护）
function XUiPanelPBRAdjustment:UpdateSliderValue(ms)
    local range = self._OffsetMax - self._OffsetMin
    if range <= 0 then
        return
    end
    self._IsUpdatingSlider = true
    self.Slider.value = (ms - self._OffsetMin) / range
    self._IsUpdatingSlider = false
    
    self:_UpdateSliderValueShow(ms)
end

function XUiPanelPBRAdjustment:_UpdateSliderValueShow(ms)
    if self.TxtSliderVal then
        self.TxtSliderVal.text = ms
    end
end

return XUiPanelPBRAdjustment
