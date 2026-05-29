local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262080 : XTheatre6SkillBase
local XBuffScript10262080 = XDlcScriptManager.RegBuffScript(10262080, "XBuffScript10262080", XTheatre6SkillBase)

--效果说明：双方累计每使用10次技能后触发：
-- · 造成50%攻击伤害；
-- · 自身每有40点【体力】属性，获得1层<坚毅>。

function XBuffScript10262080:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.attackCount = 0
    self.targetCount = 10
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuffScript10262080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.attackCount = self.attackCount + 1
    if self.attackCount >= self.targetCount then
        self.attackCount = 0
        self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
    end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self._blockController:AddSkillCount(self._stackCount)
end

return XBuffScript10262080

--无法获取到击飞事件