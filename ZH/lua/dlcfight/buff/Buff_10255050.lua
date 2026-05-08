local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10255050 : XTheatre6SkillBase
local XBuffScript10255050 = XDlcScriptManager.RegBuffScript(10255050, "XBuffScript10255050", XTheatre6SkillBase)

--效果说明：
--· 每场战斗首次使用此技能时，额外造成3层【点燃】。

function XBuffScript10255050:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._stackCountBurn = 3
    self.ChanceCheck = 0
    self._hitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10255050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self:GetEnemyNpc():GetBurnController():CastStackBuff(self._stackCountBurn, self._enemyUUID)
        self.ChanceCheck = 1
    end
end

return XBuffScript10255050
