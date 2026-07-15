local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---护盾控制器:
---@class XTheatre6ProtectorController:XTheatre6AffixControllerBase
local XTheatre6ProtectorController = XClass(XTheatre6AffixControllerBase, "XTheatre6ProtectorController")
XTheatre6ProtectorController.UpdateType = EUpdateType.Buff
XTheatre6ProtectorController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_Protector
XTheatre6ProtectorController.StackBuff = 1027107
-- XTheatre6AffixControllerBase:RegisterControllerClass(XTheatre6ProtectorController, "Protector")


function XTheatre6ProtectorController:Ctor(proxy, npc)
    --self._time = 0
    self.ProtectorDmgAdd = 0
    self._dmgAddValue = 0 --存在标记时增伤0%
    self:LogError(".....护盾控制器注册")
end

function XTheatre6ProtectorController:OnLuaAffixHitFly(eventArgs )
    if eventArgs._launcherUUID == self._npcUUID then return end --自己被击飞
    self.ProtectorDmgAdd = 1 --击飞时，获得加伤标记
end

function XTheatre6ProtectorController:OnLuaAffixHitDown(eventArgs )
    if eventArgs._launcherUUID == self._npcUUID then return end --自己被击倒
    self.ProtectorDmgAdd = 1 --击倒时，获得加伤标记
end

function XTheatre6ProtectorController:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then self.ProtectorDmgAdd = 0 end --技能结束时，清除加伤标记
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    self.originAttrib2 = self._proxy:GetNpcGameplayAttribValue(self._enemyUUID,ETheatre6AttribType.Stamina)
    if self.originAttrib1 <= 0 and self.originAttrib2 <= 0 then
        self._proxy:RemoveBuff(self._npcUUID, 111)
        --self._proxy:RemoveProtector()
        --self:LogError(".....清除全部护盾")
    end
end

function XTheatre6ProtectorController:BeforeDamageCalc(eventArgs)
    if self.ProtectorDmgAdd == 0 then return end
    if eventArgs.SkillActionId == self._dmgFixActId then return end
    if eventArgs.Target == self._npcUUID then return end
    self._proxy:AddDamageMagicContextValue(eventArgs.ContextId, ENpcAttrib.Attack2AmpP, self._dmgAddValue, 0) --有加伤标记时，受到伤害提升0%
end



return XTheatre6ProtectorController
