local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---击倒控制器:发送通知
---挂在攻击方身上
---@class XTheatre6HitDownController:XTheatre6AffixControllerBase
local XTheatre6HitDownController = XClass(XTheatre6AffixControllerBase, "XTheatre6HitDownController")
XTheatre6HitDownController.UpdateType = EUpdateType.None
XTheatre6HitDownController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_HitDown
-- XTheatre6AffixControllerBase:RegisterCotrollerClass(XTheatre6HitDownController, "HitDown")

function XTheatre6HitDownController:GetSkillCount()
    return self._atkCount
end

---@param count integer
function XTheatre6HitDownController:AddSkillCount(count)
    self:AddAtkSkillCount(count)
end

function XTheatre6HitDownController:OnAtkSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnAtkSkillCountChange(self, oldCount, newCount)
    if oldCount == 0 then
        self:RegisterAtkModifier()
    elseif newCount == 0 then
        self:UnregisterAtkModifier()
    end
end

function XTheatre6HitDownController:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType,
                                                   triggeredTags, actionId, skillId, hitCount)
    if launcherNpcUUID ~= self._npcUUID then return end
    -- if not isActivate then return end

    -- 只存在动态标签时,标记消耗技能次数
    if srcType == EHitTagSourceType.DynamicAtk then
        XTheatre6AffixControllerBase.OnLuaHitModify(self, missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
            srcType, triggeredTags, actionId, skillId, hitCount)
    end

    local hasPopText = false
    --只在子弹的第一段判定中触发跳字
    if hitCount == 1 then
        self._proxy:Theatre6PopDamage(launcherNpcUUID, targetNpcUUID, 1, 0)
        hasPopText = true
    end

    -- self:LogInfo("Hit down is triggered")

    --发送击飞事件
    local eventType = EFightLuaEvent.Theatre6AffixHitDown
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
    eventArgs._hasPopText = hasPopText
    self:DispatchLuaEvent(eventType, eventArgs)
end

return XTheatre6HitDownController
