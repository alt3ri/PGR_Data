---@class XPBRCalibrateControl : XControl
---@field _MainControl XPBRGameControl
local XPBRCalibrateControl = XClass(XControl, "XPBRCalibrateControl", true)

local FightMsPerFrame = 50; -- 战斗每帧50ms
local MS_PER_MINUTE = 60000
-- 配表 AccentBeatIndex 是 1-indexed（1=第一拍）
local ACCENT_INDEX_BASE = 1

function XPBRCalibrateControl:OnInit()
    self._IsCalibrating = false
    self._OffsetMs = 0
end

function XPBRCalibrateControl:AddAgencyEvent()
end
function XPBRCalibrateControl:RemoveAgencyEvent()
end

function XPBRCalibrateControl:OnRelease()

end

--- 开始校准（界面级调用：播放 BGM + 缓存时间常量 + 加载偏移值）
function XPBRCalibrateControl:StartCalibration(bgmId)
    self._MainControl.MusicControl:PlayPreview(bgmId)
    -- 缓存 bgmCfg 和时间常量，避免每帧查表
    local bgmCfg = self._MainControl.MusicControl:GetCurrentBgmCfg()
    self._CachedBgmCfg = bgmCfg
    local bpm = bgmCfg and bgmCfg.BeatsPerMinute or 0
    local beatInterval = bpm > 0 and (MS_PER_MINUTE / bpm) or 0
    self._BeatInterval = beatInterval
    self._HalfBeat = beatInterval / 2
    self._HalfLoop = beatInterval * ((bgmCfg and bgmCfg.BeatsPerLoop) or 0) / 2
    self._AccentOffset = math.max(0, ((bgmCfg and bgmCfg.AccentBeatIndex) or ACCENT_INDEX_BASE) - ACCENT_INDEX_BASE) * beatInterval
    -- 加载偏移值，若超出有效范围则 clamp 并回写
    local savedOffset = self:GetOffsetMs()
    local effectiveRange = self:GetEffectiveRange()
    local clampedOffset = XMath.Clamp(savedOffset, -effectiveRange, effectiveRange)
    if clampedOffset ~= savedOffset then
        self._Model:SetBeatOffset(clampedOffset)
    end
    self._OffsetMs = clampedOffset
    self._IsCalibrating = true
end

--- 停止校准（界面级调用：停止 BGM 播放）
function XPBRCalibrateControl:StopCalibration()
    self._IsCalibrating = false
    self._MainControl.MusicControl:StopPreview()
end

function XPBRCalibrateControl:IsCalibrating()
    return self._IsCalibrating
end

--- 内部：计算节拍相位（使用缓存的 bgmCfg 避免每帧查表）
--- @param includePlayerOffset boolean 是否扣除玩家偏移
--- @return number phase 相位（0~beatInterval ms）
--- @return number beatInterval 节拍间隔（ms）
function XPBRCalibrateControl:_CalcBeatPhase(includePlayerOffset)
    local bgmCfg = self._CachedBgmCfg
    if not bgmCfg then
        return 0, 0
    end
    local elapsedMs = self._MainControl.MusicControl:GetPlayElapsedMs()
    local adjustedMs = elapsedMs - (bgmCfg.Offset or 0)
    if includePlayerOffset then
        adjustedMs = adjustedMs - self._OffsetMs
    end
    local beatInterval = self._BeatInterval
    local phase = adjustedMs % beatInterval
    if phase < 0 then
        phase = phase + beatInterval
    end
    return phase, beatInterval
end

--- 获取当前节拍相位（含玩家偏移，供判定逻辑使用）
--- @return number phase 当前相位（0~beatInterval ms）
--- @return number beatInterval 节拍间隔（ms）
function XPBRCalibrateControl:GetCurrentBeatPhase()
    return self:_CalcBeatPhase(true)
end

--- 获取原始节拍相位（不含玩家偏移，供节拍视图 ImgYuan 驱动）
--- @return number phase 原始相位（0~beatInterval ms）
--- @return number beatInterval 节拍间隔（ms）
function XPBRCalibrateControl:GetRawBeatPhase()
    return self:_CalcBeatPhase(false)
end

--- 内部：计算以重音拍为零点的小节相位
--- @param includePlayerOffset boolean 是否扣除玩家偏移
--- @return number phase (0~loopDuration)，0 = 重音拍时刻
--- @return number loopDuration 小节时长(ms)
function XPBRCalibrateControl:_CalcAccentPhase(includePlayerOffset)
    local bgmCfg = self._CachedBgmCfg
    if not bgmCfg then return 0, 0 end
    local elapsedMs = self._MainControl.MusicControl:GetPlayElapsedMs()
    local adjustedMs = elapsedMs - (bgmCfg.Offset or 0) - self._AccentOffset
    if includePlayerOffset then
        adjustedMs = adjustedMs - self._OffsetMs
    end
    local loopDuration = self._BeatInterval * bgmCfg.BeatsPerLoop
    if loopDuration <= 0 then return 0, 0 end
    local phase = adjustedMs % loopDuration
    if phase < 0 then phase = phase + loopDuration end
    return phase, loopDuration
end

--- 获取原始小节相位（不含玩家偏移，供节拍视图 ImgYuan 驱动 — 一小节尺度）
--- @return number phase 原始相位（0~loopDuration ms），0 = 重音拍时刻
--- @return number loopDuration 小节时长（ms）
function XPBRCalibrateControl:GetRawMeasurePhase()
    return self:_CalcAccentPhase(false)
end

--- 获取按下时刻与最近重音拍的差值（供自动校准记录）
--- 不扣除 _OffsetMs，因为自动校准需要测量原始偏差来计算新的偏移值
--- @return number diff 正数=晚按，负数=早按
function XPBRCalibrateControl:GetNearestBeatDiff()
    local bgmCfg = self._CachedBgmCfg
    if not bgmCfg then
        return 0
    end
    local elapsedMs = self._MainControl.MusicControl:GetPlayElapsedMs()
    local adjustedMs = elapsedMs - (bgmCfg.Offset or 0) - self._AccentOffset
    local loopDuration = self._BeatInterval * bgmCfg.BeatsPerLoop
    if loopDuration <= 0 then return 0 end
    local loopIndex = math.floor(adjustedMs / loopDuration + 0.5)
    local nearestAccentMs = loopIndex * loopDuration
    return adjustedMs - nearestAccentMs
end

--- 判断当前是否在重音拍判定窗口内
function XPBRCalibrateControl:IsInHitWindow()
    local phase, loopDuration = self:_CalcAccentPhase(true)
    if loopDuration <= 0 then return false end
    local halfWindow = self:GetHitWindowMs() / 2
    return phase < halfWindow or phase > loopDuration - halfWindow
end

--- 获取当前偏移值（ms）
function XPBRCalibrateControl:GetOffsetMs()
    return self._Model:GetBeatOffset()
end

--- 设置偏移值（clamp 到有效范围 + 持久化）
function XPBRCalibrateControl:SetOffsetMs(ms)
    local range = self:GetEffectiveRange()
    ms = XMath.Clamp(ms, -range, range)
    self._OffsetMs = ms
    self._Model:SetBeatOffset(ms)
end

--- 获取配置偏差范围（单侧），实际范围为 [-range, +range]
function XPBRCalibrateControl:GetOffsetRange()
    local range = self._MainControl:GetClientPBRNumber("CalibrateOffsetRange")
    if range and range > 0 then
        return range
    end
    
    -- 默认值
    return 500
end

--- 获取有效偏差范围 = min(配置范围, halfLoop)
--- 视图尺度为一小节，偏移范围对应一小节内
function XPBRCalibrateControl:GetEffectiveRange()
    local configRange = self:GetOffsetRange()
    if self._HalfLoop and self._HalfLoop > 0 then
        return math.min(configRange, self._HalfLoop)
    end
    return configRange
end

--- 获取判定窗口全宽时间（ms），供 UI 层映射像素尺寸
--- @return number hitWindowMs 判定窗口全宽时间，未初始化返回 0
function XPBRCalibrateControl:GetHitWindowMs()
    local bgmCfg = self._CachedBgmCfg
    if not bgmCfg then
        return 0
    end
    return (bgmCfg.HitWindowFrames or 3) * FightMsPerFrame
end

--- 获取缓存的半拍时长（StartCalibration 后可用）
function XPBRCalibrateControl:GetHalfBeat()
    return self._HalfBeat or 0
end

--- 获取缓存的半小节时长（StartCalibration 后可用）
function XPBRCalibrateControl:GetHalfLoop()
    return self._HalfLoop or 0
end

--- 获取校准用的 BgmId（从 PBRClientConfig 读取）
function XPBRCalibrateControl:GetCalibrateBgmId()
    return self._MainControl:GetClientPBRNumber("CalibrateBgmId")
end

--- 查询是否已完成过自动校准
function XPBRCalibrateControl:HasAutoCalibrated()
    return self._Model:GetHasAutoCalibrated()
end

--- 标记已完成自动校准
function XPBRCalibrateControl:MarkAutoCalibrated()
    self._Model:SetHasAutoCalibrated(true)
end

--- 获取上次自动校准推荐结果（ms），无结果返回 nil
function XPBRCalibrateControl:GetAutoCalibrationResult()
    return self._Model:GetAutoCalibrationResult()
end

--- 保存自动校准推荐结果（ms）
function XPBRCalibrateControl:SetAutoCalibrationResult(ms)
    self._Model:SetAutoCalibrationResult(ms)
end

return XPBRCalibrateControl
