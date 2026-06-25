local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10275050 : XTheatre6SkillBase
local XBuffScript10275050 = XDlcScriptManager.RegBuffScript(10275050, "XBuffScript10275050", XTheatre6SkillBase)

--效果说明：
--· 获得10点【耀斑值】。

function XBuffScript10275050:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.SunRecover = 10 --耀斑值恢复量
    self._sunController = self:GetNpc():GetSunController()
end

function XBuffScript10275050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._sunController:CastStackBuff(self.SunRecover, self._npcUUID)
end

return XBuffScript10275050
