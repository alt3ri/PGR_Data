local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---【超算】成功后触发：
---扣除对手20点【体力值】，自身每有20点【超算】属性，额外扣除对手1点【体力值】；
---使用【插入式技能】时，本场战斗中每造成过1次【击飞】，【攻击】属性提升15点。
---@class XBuffScript.10251611 : XTheatre6SkillBase
local XBuff10251611 = XDlcScriptManager.RegBuffScript(10251611, "XBuffScript10251611", XTheatre6SkillBase)

function XBuff10251611:ScriptInit(isGainControl) --初始化
    ---【击飞】计数
    self._damageMagicId = 10250014               --注册超算成功技1伤害id
    self.hitFlyCount = 0                         --击飞次数
    self.isHitFlyCounted = 0                     --该技能是否统计过击飞
    self.atkBuffId = 1025904                     --攻击提升buff
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuff10251611:OnLuaAffixHitFly(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.isHitFlyCounted == 1 then return end
    self.hitFlyCount = self.hitFlyCount + 1
    --每个技能仅记录1次，关闭开关
    self.isHitFlyCounted = 1
end

function XBuff10251611:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self._skillId then
        --打开击飞计数开关
        self.isHitFlyCounted = 0
    end
    --如果是插入技能，则计算属性提升
    if eventArgs._skillType ~= ETheatre6SkillType.Insert then return end
    self._stackCountAtk = self.hitFlyCount * 15
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.atkBuffId, 1, 0, self._stackCountAtk)
end

function XBuff10251611:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    local staminaDamage = 20 + self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) // 20
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -staminaDamage, 0)
end

return XBuff10251611
