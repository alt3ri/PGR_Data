local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10255010 : XTheatre6SkillBase
local XBuffScript10255010 = XDlcScriptManager.RegBuffScript(10255010, "XBuffScript10255010", XTheatre6SkillBase)

--效果说明：
--· 【拼刀】属性>230点时，伤害额外提高20/25/30%攻击。

function XBuffScript10255010:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.TargetPD = 230
    --self:LogError(".....初始化完成")
    self._damageMagicId = 10250044 --注册超算成功技1伤害id
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
    self._exDamageRate = 2000
    if self._skillId == 10255011 then self._exDamageRate = 2000
    else if self._skillId == 10255012 then self._exDamageRate = 2500
    else self._exDamageRate = 3000
    end
    end
    self._hasChangedDamage = true
end

function XBuffScript10255010:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10255010:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hasChangedDamage = true
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    if self.originAttrib1 > self.TargetPD then
        self._hasChangedDamage = false
    end
        --self:LogError(".....扣了敌人超算？"..self._enemyUUID)
end

function XBuffScript10255010:ChangeDamageBeforeCalc(eventArgs)
    --self:LogError("................10255010")
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end

return XBuffScript10255010
