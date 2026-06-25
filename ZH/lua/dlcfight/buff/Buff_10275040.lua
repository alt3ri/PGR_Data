local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10275040 : XTheatre6SkillBase
local XBuffScript10275040 = XDlcScriptManager.RegBuffScript(10275040, "XBuffScript10275040", XTheatre6SkillBase)

--效果说明：
--· {被动}进入战斗时，获得10%【生命值】的【护盾】.

function XBuffScript10275040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._protectorMagicId = 1027504
    self.Protector = self:GetNpc():GetProtectorController()
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self._protectorMagicId)
end



return XBuffScript10275040
