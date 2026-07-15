local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10275060 : XTheatre6SkillBase
local XBuffScript10275060 = XDlcScriptManager.RegBuffScript(10275060, "XBuffScript10275060", XTheatre6SkillBase)

--效果说明：
--· {被动}进入战斗时，获得2层<坚毅>。

function XBuffScript10275060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.ChanceCheck = 0
    self._stackCount = 2
    self._blockController = self:GetNpc():GetBlockController()
    self._blockController:AddSkillCount(self._stackCount)
end

return XBuffScript10275060
