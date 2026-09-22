local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282030 : XTheatre6SkillBase
local XBuffScript10282030 = XDlcScriptManager.RegBuffScript(10282030, "XBuffScript10282030", XTheatre6SkillBase)

--效果说明：  每累计造成4次【暴击】技能时触发：
-- · 造成2层【剧毒】；
-- · 获得1层<暴击>。

function XBuffScript10282030:ScriptInit(isGainControl) --初始化
    self._stackCount = 1 -- 暴击层数
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._critController = self:GetNpc():GetCritController()
    self.PoisonedCount = {
        --不同等级的默认剧毒层数
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
    self.SkillChanceCheck = 0
    self.Count = 0
    self._stackCountCrit = 4
end


function XBuffScript10282030:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10282030:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.SkillChanceCheck = 0
    if eventArgs._skillId == self._skillId then
        self._critController:AddSkillCount(self._stackCount, self._npcUUID)
    end
end

function XBuffScript10282030:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self._skillId then
        self._poisonedController:CastStackBuff(self.PoisonedCount[self._lv],self._enemyUUID)
    end
end

function XBuffScript10282030:OnLuaAffixCritDamage(eventArgs)
    --self:LogError(".....抓到暴击")
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.Count = self.Count + 1
        self.SkillChanceCheck = 1
    end
    if self.Count == self._stackCountCrit then
        self._level:RequestInsertSkill(self._npcUUID,self._skillId)
        --self:LogError(".....暴击插入技已塞入队列"..self._npcUUID)
        self.Count = 0
    end
end


return XBuffScript10282030