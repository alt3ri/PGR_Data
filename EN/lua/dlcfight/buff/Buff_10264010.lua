local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 【超算】成功后，造成200%攻击伤害。
--  · 获得50点【怒火】；
--  · 本场战斗中每次通过技能消耗【怒火】，额外扣除对手10点【体力值】。
---@class XBuffScript.10264010 : XTheatre6SkillBase
local XBuff10264010 = XDlcScriptManager.RegBuffScript(10264010, "XBuffScript10264010", XTheatre6SkillBase)

function XBuff10264010:ScriptInit(isGainControl) --初始化
    self.angerStacks = 50
    self.staminaDamage = 10         --体力消除数值
    self.stackBuffAnger = 1025107   --怒火buff
end

function XBuff10264010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuff10264010:OnLuaSpecialHit(eventArgs)
    --释放特殊命中时，获得怒火、扣除对手体力
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --获得怒火
    self._AngerController:CastStackBuff(self.angerStacks, self._npcUUID)
end

function XBuff10264010:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcRemoveBuff, self._npcUUID)
end

function XBuff10264010:NpcRemoveBuff(eventArgs)
    if eventArgs.BuffId ~= self.stackBuffAnger then return end
    if eventArgs.NpcUuid ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.staminaDamage,0)
end

return XBuff10264010
