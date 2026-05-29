local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---暴击控制器:消耗心眼层数触发暴击
---挂在攻击方身上
---@class XTheatre6BlockController:XTheatre6AffixControllerBase
local XTheatre6BlockController = XClass(XTheatre6AffixControllerBase, "XTheatre6BlockController")
XTheatre6BlockController.UpdateType = EUpdateType.None
XTheatre6BlockController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_Block
XTheatre6BlockController.StackBuff = 1025105
XTheatre6BlockController.SuperArmor = 105244
XTheatre6BlockController.PopDamageId = 1

function XTheatre6BlockController:Ctor(proxy, npc)
    self._isFirstHit = false --标记当前受击是否为技能的第一次命中
    self._hasArmor = false   --是否已经添加霸体buff

    self._needDmgFix = false
    self._dmgFixActId = nil
    -- self._dmgReducValue = 5000
    self._dmgReducValue = proxy:Theatre6GetConfig():GetInt("BlockDmg-")
end

function XTheatre6BlockController:GetSkillCount()
    return self._defCount
end

---@param count integer
function XTheatre6BlockController:AddSkillCount(count)
    self:AddDefSkillCount(count)
end

function XTheatre6BlockController:OnDefSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnDefSkillCountChange(self, oldCount, newCount)
    self:SetBuffByDefCount()
    if oldCount == 0 then
        self:RegisterDefModifier()
    elseif newCount == 0 then
        self:UnregisterDefModifier()
    end
end

function XTheatre6BlockController:OnLuaSkillStart(eventArgs)
    XTheatre6AffixControllerBase.OnLuaSkillStart(self, eventArgs)
    if eventArgs._targetUUID ~= self._npcUUID then return end
    self._isFirstHit = true
end

function XTheatre6BlockController:OnLuaSkillEnd(eventArgs)
    XTheatre6AffixControllerBase.OnLuaSkillEnd(self, eventArgs)
    if eventArgs._targetUUID ~= self._npcUUID then return end
    self._isFirstHit = false
    self:RemoveArmor()
end

--决定是否尝试触发格挡效果
function XTheatre6BlockController:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate)
    --如果不是自己挨打, 则不尝试触发
    if targetNpcUUID ~= self._npcUUID then return false end

    --如果srcType不是DynamicDef, 则不尝试触发
    if srcType & EHitTagSourceType.DynamicDef == 0 then return false end

    --如果前置状态是受击状态, 则不尝试触发
    if not self._npc:CanBlock() then return false end

    --如果是技能的第一段攻击, 则尝试触发
    if self._isFirstHit then return true end

    --如果不是技能的第一段攻击, 只在续防时尝试触发
    return self._npc:IsInBlock()
end

function XTheatre6BlockController:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType,
                                                 triggeredTags, actionId, skillId, hitCount)
    if targetNpcUUID ~= self._npcUUID then return end

    --仅在技能的第一段hit中标记消耗格挡次数, 无论是否造成破防
    if self._isFirstHit then
        self._isFirstHit = false
        self._isTriggered = true
    end

    if self:CheckCanBreakBlock(triggeredTags) then
        return self:BreakBlock(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType, triggeredTags, actionId,
            skillId, hitCount)
    else
        return self:Block(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType, triggeredTags, actionId,
            skillId, hitCount)
    end
end

---@param triggeredTags table<EGameplayTag, boolean> 成功触发的全部效果列表
function XTheatre6BlockController:CheckCanBreakBlock(triggeredTags)
    return triggeredTags[XGameplayTag.Missile_Theatre6_HitAffixType_HitFly] or
        triggeredTags[XGameplayTag.Missile_Theatre6_HitAffixType_HitDown]
end

function XTheatre6BlockController:BreakBlock(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType,
                                             triggeredTags, actionId, skillId, hitCount)
    local npc = self._npc
    if not npc:IsInBlock() then return end

    -- local skillId = self._proxy:Theatre6GetSkillByAction(launcherNpcUUID, actionId)
    -- self:LogInfo("BreakBlock is triggered, skill = " .. skillId)

    self:RemoveArmor()

    npc:OnBreakBlock()

    --发送破防事件
    local eventType = EFightLuaEvent.Theatre6AffixBlockBreak
    local eventArgs = XEventManager.GetEventArgs(eventType) --[[@as Theatre6HitAffixArgs]]
    -- eventArgs._contextId = contextId
    eventArgs._missileUUID = missileUUID
    eventArgs._launcherUUID = launcherNpcUUID
    eventArgs._targetUUID = targetNpcUUID
    eventArgs._isActivate = isActivate and true or false
    eventArgs._srcType = srcType
    eventArgs._triggeredTags = triggeredTags
    eventArgs._actionId = actionId
    eventArgs._skillId = skillId
    eventArgs._missileHitCount = hitCount
    eventArgs._hasPopText = false
    self:DispatchLuaEvent(eventType, eventArgs)
end

function XTheatre6BlockController:Block(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType, triggeredTags,
                                        actionId, skillId, hitCount)
    -- local skillId = self._proxy:Theatre6GetSkillByAction(launcherNpcUUID, actionId)
    -- self:LogInfo("Block is triggered, skill = " .. skillId)

    local npc = self._npc
    self:AddArmor()
    npc:OnBlock()

    -- Todo: 飘字 + 伤害修正 + 超算获取率修正
    local hasPopText = isActivate and hitCount == 1
    if hasPopText then self._proxy:Theatre6PopDamage(launcherNpcUUID, targetNpcUUID, 6, 0) end

    --准备在接下来的伤害事件中执行伤害修正
    self._needDmgFix = true
    self._dmgFixActId = actionId

    --发送格挡事件
    local eventType = EFightLuaEvent.Theatre6AffixBlock
    local eventArgs = XEventManager.GetEventArgs(eventType) --[[@as Theatre6HitAffixArgs]]
    -- eventArgs._contextId = contextId
    eventArgs._missileUUID = missileUUID
    eventArgs._launcherUUID = launcherNpcUUID
    eventArgs._targetUUID = targetNpcUUID
    eventArgs._isActivate = isActivate and true or false
    eventArgs._srcType = srcType
    eventArgs._triggeredTags = triggeredTags
    eventArgs._actionId = actionId
    eventArgs._skillId = skillId
    eventArgs._missileHitCount = hitCount
    eventArgs._hasPopText = hasPopText and true or false
    self:DispatchLuaEvent(eventType, eventArgs)
end

function XTheatre6BlockController:BeforeDamageCalc(eventArgs)
    if not self._needDmgFix then return end
    if eventArgs.SkillActionId ~= self._dmgFixActId then return end
    if eventArgs.Target ~= self._npcUUID then return end
    self._needDmgFix = false
    self._dmgFixActId = nil
    -- self:LogInfo("block controller damge change is called")
    self._proxy:AddDamageMagicContextValue(eventArgs.ContextId, ENpcAttrib.DmgReduction, self._dmgReducValue, 0)
end

function XTheatre6BlockController:AddArmor()
    if self._hasArmor then return end
    self._hasArmor = true
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.SuperArmor, 0, 0, 1)
end

function XTheatre6BlockController:RemoveArmor()
    if not self._hasArmor then return end
    self._hasArmor = false
    self._proxy:RemoveBuff(self._uuid, self.SuperArmor)
end

return XTheatre6BlockController
