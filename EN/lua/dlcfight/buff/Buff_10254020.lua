local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10254020 : XTheatre6SkillBase
local XBuffScript10254020 = XDlcScriptManager.RegBuffScript(10254020, "XBuffScript10254020", XTheatre6SkillBase)

--效果说明：用于暴击伤害修正

function XBuffScript10254020:ScriptInit(isGainControl) --初始化
    self._skillCount = 1
    self._critController = self:GetNpc():GetCritController()
    self:LogError("....【超算成功追加技能2】初始化完成")
end


function XBuffScript10254020:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._critController:AddSkillCount(self._skillCount)
end


return XBuffScript10254020

--点燃层数改了下，不知道有没有在表里的关键帧挂点燃，挂了的话这边得回滚