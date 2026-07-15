local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271040 : XTheatre6SkillBase
local XBuffScript10271040 = XDlcScriptManager.RegBuffScript(10271040, "XBuffScript10271040", XTheatre6SkillBase)

--效果说明：
--· 每有1层<坚毅>，获得4点【耀斑值】，至多20点。

function XBuffScript10271040:ScriptInit(isGainControl)
    self.BlockBuffId = 1025105 --坚毅buff的id
    self.FlarePerBlock = 4    --每层坚毅获得10点耀斑值
    self.MaxFlare = 20         --最多50点耀斑值
    self._sunController = self:GetNpc():GetSunController()
end

function XBuffScript10271040:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    local blockStacks = self._proxy:GetBuffStacks(self._npcUUID, self.BlockBuffId) or 0
    local addFlare = math.min(blockStacks * self.FlarePerBlock, self.MaxFlare)
    if addFlare <= 0 then return end

    self._sunController:CastStackBuff(addFlare, self._npcUUID)
end

return XBuffScript10271040
