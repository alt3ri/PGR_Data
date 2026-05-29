local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265050 : XTheatre6SkillBase
local XBuffScript10265050 = XDlcScriptManager.RegBuffScript(10265050, "XBuffScript10265050", XTheatre6SkillBase)

--效果说明：
--· 每场战斗首次使用此技能时，额外造成30点【怒火】。

function XBuffScript10265050:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._angerRecover = 30
    self.ChanceCheck = 0
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10265050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self._AngerController:CastStackBuff(self._angerRecover, self._npcUUID)
        self.ChanceCheck = 1
    end
end

return XBuffScript10265050
