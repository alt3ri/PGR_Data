local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252160 : XTheatre6SkillBase
local XBuffScript10252160 = XDlcScriptManager.RegBuffScript(10252160, "XBuffScript10252160", XTheatre6SkillBase)

--效果说明：自身【体力值】在本场战斗中首次归零时触发：
--· 造成180%攻击伤害，对手【生命值】每降低1%，此技能伤害提升1%攻击；
--· 本场战斗中每造成过1次【暴击】，恢复4/8/12点【体力值】。

function XBuffScript10252160:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    if self._skillId == 10252081 then self.TLrecover = 12
    else if self._skillId == 10252082 then self.TLrecover = 8
    else self.TLrecover = 4
    end
    end
    self.ExtraAttack = 100
    self.ChanceCheck = 0
    self.ChanceCheckSkillUse = 0
    self.Count = 0
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10252160:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    if self.originAttrib1 <= 0 then
        if self.ChanceCheckSkillUse <= 0 then
            self.ChanceCheckSkillUse = 1
            self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
        end
    end
end

function XBuffScript10252160:OnLuaAffixCritDamage(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.Count = self.Count + 1
        self.SkillChanceCheck = 1
    end
end

function XBuffScript10252160:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.SkillChanceCheck = 0
    if eventArgs._skillId ~= self.TargetSkill then return end
    self.TLRecover_A = self.TLrecover * self.Count
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover_A, 0) --恢复5体力
end

return XBuffScript10252160