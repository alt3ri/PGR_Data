local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281010 : XTheatre6SkillBase
local XBuffScript10281010 = XDlcScriptManager.RegBuffScript(10281010, "XBuffScript10281010", XTheatre6SkillBase)

--效果说明：· 造成2/3/4层【剧毒】，每使用过一次此技能，造成的【剧毒】层数+1。

function XBuffScript10281010:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.StackBuff = 1025105 --格挡buffid
    self.Count = 0 --此技能使用次数
    self.DefaultCount = {
        --不同等级的默认剧毒层数
        [1] = 2,
        [2] = 3,
        [3] = 4
    }
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10281010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10281010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local poisoned =  self.DefaultCount[self._lv] + self.Count
    self._poisonedController:CastStackBuff(poisoned, self._enemyUUID)
    self.Count = self.Count + 1
end

return XBuffScript10281010