local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262050 : XTheatre6SkillBase
local XBuffScript10262050 = XDlcScriptManager.RegBuffScript(10262050, "XBuffScript10262050", XTheatre6SkillBase)

--效果说明：本场战斗中首次累计造成5次【击倒】时触发：
--· 获得5层<坚毅>。

function XBuffScript10262050:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._damageMagicId = 10250044 --注册超算成功技1伤害id，目前是临时的
    self.targetCount = 5
    self._blockController = self:GetNpc():GetBlockController()
    self._stackCount = 5
    self.ChanceCheck = 0
end

function XBuffScript10262050:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end

function XBuffScript10262050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._blockController:AddSkillCount(self._stackCount)
end


function XBuffScript10262050:OnLuaAffixHitDown(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.attackCount = self.attackCount + 1
    if self.ChanceCheck == 0 then
        if self.attackCount >= self.targetCount then
            self.ChanceCheck = 1
            self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
        end
    end
end

return XBuffScript10262050

--无法获取到击飞事件