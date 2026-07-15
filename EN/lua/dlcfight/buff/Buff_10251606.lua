local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---造成4次【击飞】后触发，【拼刀】属性+3
---@class XBuffScript.10251606 : XTheatre6SkillBase
local XBuff10251606 = XDlcScriptManager.RegBuffScript(10251606, "XBuffScript10251606", XTheatre6SkillBase)

function XBuff10251606:ScriptInit(isGainControl) --初始化
    ---技能使用计次
    self.attackCount = 0
    self.targetCount = 4
    self._stackCount = 1
    ---添加拼刀属性
    self.dictBuffStacks = {
        [1] = 30,
        [2] = 40,
        [3] = 50
    }
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._critController = self:GetNpc():GetCritController()
end

function XBuff10251606:OnLuaAffixHitFly(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.attackCount = self.attackCount + 1
    if self.attackCount >= self.targetCount then
        self.attackCount = 0
        self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
    end
end

function XBuff10251606:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self:AddTheatre6Attrib(ETheatre6AttribType.WrestlePoint, self.dictBuffStacks[self._lv], self._npcUUID, self._npcUUID)
    self._critController:AddSkillCount(self._stackCount)
end

--function XBuff10251606:OnLuaAttackerChange(eventArgs)
---出手权交换时重置计数
--self.attackCount = 0
--end

return XBuff10251606
