local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265070 : XTheatre6SkillBase
local XBuffScript10265070 = XDlcScriptManager.RegBuffScript(10265070, "XBuffScript10265070", XTheatre6SkillBase)

--效果说明：
--· 下一次使用的技能伤害提升25%。

function XBuffScript10265070:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.BuffId = 10255071        --25%加伤buff
    self._critController = self:GetNpc():GetCritController()
end

function XBuffScript10265070:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
end

return XBuffScript10265070
