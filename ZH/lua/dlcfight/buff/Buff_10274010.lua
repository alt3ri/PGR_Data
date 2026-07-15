local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10274010 : XTheatre6SkillBase
local XBuffScript10274010 = XDlcScriptManager.RegBuffScript(10274010, "XBuffScript10274010", XTheatre6SkillBase)

-- 效果说明：
-- · 每有100点【超算】属性，获得【当前生命值】1%的【护盾】；
-- · {被动}进入战斗时，触发一次上述效果；
-- · 扣除对手20点【体力值】，自身每有45点【护盾】，额外扣除对手1点【体力值】。

function XBuffScript10274010:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)
    self.Protector = self:GetNpc():GetProtectorController()
    self.ShieldBuffId = 1027401         -- 正式buffid
    self.OverClockPerShieldPercent = 100-- 每100点超算属性触发一次护盾比例
    --self.ShieldPercentPerStep = 0.01  -- 每次触发获得当前生命值1%的护盾
end

function XBuffScript10274010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self:TriggerShieldEffect()
end

function XBuffScript10274010:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self:TriggerShieldEffect()
    self:TriggerStaminaDrainEffect()
end

function XBuffScript10274010:TriggerShieldEffect()
    --local overClockValue = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock)
    --local currentHp = self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Life)
    local shieldValue = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) // self.OverClockPerShieldPercent

    if shieldValue <= 0 then
        return
    end

    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.ShieldBuffId, 1, 0, shieldValue)
end

function XBuffScript10274010:TriggerStaminaDrainEffect()
    local shieldValue = self._proxy:GetNpcProtector(self._npcUUID)
    local baseStaminaDrain = 20
    local extraStaminaDrain = math.floor(shieldValue / 45)
    local totalStaminaDrain = baseStaminaDrain + extraStaminaDrain

    if totalStaminaDrain <= 0 then
        return
    end

    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -totalStaminaDrain, 0)
end

return XBuffScript10274010
