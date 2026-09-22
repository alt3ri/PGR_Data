--- 战斗受伤飘字（扣血数值文本，上浮淡出走 Timeline）。
--- 池化管理：DamageNumberPlayer 的 XPool 管生命周期（New 归池 → Play 取池显 → 完播/超时回池）。
--- 回池双保险：PlayAnimation finCb（_EnsurePool 已校验 prefab 含 Enable Timeline）+ 超时定时器兜底（finCb 失败强制回池，防 grid 永驻致池耗尽）。
---@class XUiGridDamagePopTxt: XUiNode
---@field protected _Control
---@field Parent
---@field Damage UnityEngine.UI.Text 飘字数值文本
local XUiGridDamagePopTxt = XClass(XUiNode, "XUiGridDamagePopTxt")

local DAMAGE_ANIM_NAME = "Enable"  -- prefab 下 Animation/<本名> Timeline
local DAMAGE_FALLBACK_MS = 10 * XScheduleManager.SECOND  -- 回池超时兜底（finCb 失败时强制回池）

--- 播放一次飘字。
---@param value number 单段伤害值 atkPerHit
---@param isCrit boolean|nil 暴击态（预留，prefab 定后接）
function XUiGridDamagePopTxt:Play(value, isCrit)
    self:Open()
    if self.Damage then
        self.Damage.text = tostring(value)
    end
    -- TODO(prefab): 暴击态变色/放大
    self._OnFinishedHandler = self._OnFinishedHandler or handler(self, self._OnFinished)
    self:StopFallbackTimer()
    self._FallbackTimerId = XScheduleManager.ScheduleOnce(self._OnFinishedHandler, DAMAGE_FALLBACK_MS)
    
    self:PlayAnimation(DAMAGE_ANIM_NAME, self._OnFinishedHandler)
end

--- 注册完播回调（控制器注入，须 Play 前调，一次性）。
---@param cb function|nil cb(self)
function XUiGridDamagePopTxt:SetFinishedCallback(cb)
    self._OnFinishedCb = cb
end

--- 完播通知（PlayAnimation finCb 或超时兜底触发；幂等：双触发 cb 已清则 no-op）。
function XUiGridDamagePopTxt:_OnFinished()
    self:StopFallbackTimer()
    local cb = self._OnFinishedCb
    if cb then
        self._OnFinishedCb = nil
        cb(self)
    end
end

function XUiGridDamagePopTxt:StopFallbackTimer()
    if self._FallbackTimerId then
        XScheduleManager.UnSchedule(self._FallbackTimerId)
        self._FallbackTimerId = nil
    end
end

function XUiGridDamagePopTxt:_StopAnim()
    self:StopAnimation(DAMAGE_ANIM_NAME)
end

--- 入池前清理（XPool onRelease）：先清回调再停动画，防停动画触发 finCb 误调旧回调。
function XUiGridDamagePopTxt:ResetForReuse()
    self._OnFinishedCb = nil
    self:StopFallbackTimer()
    self:_StopAnim()
    if self.Damage then
        self.Damage.text = ""
    end
    
    self:Close()
end

function XUiGridDamagePopTxt:OnDisable()
    self:_StopAnim()
    self:StopFallbackTimer()
end

function XUiGridDamagePopTxt:OnDestroy()
    self:_StopAnim()
    self:StopFallbackTimer()
    self._OnFinishedCb = nil
end

return XUiGridDamagePopTxt
