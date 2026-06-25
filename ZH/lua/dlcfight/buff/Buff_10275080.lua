local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10275080 : XTheatre6SkillBase
local XBuffScript10275080 = XDlcScriptManager.RegBuffScript(10275080, "XBuffScript10275080", XTheatre6SkillBase)

--效果说明：
--· 每使用过一次白色技能，本技能伤害提升10%攻击。

function XBuffScript10275080:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.Count = 0
    self._critController = self:GetNpc():GetCritController()
    self._damageMagicId = 10270222 --注册伤害id
    self._exDamageBaseRate = 1000 --每次使用技能的伤害倍率提升
    self._exDamageRate = 0
    self._hasChangedDamage = false
    self.isCount = false
end

function XBuffScript10275080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local cfg = self._proxy:Theatre6GetSkillConfig(eventArgs._skillId)
    if cfg.Quality ~= 1 then return end
    self._exDamageRate = self._exDamageBaseRate * self.Count
    self._hasChangedDamage = false
    self.isCount = true
end

function XBuffScript10275080:OnLuaSkillEnd(eventArgs)
    if not self.isCount then return end
    self.Count = self.Count + 1
    self.isCount = false
end

function XBuffScript10275080:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10275080:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    self._hasChangedDamage = true
end

return XBuffScript10275080
