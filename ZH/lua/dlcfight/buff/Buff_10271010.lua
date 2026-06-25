local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10271010 : XTheatre6SkillBase
local XBuffScript10271010 = XDlcScriptManager.RegBuffScript(10271010, "XBuffScript10271010", XTheatre6SkillBase)

-- 效果说明：
-- · 获得【生命】属性3%的【护盾】；
-- · 造成【击飞】。

function XBuffScript10271010:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
end

function XBuffScript10271010:ScriptInit(isGainControl)
    self._selfDamageMagicId = 10278001
    self._selfDamageRatio = 0.03
    self.Protector = self:GetNpc():GetProtectorController()
    self.StackBuff = 1027102 --给护盾Buff
end

function XBuffScript10271010:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self._selfDamageMagicId, 1, 0, 1)
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.StackBuff) --给玩家发一下护盾
    local hitFlyController = self:GetNpc():GetHitFlyController()
    if hitFlyController then
        hitFlyController:AddSkillCount(1)
    end
end

--function XBuffScript10271010:AfterDamageCalc(eventArgs)
    --if eventArgs.Id ~= self._selfDamageMagicId then return end
    --if eventArgs.Launcher ~= self._npcUUID then return end
    --if eventArgs.Target ~= self._npcUUID then return end

    --local maxLife = self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life)
    --local damage = maxLife * self._selfDamageRatio
    --self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, damage, eventArgs.ElementDamage,eventArgs.FinalHackDamage)
--end

--function XBuffScript10271010:Terminate()
    --self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    --XTheatre6SkillBase.Terminate(self)
--end

return XBuffScript10271010
