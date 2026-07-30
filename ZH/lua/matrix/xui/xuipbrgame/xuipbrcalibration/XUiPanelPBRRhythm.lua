--- 节拍视图节点
---@class XUiPanelPBRRhythm : XUiNode
---@field protected _Control
---@field Parent
---@field ImgBase @重音基准点
---@field ImgYuan @随bgm的播放进度同步移动的节点
---@field ImgYuanShadow @玩家点击重音按钮，记录玩家实际点击进度位置的残影节点
---@field ImgLine @UI的进度线
---@field ImgPerfect @Perfect 命中提示节点
local XUiPanelPBRRhythm = XClass(XUiNode, "XUiPanelPBRRhythm")

-- 残影/Perfect 默认显示时长（ms），配表 key 未配置时的回退值
local DEFAULT_SHADOW_DURATION_MS = 1000
-- 定时器间隔（ms），约60fps
local UPDATE_INTERVAL_MS = 16

function XUiPanelPBRRhythm:OnStart()
    self._UpdateHandler = handler(self, self.Update)
    -- 缓存 Prefab 原始直径（OnStart 仅执行一次，不会被 _UpdateHitWindowSize 污染）
    self._OriginalBaseDiameter = self.ImgBase.rectTransform.rect.width
    self._OriginalYuanDiameter = self.ImgYuan.rectTransform.rect.width
end

function XUiPanelPBRRhythm:OnEnable()
    self._LineWidth = self.ImgLine.rectTransform.rect.width
    self._HalfLineWidth = self._LineWidth / 2
    -- 缓存 ImgYuan 的 Y/Z，避免每帧跨 C# 边界读取
    local _, posY, posZ = XTool.GetLocalPosition(self.ImgYuan)
    self._YuanPosY = posY
    self._YuanPosZ = posZ
    self.ImgYuanShadow.gameObject:SetActiveEx(false)
    self.ImgPerfect.gameObject:SetActiveEx(false)
end

function XUiPanelPBRRhythm:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    self:_CancelShadowTimer()
end

function XUiPanelPBRRhythm:Update()
    local calibrateCtrl = self._Control.CalibrateControl
    local phase, loopDuration = calibrateCtrl:GetRawMeasurePhase()
    if not loopDuration or loopDuration <= 0 then
        return
    end
    -- 相位居中：phase=0（重音时刻）映射到 x=0（视图中心）
    local halfLoop = loopDuration / 2
    local centeredPhase = phase <= halfLoop and phase or (phase - loopDuration)
    -- 像素映射：一小节铺满整个视图
    local posX = (centeredPhase / halfLoop) * self._HalfLineWidth
    XTool.SetLocalPosition(self.ImgYuan, posX, self._YuanPosY, self._YuanPosZ)
end

--- 根据当前相位计算 ImgYuan 的精确 X 坐标（与 Update 使用完全一致的映射公式）
--- 在按钮事件（ShowShadow / _CheckPerfectAt）中调用，绕过 Update 定时器最多 16ms 的陈旧位置
--- @return number posX 像素坐标，0 = 视图中心（重音时刻）
function XUiPanelPBRRhythm:_CalcYuanPosX()
    local calibrateCtrl = self._Control.CalibrateControl
    local phase, loopDuration = calibrateCtrl:GetRawMeasurePhase()
    if not loopDuration or loopDuration <= 0 then
        -- 校准尚未启动时回退到当前渲染位置，避免返回 0 造成跳变
        return XTool.GetLocalPosition(self.ImgYuan)
    end
    local halfLoop = loopDuration / 2
    local centeredPhase = phase <= halfLoop and phase or (phase - loopDuration)
    return (centeredPhase / halfLoop) * self._HalfLineWidth
end

--- 显示残影 + Perfect 判定，并启动延时自动隐藏
--- 使用 _CalcYuanPosX() 而非 ImgYuan 的渲染位置，消除定时器最多 16ms 的相位延迟
function XUiPanelPBRRhythm:ShowShadow()
    local posX = self:_CalcYuanPosX()
    XTool.SetLocalPosition(self.ImgYuanShadow, posX, self._YuanPosY, self._YuanPosZ)
    self.ImgYuanShadow.gameObject:SetActiveEx(true)
    self.ImgPerfect.gameObject:SetActiveEx(self:_CheckPerfect())

    self:_CancelShadowTimer()
    local durationMs = self._Control:GetClientPBRNumber("CalibrateShadowDurationMs") or DEFAULT_SHADOW_DURATION_MS
    self._ShadowTimer = XScheduleManager.ScheduleOnce(handler(self, self._HideShadow), durationMs)
end

function XUiPanelPBRRhythm:_HideShadow()
    self._ShadowTimer = nil
    self.ImgYuanShadow.gameObject:SetActiveEx(false)
    self.ImgPerfect.gameObject:SetActiveEx(false)
end

function XUiPanelPBRRhythm:_CancelShadowTimer()
    if self._ShadowTimer then
        XScheduleManager.UnSchedule(self._ShadowTimer)
        self._ShadowTimer = nil
    end
end

--- Perfect 判定：委托逻辑层统一判定（基于配置表判定窗口时间）
function XUiPanelPBRRhythm:_CheckPerfect()
    return self._Control.CalibrateControl:IsInHitWindow()
end

--- 设置圆点可见性
function XUiPanelPBRRhythm:SetYuanVisible(visible)
    self.ImgYuan.gameObject:SetActiveEx(visible)
end

--- 控制节拍视图播放/停止（不依赖面板显隐生命周期）
function XUiPanelPBRRhythm:SetPlaying(playing)
    self:_UpdateHitWindowSize()
    if playing then
        if not self._Timer then
            self._Timer = XScheduleManager.ScheduleForever(self._UpdateHandler, UPDATE_INTERVAL_MS)
        end
        self.ImgYuan.gameObject:SetActiveEx(true)
        self.ImgYuanShadow.gameObject:SetActiveEx(false)
        self.ImgPerfect.gameObject:SetActiveEx(false)
        self:_CancelShadowTimer()
    else
        if self._Timer then
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
        end
        self.ImgYuan.gameObject:SetActiveEx(false)
        self:_CancelShadowTimer()
    end
end

--- 设置 ImgBase 偏移位置（手动模式传入 offsetMs，自动模式传入 0）
--- 映射尺度与 ImgYuan 一致（halfLoop），确保视觉与逻辑层时间轴对齐
function XUiPanelPBRRhythm:SetBaseOffset(offsetMs)
    local halfLoop = self._Control.CalibrateControl:GetHalfLoop()
    if halfLoop <= 0 then
        return
    end
    local posX = (offsetMs / halfLoop) * self._HalfLineWidth
    local _, posY, posZ = XTool.GetLocalPosition(self.ImgBase)
    XTool.SetLocalPosition(self.ImgBase, posX, posY, posZ)
end

--- 根据配置表判定窗口时间，动态设置 ImgBase/ImgYuan/ImgYuanShadow 尺寸
--- 映射公式与 ImgYuan 移动一致：px = (ms / halfLoop) * halfLineWidth
function XUiPanelPBRRhythm:_UpdateHitWindowSize()
    local calibrateCtrl = self._Control.CalibrateControl
    local hitWindowMs = calibrateCtrl:GetHitWindowMs()
    local halfLoop = calibrateCtrl:GetHalfLoop()
    if hitWindowMs <= 0 or halfLoop <= 0
       or self._HalfLineWidth <= 0 or self._OriginalBaseDiameter <= 0 then
        return
    end
    -- 判定窗口全宽(ms) → 像素直径
    local newBaseDiameter = (hitWindowMs / halfLoop) * self._HalfLineWidth
    self.ImgBase.rectTransform:SetSizeDeltaX(newBaseDiameter)
    self.ImgBase.rectTransform:SetSizeDeltaY(newBaseDiameter)
    -- ImgYuan / ImgYuanShadow 按比例缩放
    local scale = newBaseDiameter / self._OriginalBaseDiameter
    local newYuanDiameter = self._OriginalYuanDiameter * scale
    self.ImgYuan.rectTransform:SetSizeDeltaX(newYuanDiameter)
    self.ImgYuan.rectTransform:SetSizeDeltaY(newYuanDiameter)
    self.ImgYuanShadow.rectTransform:SetSizeDeltaX(newYuanDiameter)
    self.ImgYuanShadow.rectTransform:SetSizeDeltaY(newYuanDiameter)
end

return XUiPanelPBRRhythm
