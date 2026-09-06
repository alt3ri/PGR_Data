local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282010 : XTheatre6SkillBase
local XBuffScript10282010 = XDlcScriptManager.RegBuffScript(10282010, "XBuffScript10282010", XTheatre6SkillBase)

--效果说明：· 每次使用1号位的主动技能时触发：
--· 造成3层【剧毒】。
--· 造成【击飞】。

function XBuffScript10282010:ScriptInit(isGainControl) --初始化
    self._stackCount = {
        --不同等级的默认剧毒层数
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._stackCountHitFly = 1
end

function XBuffScript10282010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10282010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.FirstMainSkillId = self._proxy:Theatre6GetMainSkill(self._npcUUID)[0] -- 抓一下一号位主动技能id
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self.FirstMainSkillId then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
    if eventArgs._skillId == self._skillId then
        --self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self._HitFlyController:AddSkillCount(self._stackCountHitFly)
        self._poisonedController:CastStackBuff(self._stackCount[self._lv], self._enemyUUID)
    end
end

return XBuffScript10282010