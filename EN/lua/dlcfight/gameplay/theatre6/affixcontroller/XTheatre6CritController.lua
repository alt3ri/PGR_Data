local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---暴击控制器:消耗心眼层数触发暴击
---挂在攻击方身上
---@class XTheatre6CritController:XTheatre6AffixControllerBase
local XTheatre6CritController = XClass(XTheatre6AffixControllerBase, "XTheatre6CritController")
XTheatre6CritController.UpdateType = EUpdateType.None
XTheatre6CritController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_Crit
XTheatre6CritController.StackBuff = 1025104

function XTheatre6CritController:Ctor(proxy, npc)
    -- self.StaminaRecoverPermyriad = 0
    self.StaminaRecoverValue = proxy:Theatre6GetConfig():GetInt("CriticalTL+")
    self._needDmgFix = false
    self._dmgFixActId = nil
end

function XTheatre6CritController:GetSkillCount()
    return self._atkCount
end

---@param count integer
function XTheatre6CritController:AddSkillCount(count)
    self:AddAtkSkillCount(count)
end

function XTheatre6CritController:OnAtkSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnAtkSkillCountChange(self, oldCount, newCount)
    self:SetBuffByAtkCount()
    if oldCount == 0 then
        self:RegisterAtkModifier()
    elseif newCount == 0 then
        self:UnregisterAtkModifier()
    end
end

function XTheatre6CritController:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate)
    -- --通过静态标签触发
    -- if srcType & EHitTagSourceType.StaticAtk ~= 0 then return true end

    --暂时禁止通过静态标签触发
    if srcType & EHitTagSourceType.StaticAtk ~= 0 then
        -- local _, misTemplateId = self._proxy:MissileUUIDToTemplateId(missileUUID)
        -- self:LogError("Static Crit Tag Detected, missile Id = " .. misTemplateId)
        return false
    end

    --通过动态标签触发
    if (srcType & EHitTagSourceType.DynamicAtk ~= 0) and launcherNpcUUID == self._npcUUID then return true end
    return false
end

function XTheatre6CritController:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType,
                                                triggeredTags, actionId, skillId, hitCount)
    if launcherNpcUUID ~= self._npcUUID then return end

    XTheatre6AffixControllerBase.OnLuaHitModify(self, missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType,
        triggeredTags, actionId, skillId, hitCount)

    local skillId = self._proxy:Theatre6GetSkillByAction(launcherNpcUUID, actionId)

    --仅在activate子弹的第一段命中触发跳字及体力恢复
    local hasPopText = false
    if isActivate and hitCount == 1 then
        hasPopText = true
        self._proxy:Theatre6PopDamage(launcherNpcUUID, targetNpcUUID, 1, 0)
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.StaminaRecoverValue)
    end

    --准备在接下来的伤害事件中执行伤害修正
    self._needDmgFix = true
    self._dmgFixActId = actionId

    --发送暴击事件
    local eventType = EFightLuaEvent.Theatre6AffixCritDamage
    local eventArgs = XEventManager.GetEventArgs(eventType) --[[@as Theatre6HitAffixArgs]]
    eventArgs._missileUUID = missileUUID
    eventArgs._launcherUUID = launcherNpcUUID
    eventArgs._targetUUID = targetNpcUUID
    eventArgs._isActivate = isActivate and true or false
    eventArgs._srcType = srcType
    eventArgs._triggeredTags = triggeredTags
    eventArgs._actionId = actionId
    eventArgs._skillId = skillId
    eventArgs._missileHitCount = hitCount
    eventArgs._hasPopText = hasPopText
    self:DispatchLuaEvent(eventType, eventArgs)
end

function XTheatre6CritController:BeforeDamageCalc(eventArgs)
    if not self._needDmgFix then return end
    if eventArgs.SkillActionId ~= self._dmgFixActId then return end
    if eventArgs.Launcher ~= self._npcUUID then return end
    self._needDmgFix = false
    self._dmgFixActId = nil
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalPermyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, true)
end

return XTheatre6CritController
