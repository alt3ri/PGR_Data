local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 【超算】成功后，造成200%攻击伤害。
--· 获得100点【怒火】；
--· 每有20点【超算】属性，扣除对手1点【体力值】；
--· 通过技能获得【怒火】时，【超算】属性提升5点。
---@class XBuffScript.10264010 : XTheatre6SkillBase
local XBuff10264010 = XDlcScriptManager.RegBuffScript(10264010, "XBuffScript10264010", XTheatre6SkillBase)

function XBuff10264010:ScriptInit(isGainControl) --初始化
    self.angerStacks = 100
    --self.staminaDamage = 0                     --体力消除数值
    self.stackBuffAnger = 1025107                --怒火buff
    --self.stackBuffAngry = 1025108              --狂暴buff
    self._AngerController = self:GetNpc():GetAngerController()
    --self.dictAngerRemoveSkill = self._AngerController.DictAngerRemoveSkill
    self.angerAddTrigger = true
end

function XBuff10264010:OnLuaSkillEnd(eventArgs)
    self.angerAddTrigger = true
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._AngerController:CastStackBuff(self.angerStacks, self._npcUUID)
    local staminaDamage = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock) // 20
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -staminaDamage, 0)
end

function XBuff10264010:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuff10264010:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if not self.angerAddTrigger then return end
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.stackBuffAnger then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025902,1,0, 5) --给玩家加超算
    --self:LogError(".....成功触发了增加超算属性")
    self.angerAddTrigger = false
end

return XBuff10264010
