local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271110 : XTheatre6SkillBase
local XBuffScript10271110 = XDlcScriptManager.RegBuffScript(10271110, "XBuffScript10271110", XTheatre6SkillBase)

--效果说明：· 消耗30点【体力值】，获得2层<坚毅>。
--· 造成【击飞】。

function XBuffScript10271110:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._stackCount = 2
    self._blockController = self:GetNpc():GetBlockController()
    --self.BlockCostStamina = 30
    --self.BlockPerStamina = 50
    self.HitFlyCount = 1
end

function XBuffScript10271110:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --local effectStacks = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina) // self.BlockPerStamina
    if self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina) > 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -self.BlockCostStamina, 0)
        self._blockController:AddSkillCount(self._stackCount)
    end
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._HitFlyController:AddSkillCount(self.HitFlyCount) -- 造成一次击飞
end

return XBuffScript10271110