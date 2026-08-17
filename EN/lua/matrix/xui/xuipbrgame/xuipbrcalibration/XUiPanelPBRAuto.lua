--- 自动调节子界面节点
---@class XUiPanelPBRAuto : XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field BtnStress XUiComponent.XUiButton 重音按下
---@field BtnUse XUiComponent.XUiButton 应用偏差值
---@field BtnReset XUiComponent.XUiButton 重置偏差值到默认值
---@field TxtTitle @采样阶段标题
---@field TxtRecommend @完成阶段推荐文案
---@field ImgDot @自动校准进度圆点
---@field PanelRhythm @节拍视图
local XUiPanelPBRAuto = XClass(XUiNode, "XUiPanelPBRAuto")
local XUiPanelPBRRhythm = require("XUi/XUiPBRGame/XUiPBRCalibration/XUiPanelPBRRhythm")

-- 三种 UI 状态
local State = {
    Sampling = 1,       -- 正在采样
    Complete = 2,       -- 本轮采样完成，等待应用
    Calibrated = 3,     -- 已有自动校准结果，等待用户决定是否重新校准
}

function XUiPanelPBRAuto:OnStart()
    ---@type XUiPanelPBRRhythm
    self._PanelRhythm = XUiPanelPBRRhythm.New(self.PanelRhythm, self)
    if self._PanelRhythm.ImgYuan then
        self._PanelRhythm.ImgYuan.gameObject:SetActiveEx(false)
    end

    self._Samples = {}
    self._SampleCount = 0
    self._MaxSampleCount = self._Control:GetClientPBRNumber("CalibrateAutoSampleCount") or 8
    self._State = State.Sampling

    self._RefreshDotCallback = function(index, ui)
        if ui.ImgGou then
            ui.ImgGou.gameObject:SetActiveEx(index <= self._SampleCount)
        end
    end

    self:InitButtons()
    self:RefreshDots()
end

function XUiPanelPBRAuto:OnEnable()
    local calibrateCtrl = self._Control.CalibrateControl
    local isComplete = self:_IsComplete()

    if isComplete then
        self._State = State.Complete
    elseif calibrateCtrl:HasAutoCalibrated() and #self._Samples == 0 then
        -- 已有历史自动校准，且本轮未开始采样 → 等待用户主动触发
        self._State = State.Calibrated
    else
        -- 从未自动校准 或 采样进行中 → 进入采样流程
        self._State = State.Sampling
    end

    self._PanelRhythm:SetPlaying(self._State == State.Sampling)
    self._PanelRhythm:SetYuanVisible(false)

    if self._State == State.Complete then
        self._PanelRhythm:SetBaseOffset(self:_CalcAverageOffset())
    elseif self._State == State.Calibrated then
        local savedResult = calibrateCtrl:GetAutoCalibrationResult()
        self._PanelRhythm:SetBaseOffset(savedResult or calibrateCtrl:GetOffsetMs())
    elseif #self._Samples == 0 then
        self._PanelRhythm:SetBaseOffset(calibrateCtrl:GetOffsetMs())
    else
        self._PanelRhythm:SetBaseOffset(0)
    end
    self:RefreshGroupState()
end

function XUiPanelPBRAuto:OnDisable()
    -- 切走时清空未完成的采样（HasAutoCalibrated 标记持久化，OnEnable 会重新判定状态）
    self._Samples = {}
    self:RefreshDots()
end

function XUiPanelPBRAuto:InitButtons()
    self.BtnStress:AddEventListener(function() self:OnBtnStressClick() end)
    self.BtnUse:AddEventListener(function() self:OnBtnUseClick() end)
    self.BtnReset:AddEventListener(function() self:OnBtnResetClick() end)
end

function XUiPanelPBRAuto:OnBtnStressClick()
    if self._State ~= State.Sampling then
        return
    end
    if #self._Samples >= self._MaxSampleCount then
        return
    end
    local diff = self._Control.CalibrateControl:GetNearestBeatDiff()
    if not diff then
        return
    end
    table.insert(self._Samples, diff)
    self:RefreshDots()
    self._PanelRhythm:ShowShadow()
    if self:_IsComplete() then
        self:_LogRecommendOffset()
        self._State = State.Complete
        local avgOffset = self:_CalcAverageOffset()
        self._Control.CalibrateControl:SetAutoCalibrationResult(avgOffset)
        self._PanelRhythm:SetPlaying(false)
        self._PanelRhythm:SetBaseOffset(avgOffset)
    end
    self:RefreshGroupState()
end

function XUiPanelPBRAuto:OnBtnUseClick()
    local calibrateCtrl = self._Control.CalibrateControl
    if self._State == State.Complete then
        local avg = self:_CalcAverageOffset()
        calibrateCtrl:SetOffsetMs(avg)
        calibrateCtrl:MarkAutoCalibrated()
        self._PanelRhythm:SetBaseOffset(avg)
    elseif self._State == State.Calibrated then
        local savedResult = calibrateCtrl:GetAutoCalibrationResult()
        calibrateCtrl:SetOffsetMs(savedResult)
        self._PanelRhythm:SetBaseOffset(savedResult)
    else
        return
    end
    self._State = State.Calibrated
    self:RefreshGroupState()
    XUiManager.TipMsg(self._Control:GetClientPBRText("CalibrateAutoResultApplyTips"))
end

--- 重置/重新校准（Complete 态：重置偏移归零重来；Calibrated 态：重新开始采样）
function XUiPanelPBRAuto:OnBtnResetClick()
    if self._State == State.Complete then
        self._Control.CalibrateControl:SetOffsetMs(0)
    end
    self._Samples = {}
    self._State = State.Sampling
    self:RefreshDots()
    self:RefreshGroupState()
    self._PanelRhythm:SetPlaying(true)
    self._PanelRhythm:SetYuanVisible(false)
    self._PanelRhythm:SetBaseOffset(0)
end

function XUiPanelPBRAuto:_IsComplete()
    return #self._Samples >= self._MaxSampleCount
end

function XUiPanelPBRAuto:_CalcAverageOffset()
    if #self._Samples == 0 then
        return 0
    end
    local sum = 0
    for _, v in ipairs(self._Samples) do
        sum = sum + v
    end
    return XMath.ToInt(sum / #self._Samples)
end

function XUiPanelPBRAuto:_LogRecommendOffset()
    local avg = self:_CalcAverageOffset()
    XLog.Debug(string.format("[战双兄弟]节拍自动校准完成. 采样次数: %d, 推荐标准偏移: %dms, 各采样偏移: %s",
            #self._Samples, avg, table.concat(self._Samples, ", ")))
end

--- 刷新三组 UI 的互斥显示
function XUiPanelPBRAuto:RefreshGroupState()
    local state = self._State
    -- 采样中：TxtTitle + BtnStress
    self.TxtTitle.gameObject:SetActiveEx(state == State.Sampling)
    self.BtnStress.gameObject:SetActiveEx(state == State.Sampling)
    -- 采样完成：TxtRecommend + BtnUse + BtnReset
    local isComplete = state == State.Complete or state == State.Calibrated
    self.TxtRecommend.gameObject:SetActiveEx(isComplete)
    self.BtnUse.gameObject:SetActiveEx(isComplete)
    self.BtnReset.gameObject:SetActiveEx(isComplete)
    -- Calibrated 态：显示当前偏移 + BtnReset 作为"重新校准"
    if state == State.Complete then
        local tipsFmt = self._Control:GetClientPBRText("CalibrateAutoResultTips")
        self.TxtRecommend.text = XUiHelper.FormatTextEx(tipsFmt or "%dms", self:_CalcAverageOffset())
    elseif state == State.Calibrated then
        local savedResult = self._Control.CalibrateControl:GetAutoCalibrationResult()
        local tipsFmt = self._Control:GetClientPBRText("CalibrateAutoResultTips")
        self.TxtRecommend.text = XUiHelper.FormatTextEx(tipsFmt or "%dms", savedResult or 0)
    end
end

--- 刷新进度圆点显示（ImgDot 下的子节点）
function XUiPanelPBRAuto:RefreshDots()
    self._SampleCount = #self._Samples

    self._ImgDotsUiList = XUiHelper.RefreshUiObjectList(self._ImgDotsUiList, self.ImgDot.transform.parent, self.ImgDot, self._MaxSampleCount, self._RefreshDotCallback)
end

return XUiPanelPBRAuto
