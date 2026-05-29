local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---击飞控制器:允许运行时动态开关技能的击飞效果(技能本身需要支持击飞表现)
---挂在攻击方身上
---@class XTheatre6HitFlyController:XTheatre6AffixControllerBase
local XTheatre6HitFlyController = XClass(XTheatre6AffixControllerBase, "XTheatre6HitFlyController")
XTheatre6HitFlyController.UpdateType = EUpdateType.None
XTheatre6HitFlyController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_HitFly
-- XTheatre6AffixControllerBase:RegisterCotrollerClass(XTheatre6HitFlyController, "HitFly")

function XTheatre6HitFlyController:GetSkillCount()
    return self._atkCount
end

---@param count integer
function XTheatre6HitFlyController:AddSkillCount(count)
    self:AddAtkSkillCount(count)
end

function XTheatre6HitFlyController:OnAtkSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnAtkSkillCountChange(self, oldCount, newCount)
    if oldCount == 0 then
        self:RegisterAtkModifier()
    elseif newCount == 0 then
        self:UnregisterAtkModifier()
    end
end

function XTheatre6HitFlyController:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
                                                  srcType, triggeredTags, actionId, skillId, hitCount)
    if launcherNpcUUID ~= self._npcUUID then return end
    -- if not isActivate then return end


    -- 只存在动态标签时,标记消耗技能次数
    if srcType == EHitTagSourceType.DynamicAtk then
        XTheatre6AffixControllerBase.OnLuaHitModify(self, missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
            srcType, triggeredTags, actionId, skillId, hitCount)
    end

    local hasPopText = false
    -- 只在子弹的第一段判定中触发跳字
    if hitCount == 1 then
        self._proxy:Theatre6PopDamage(launcherNpcUUID, targetNpcUUID, 7, 0)
        hasPopText = true
    end

    --发送击飞事件
    local eventType = EFightLuaEvent.Theatre6AffixHitFly
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

return XTheatre6HitFlyController
