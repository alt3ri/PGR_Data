local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10255080 : XTheatre6SkillBase
local XBuffScript10255080 = XDlcScriptManager.RegBuffScript(10255080, "XBuffScript10255080", XTheatre6SkillBase)

--效果说明：
--· 每使用过一次一星技能，本技能伤害提升10%攻击。

function XBuffScript10255080:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.BuffId = 10255080        --25%加伤buff
    self.Count = 0
    self._critController = self:GetNpc():GetCritController()
    self._damageMagicId = 10250054 --注册伤害id
    self._exDamageBaseRate = 1000 --每次使用技能的伤害倍率提升
    self._exDamageRate = 0
end

function XBuffScript10255080:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10255080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.SkillIdCheck = eventArgs._skillId % 10000
    if self.SkillIdCheck < 5999 and self.SkillIdCheck > 5000 then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.Count = self.Count + 1
    self._exDamageRate = self._exDamageBaseRate * self.Count
    self._hasChangedDamage = false
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
end

function XBuffScript10255080:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end


return XBuffScript10255080
