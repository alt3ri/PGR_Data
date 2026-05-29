local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript10255071 : XTheatre6BuffBase
local XBuffScript10255071 = XDlcScriptManager.RegBuffScript(10255071, "XBuffScript10255071", XTheatre6BuffBase)

--效果说明：使用的技能伤害提升25%。加伤效果通过单位表发放，此效果废弃。

function XBuffScript10255071:ScriptInit(isGainControl) --初始化
    --self.TargetSkill = self._skillId
    self.BuffId = 10255071        --25%加伤buff
end

--function XBuffScript10255071:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    --if eventArgs._skillId ~= self._skillId then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    --self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 1)
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
--end

return XBuffScript10255071
