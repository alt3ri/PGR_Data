--- 单个战斗场景特效实例（由 XUiPunishaarEffectPlayer 的对象池管理）。
--- 移动：XUiHelper.Tween（固定时长）+ XTool.GetBezierScalar（单轴二次贝塞尔，三轴独立）驱动起点→中点→终点曲线。
---   中点 = 起终中点（X/Z）+ Y 取起终最大值 + 随机偏移（弧度高度，走 ClientConfig.BattleEffectTangentHeight），
---   X 轴加随机偏移（走 ClientConfig.BattleEffectTangentWidth），钳到敌我坐标范围内（不超左右界）。
---   min==max 时不调 Random.Range（上下限相同接口可能报错），直接用固定值。#73
---@class XUiPunishaarBattleEffect
local XUiPunishaarBattleEffect = XClass(nil, "XUiPunishaarBattleEffect")

--- 取 [minVal, maxVal] 随机值；min==max 时直接返（不调 Random.Range，避免上下限相同接口报错）。
local function RandomOffset(minVal, maxVal)
    if minVal == maxVal then
        return minVal
    end
    return CS.UnityEngine.Random.Range(minVal, maxVal)
end

function XUiPunishaarBattleEffect:Ctor(go, parent)
    self._Parent = parent
    self.GameObject = go
    self.Transform = go.transform
    self._IsPlaying = false
    self._OnComplete = nil
    self._TweenTimer = nil
end

--- 播放：从起点经中点（弧度偏移）贝塞尔曲线到终点，duration 秒后到期归池。
--- 起终点传 6 标量（贝塞尔标量化，避 Vector3 装箱；调用方 GetPosition 标量直传，不在边界构造 Vector3）。
--- duration 由调用方按当前倍速缩放后传入（VFX 速度跟随倍速，与逻辑层延时 landTick 同步）；本方法不读 config。
---@param startX number 发动者模型挂点世界坐标 x
---@param startY number
---@param startZ number
---@param endX number 目标模型挂点世界坐标 x
---@param endY number
---@param endZ number
---@param duration number Tween 时长（秒，已按倍速缩放，须>0）
---@param onComplete function|nil 播放完毕回调（由 Controller 归还池）
function XUiPunishaarBattleEffect:Play(startX, startY, startZ, endX, endY, endZ, duration, onComplete)
    self._OnComplete = onComplete
    self._IsPlaying = true
    self.GameObject:SetActiveEx(true)

    -- Y 弧度高度（须 > 0，0=未配→IsNumberValidEx 判 false→替换常量）
    local baseY = math.max(startY, endY)
    local yMin = XMVCA.XPunishaar:GetClientNumberByKey("BattleEffectTangentHeight", 1)

    if not XTool.IsNumberValidEx(yMin) then
        yMin = 1
    end

    local yMax = XMVCA.XPunishaar:GetClientNumberByKey("BattleEffectTangentHeight", 2)

    if not XTool.IsNumberValidEx(yMax) then
        yMax = 5
    end

    local yOffset = RandomOffset(yMin, yMax)

    -- X 水平偏移（可为负/0，0=无偏移=默认安全值；min==max 不调 Range）
    local xMin = XMVCA.XPunishaar:GetClientNumberByKey("BattleEffectTangentWidth", 1)
    local xMax = XMVCA.XPunishaar:GetClientNumberByKey("BattleEffectTangentWidth", 2)
    local xOffset = RandomOffset(xMin or 0, xMax or 0)

    -- 中点标量（不构造 Vector3，贝塞尔标量化）：X = 起终中点 + xOffset 钳到敌我范围；Y = 起终最大值 + 弧度偏移；Z = 起终中点
    local midX = XMath.Clamp((startX + endX) * 0.5 + xOffset, math.min(startX, endX), math.max(startX, endX))
    local midY = baseY + yOffset
    local midZ = (startZ + endZ) * 0.5

    -- 立即设起点（防 Tween 第一帧延迟——ScheduleForever 下一帧才调 onRefresh，
    -- reparent SetParent(false) 后特效在 EffectAnchor 位置非起点，首帧视觉跳）
    -- 坐标设置走 SetPosition 标量 API（避 Vector3 装箱）
    self.Transform:SetPosition(startX, startY, startZ)

    -- 固定时长 Tween 驱动标量贝塞尔曲线移动（duration 由调用方按倍速缩放传入，VFX 与逻辑 landTick 同步）
    self._TweenTimer = XUiHelper.Tween(duration, function(t)
        -- 二次贝塞尔标量（XTool.GetBezierScalar 单轴，三轴独立调用；避 GetBezierPoint 的 Vector3 运算装箱 #向量GC）
        local bx = XTool.GetBezierScalar(t, startX, midX, endX)
        local by = XTool.GetBezierScalar(t, startY, midY, endY)
        local bz = XTool.GetBezierScalar(t, startZ, midZ, endZ)
        self.Transform:SetPosition(bx, by, bz)
    end, function()
        self:_OnFinish()
    end)
end

--- Tween 到期：归池前回调 Controller 的 onComplete。
function XUiPunishaarBattleEffect:_OnFinish()
    if not self._IsPlaying then
        return
    end
    local cb = self._OnComplete
    self:_Reset()
    if cb then
        cb()
    end
end

--- 强制中断（OnDisable 时由 Controller 调用）：UnSchedule Tween，不触发 onComplete，直接归池。
function XUiPunishaarBattleEffect:ForceStop()
    self._IsPlaying = false
    if self._TweenTimer then
        XScheduleManager.UnSchedule(self._TweenTimer)
        self._TweenTimer = nil
    end
    self:_Reset()
end

function XUiPunishaarBattleEffect:_Reset()
    self._IsPlaying = false
    self._OnComplete = nil
    self._TweenTimer = nil
    if self.GameObject then
        self.GameObject:SetActiveEx(false)
    end
end

return XUiPunishaarBattleEffect
