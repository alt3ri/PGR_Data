local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10255040 : XTheatre6SkillBase
local XBuffScript10255040 = XDlcScriptManager.RegBuffScript(10255040, "XBuffScript10255040", XTheatre6SkillBase)

--效果说明：
--· 每场战斗首次使用此技能时，额外造成【击飞】。

function XBuffScript10255040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._stackCount = 1
    self.ChanceCheck = 0
    self._hitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10255040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._stackCount == 1 then
        if self.ChanceCheck == 0 then
            self._hitFlyController:AddSkillCount(self._stackCount)
            self.ChanceCheck = 1
            self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025194)
            self._stackCount = 0
        end
    end
end

function XBuffScript10255040:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 1 then
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
        self.ChanceCheck = 2
    end
end

return XBuffScript10255040
