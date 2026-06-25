local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271080 : XTheatre6SkillBase
local XBuffScript10271080 = XDlcScriptManager.RegBuffScript(10271080, "XBuffScript10271080", XTheatre6SkillBase)

--效果说明：· 持有【护盾】时，此技能伤害倍率提升30%；
--· 持有<坚毅>时，此技能伤害倍率提升30%。

function XBuffScript10271080:ScriptInit(isGainControl) --初始化
    self._damageMagicId = 10270114
    self.extraPermyriadProtector = 3000 --有格挡的增伤
    self.extraPermyriadBlock = 3000 --有护盾的增伤
    self.isDmgChanged = false
    self.BlockBuffId = 1025105
    self.extraPermyriad = 0
end

function XBuffScript10271080:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10271080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.isDmgChanged = false
end

function XBuffScript10271080:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self.isDmgChanged then return end
    self.extraPermyriad = 0 --重置增伤
    local originAttrib1 = self._proxy:GetNpcProtector(self._npcUUID) --取一下玩家的护盾值
    if originAttrib1 > 0 then
        self.extraPermyriad = self.extraPermyriad + self.extraPermyriadProtector --增加伤害
    end
    local originAttrib2 = self._proxy:GetBuffStacks(self._npcUUID, self.BlockBuffId) --取一下玩家的格挡层数
    if originAttrib2 > 0 then
        self.extraPermyriad = self.extraPermyriad + self.extraPermyriadBlock --增加伤害
    end
    local finalPermyriad = self.extraPermyriad + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    self.isDmgChanged = true
end

return XBuffScript10271080