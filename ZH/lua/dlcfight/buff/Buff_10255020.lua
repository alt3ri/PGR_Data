local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10255020 : XTheatre6SkillBase
local XBuffScript10255020 = XDlcScriptManager.RegBuffScript(10255020, "XBuffScript10255020", XTheatre6SkillBase)

--效果说明：
--· 【超算】属性>230点时，伤害额外提高20/25/30%攻击。

function XBuffScript10255020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.TargetCS = 230
    --self:LogError(".....初始化完成")
    self._damageMagicId = 10250046 --注册超算成功技1伤害id
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
    if self._skillId == 10255021 then self._exDamageRate = 2000
    else if self._skillId == 10255022 then self._exDamageRate = 2500
    else self._exDamageRate = 3000
    end
    end
    self._hasChangedDamage = true
end

function XBuffScript10255020:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10255020:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hasChangedDamage = true
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    if self.originAttrib1 > self.TargetCS then
        self._hasChangedDamage = false
    end
        --self:LogError(".....扣了敌人超算？"..self._enemyUUID)
end

function XBuffScript10255020:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end

return XBuffScript10255020
