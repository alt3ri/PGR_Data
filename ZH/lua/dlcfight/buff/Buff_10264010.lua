local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 【超算】成功后，造成200%攻击伤害。
--  · 获得50点【怒火】；
--  · 本场战斗中每次通过技能消耗【怒火】，额外扣除对手10点【体力值】。
---@class XBuffScript.10264010 : XTheatre6SkillBase
local XBuff10264010 = XDlcScriptManager.RegBuffScript(10264010, "XBuffScript10264010", XTheatre6SkillBase)

function XBuff10264010:ScriptInit(isGainControl) --初始化
    self.angerStacks = 50
    self.staminaDamage = 10                      --体力消除数值
    self.stackBuffAnger = 1025107                --怒火buff
    self.stackBuffAngery = 1025108               --狂暴buff
    self.angerRemoveTrigger = false              --怒火扣除开关
    self.isSelfStart = false                     --本技能释放成功
    self._AngerController = self:GetNpc():GetAngerController()
    self.dictAngerRemoveSkill = self._AngerController.DictAngerRemoveSkill
end

function XBuff10264010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --如果是自己，则技能释放成功
    if eventArgs._skillId == self._skillId then self.isSelfStart = true end
    --打开怒火扣除检测开关
    local skillKey = eventArgs._skillId // 10
    if self.dictAngerRemoveSkill[skillKey] ~= nil then self.angerRemoveTrigger = true end
    
end

function XBuff10264010:OnLuaSkillEnd(eventArgs)
    --释放特殊命中时，获得怒火、扣除对手体力
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --获得怒火
    self._AngerController:CastStackBuff(self.angerStacks, self._npcUUID)
end

function XBuff10264010:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuff10264010:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if not self.angerRemoveTrigger then return end
    if not self.isSelfStart then return end
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.stackBuffAnger then return end
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.staminaDamage, 0)
    self.angerRemoveTrigger = false
end

return XBuff10264010
