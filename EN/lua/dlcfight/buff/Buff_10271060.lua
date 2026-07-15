local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271060 : XTheatre6SkillBase
local XBuffScript10271060 = XDlcScriptManager.RegBuffScript(10271060, "XBuffScript10271060", XTheatre6SkillBase)

--效果说明：· 每有4点【耀斑值】，获得1点【耀斑值】；
--· 造成【击飞】。

function XBuffScript10271060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.StackBuff = 1027101 --耀斑buffid
    self.SunRecover = 0 --耀斑值恢复量
    self._sunController = self:GetNpc():GetSunController()
    self.SunRecoverPerSun = 4
    self.HitFlyCount = 1
end

function XBuffScript10271060:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._HitFlyController:AddSkillCount(self.HitFlyCount) -- 造成一次击飞
    local originAttrib1 = self._proxy:GetBuffStacks(self._npcUUID,self.StackBuff)
    --self:LogError(".....播报下耀斑层数层数"..originAttrib1)
    self.SunRecover = originAttrib1 // self.SunRecoverPerSun
    self._sunController:CastStackBuff(self.SunRecover, self._npcUUID)
end

return XBuffScript10271060