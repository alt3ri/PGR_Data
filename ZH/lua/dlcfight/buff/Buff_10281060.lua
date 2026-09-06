local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281060 : XTheatre6SkillBase
local XBuffScript10281060 = XDlcScriptManager.RegBuffScript(10281060, "XBuffScript10281060", XTheatre6SkillBase)

--效果说明：· 造成1层【剧毒】；
--· 触发1次【剧毒】伤害。

function XBuffScript10281060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.StackBuff = 1025105 --格挡buffid
    self.Count = 0 --此技能使用次数
    self.DefaultCount = 1
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    --self.PoisonedDmgCount = 1
end

function XBuffScript10281060:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10281060:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --local poisoned =  self.DefaultCount + self.Count
    self._poisonedController:CastStackBuff(self.DefaultCount, self._enemyUUID)
    self._poisonedController:CastDmg()
end

return XBuffScript10281060