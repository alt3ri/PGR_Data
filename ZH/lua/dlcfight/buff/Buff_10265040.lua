local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265040 : XTheatre6SkillBase
local XBuffScript10265040 = XDlcScriptManager.RegBuffScript(10265040, "XBuffScript10265040", XTheatre6SkillBase)

--效果说明：
--· 每场战斗首次使用此技能时，额外造成【击飞】。

function XBuffScript10265040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._stackCount = 1
    self.ChanceCheck = 0
    self._hitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10265040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self._hitFlyController:AddSkillCount(self._stackCount)
        self.ChanceCheck = 1
        --self._proxy:LaunchMissile(self._enemyUUID, self._enemyUUID, 102530101, 102530101, 1) --科研半天发现不行，lua里给角色发击飞子弹好像没办法让角色出现击飞表现
    end
end

return XBuffScript10265040
