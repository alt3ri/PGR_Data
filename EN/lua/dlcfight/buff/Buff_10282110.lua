local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10282110 : XTheatre6SkillBase
local XBuffScript10282110 = XDlcScriptManager.RegBuffScript(10282110, "XBuffScript10282110", XTheatre6SkillBase)

-- 效果说明： 使用【反制技能】后触发：
--· 造成1/2/3层【剧毒】。
--· {被动}进入战斗时，造成1/2/3层【剧毒】。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10282110:ScriptInit(isGainControl)
    --XTheatre6SkillBase.ScriptInit(self, isGainControl)
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._stackCountFirst = {
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
    self._stackCount = {
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
end

function XBuffScript10282110:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._poisonedController:CastStackBuff(self._stackCountFirst[self._lv], self._enemyUUID)
end

function XBuffScript10282110:OnLuaSkillStart(eventArgs)
    local ChanceCheck = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType == ETheatre6SkillType.Dodge then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
    if eventArgs._skillId ~= self._skillId then return end
    self._poisonedController:CastStackBuff(self._stackCount[self._lv], self._enemyUUID)
end


return XBuffScript10282110
