local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265071 : XTheatre6SkillBase
local XBuffScript10265071 = XDlcScriptManager.RegBuffScript(10265071, "XBuffScript10265071", XTheatre6SkillBase)

--效果说明：使用的技能伤害提升25%，技能结束时销毁此buff ，实际上没有用这个buff，继续用了10255071

function XBuffScript10265071:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.BuffId = 10265071        --25%加伤buff
end

function XBuffScript10265071:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 1)
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
end

return XBuffScript10265071
