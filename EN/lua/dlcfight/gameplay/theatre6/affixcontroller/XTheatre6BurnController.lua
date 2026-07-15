local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---点燃控制器:
---挂在受击方身上：实现点燃烧血逻辑
---挂在攻击方身上：为技能动态添加点燃附魔
---@class XTheatre6BurnController:XTheatre6AffixControllerBase
local XTheatre6BurnController = XClass(XTheatre6AffixControllerBase, "XTheatre6BurnController")
XTheatre6BurnController.UpdateType = EUpdateType.Buff
XTheatre6BurnController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_Burn
XTheatre6BurnController.StackBuff = 1025101
-- XTheatre6AffixControllerBase:RegisterControllerClass(XTheatre6BurnController, "Burn")


--region 按照固定间隔烧血的逻辑，经过数值调整改成了在技能命中时附加一次伤害

function XTheatre6BurnController:Ctor(proxy, npc)
    --self._dmgInterval = 5
    --self._dmgTime = 0
    --self._time = 0
    self._dmgMagicId = 10251501
end

--function XTheatre6BurnController:Update(dt)
-- self:LogError(".....burning running")
--local time = self._time + dt
--self._time = time
--if time < self._dmgTime then return end
--self._dmgTime = time + self._dmgInterval
--self:CastDmg()
--end

function XTheatre6BurnController:OnLuaSkillStart(eventArgs)
    -- self:LogError(".....burning running")
    if eventArgs._launcherUUID == self._npcUUID then return end
    self:CastDmg()
end

function XTheatre6BurnController:CastDmg()
    -- self:LogInfo("Burn Damage is Casted, Stack Buff Count = " .. self._buffCount)
    self._proxy:ApplyMagic(self._enemyUUID, self._npcUUID, self._dmgMagicId, 1)
end

--endregion

function XTheatre6BurnController:AfterDamageCalc(eventArgs)
    if eventArgs.Target ~= self._npcUUID then return end
    if eventArgs.Id ~= self._dmgMagicId then return end
    local attack = self._proxy:GetNpcAttribValue(self._enemyUUID, 1) --取玩家的攻击属性
    local extraDmg = self._buffCount * attack // 10
    if self._proxy:GetBuffCountByKind(self._npcUUID,1025800) then
        extraDmg = extraDmg // 2 -- 存在PVP全减伤50%的特殊处理，伤害减半
    end
    
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, extraDmg, eventArgs.ElementDamage,
        eventArgs.FinalHackDamage)
    --1025113造成伤害时，修改造成的伤害量
    -- self:LogError(".....点燃层数"..self._buffCount)
    -- self:LogError(".....玩家攻击属性"..attack)
    -- self:LogError(".....伤害量修正值"..extraDmg)
end

--region 通过攻击给对方叠加点燃层数的逻辑

function XTheatre6BurnController:GetSkillCount()
    return self._atkCount
end

---@param count integer
function XTheatre6BurnController:AddSkillCount(count)
    self:AddAtkSkillCount(count)
end

function XTheatre6BurnController:OnAtkSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnAtkSkillCountChange(self, oldCount, newCount)
    if oldCount == 0 then
        self:RegisterAtkModifier()
    elseif newCount == 0 then
        self:UnregisterAtkModifier()
    end
end

--对于存在多段hit的子弹, 只允许第一段hit触发点燃效果
function XTheatre6BurnController:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate,
                                                      hitCount)
    if not XTheatre6AffixControllerBase.CheckCanTriggerByHit(self, missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate, hitCount) then return false end
    if hitCount > 1 then return false end
    return true
end

function XTheatre6BurnController:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
                                                srcType, triggeredTags, actionId, skillId, hitCount)
    if launcherNpcUUID ~= self._npcUUID then return end

    -- 只存在动态标签时,标记消耗技能次数
    if srcType == EHitTagSourceType.DynamicAtk then
        XTheatre6AffixControllerBase.OnLuaHitModify(self, missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
            srcType, triggeredTags, actionId, skillId, hitCount)
    end

    self:GetEnemyNpc():GetBurnController():CastStackBuff(1, self._npcUUID)
    self._proxy:Theatre6PopDamage(launcherNpcUUID, targetNpcUUID, 5, 0)
end

--endregion

return XTheatre6BurnController
