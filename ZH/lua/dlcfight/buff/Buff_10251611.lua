local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---【超算】成功后触发：
---扣除对手20点【体力值】，自身每有20点【超算】属性，额外扣除对手1点【体力值】；
---使用【插入式技能】时，本场战斗中每造成过1次【击飞】，【攻击】属性提升10点。
---@class XBuffScript.10251611 : XTheatre6SkillBase
local XBuff10251611 = XDlcScriptManager.RegBuffScript(10251611, "XBuffScript10251611", XTheatre6SkillBase)

function XBuff10251611:ScriptInit(isGainControl) --初始化
    ---【击飞】计数
    self._damageMagicId = 10250014 --注册超算成功技1伤害id
    self.hitFlyCount = 0
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuff10251611:OnLuaAffixHitFly(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.hitFlyCount = self.hitFlyCount + 1
end

function XBuff10251611:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
end

function XBuff10251611:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType ~= Insert then return end
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -self.staminaDamage,0)
end

function XBuff10251611:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    local staminaDamage = 20 + self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) // 20
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -staminaDamage,0)
end


return XBuff10251611
