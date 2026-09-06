local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10285050 : XTheatre6SkillBase
local XBuffScript10285050 = XDlcScriptManager.RegBuffScript(10285050, "XBuffScript10285050", XTheatre6SkillBase)

--效果说明：
--· 每场战斗首次使用此技能时，额外造成3层【剧毒】。

function XBuffScript10285050:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._stackCount = 3
    self.ChanceCheck = 0
end

function XBuffScript10285050:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10285050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self._poisonedController:CastStackBuff(self._stackCount,self._enemyUUID)
        self.ChanceCheck = 1
    end
end

return XBuffScript10285050
