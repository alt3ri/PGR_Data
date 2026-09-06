local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10283020 : XTheatre6SkillBase
local XBuffScript10283020 = XDlcScriptManager.RegBuffScript(10283020, "XBuffScript10283020", XTheatre6SkillBase)

--效果说明：· 造成5层【剧毒】；
--· 触发2次【剧毒】伤害；
--· {被动}使用【触发技能】时，触发1次【剧毒】伤害，每有1点【先机】属性，【剧毒】伤害提升0.3%。伤害提升这部分被动写在控制器里

function XBuffScript10283020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.StackBuff = 1025105 --格挡buffid
    self.Count = 0 --此技能使用次数
    self.PoisonedCount = 5
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    --self.PoisonedTriggerCount = 2
    self.PoisonedTriggerInsert = 1
end


function XBuffScript10283020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10283020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType == ETheatre6SkillType.Insert then
        self._proxy:ApplyMagic(self._enemyUUID,self._enemyUUID,1028104,1,1,self.PoisonedTriggerInsert)
    end
    if eventArgs._skillId ~= self._skillId then return end
    self._poisonedController:CastStackBuff(self.PoisonedCount, self._enemyUUID)
    self._poisonedController:CastDmg()
    self._poisonedController:CastDmg() -- 发两次触发剧毒伤害，控制器捕获到后理论上会触发2次剧毒伤害，写成一次加两层只会被捕获一次
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5) --造成5秒晕眩
end

--function XBuffScript10283020:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end


return XBuffScript10283020