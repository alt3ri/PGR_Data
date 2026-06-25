local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 使用【拼刀成功技能】后触发：
--  · 造成100%攻击的伤害；
--  · 获得1/2/3层<坚毅>。
---@class XBuffScript.10262120 : XTheatre6SkillBase
local XBuff10262120 = XDlcScriptManager.RegBuffScript(10262120, "XBuffScript10262120", XTheatre6SkillBase)

function XBuff10262120:ScriptInit(isGainControl) --初始化
    self.skillType = ETheatre6SkillType.Wrestle
    self.dictBlockStacks = {
        --坚毅层数
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
end

function XBuff10262120:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuff10262120:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --如果是【拼刀成功技】，则触发本技能
    if eventArgs._skillType ~= self.skillType then return end
    self._level:RequestInsertSkill(self._npcUUID, self._skillId)
end

function XBuff10262120:OnLuaSkillStart(eventArgs)
    --获得坚毅
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._blockController:AddSkillCount(self.dictBlockStacks[self._lv])
end

return XBuff10262120
