local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 【超算】成功后触发：
--  · 造成80%攻击伤害；
--  · 【击倒】对手；
--  · 使本场战斗中【攻击】属性+20/30/40点。

---@class XBuffScript.10262110 : XTheatre6SkillBase
local XBuff10262110 = XDlcScriptManager.RegBuffScript(10262110, "XBuffScript10262110", XTheatre6SkillBase)

function XBuff10262110:ScriptInit(isGainControl) --初始化
    self.hitDownStacks = 1
    self.dictAddAtk = {
        --攻击增加量
        [1] = 20,
        [2] = 30,
        [3] = 40
    }
end

function XBuff10262110:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._hitDownController = self:GetEnemyNpc():GetHitDownController()
end

function XBuff10262110:OnLuaSpecialHit(eventArgs)
    --造成击倒
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._missileHitCount ~= 1 then return end
    self._hitDownController:AddSkillCount(self.hitDownStacks)
end

function XBuff10262110:OnLuaSkillEnd(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --增加攻击力
    self:AddAttrib(ENpcAttrib.Attack, self.dictAddAtk[self._level], self._npcUUID, self._enemyUUID)
end

return XBuff10262110
