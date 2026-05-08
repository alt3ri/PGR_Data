local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265060 : XTheatre6SkillBase
local XBuffScript10265060 = XDlcScriptManager.RegBuffScript(10265060, "XBuffScript10265060", XTheatre6SkillBase)

--效果说明：
--· 每场战斗首次使用此技能时，必定【暴击】。

function XBuffScript10265060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._stackCount = 1
    self.ChanceCheck = 0
    self._critController = self:GetNpc():GetCritController()
end

function XBuffScript10265060:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self._critController:AddSkillCount(self._stackCount)
        self.ChanceCheck = 1
    end
end

return XBuffScript10265060
