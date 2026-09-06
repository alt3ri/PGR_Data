local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---剧毒控制器:
---挂在受击方身上：实现剧毒烧血逻辑
---挂在攻击方身上：为技能动态添加剧毒附魔
---@class XTheatre6PoisonedController:XTheatre6AffixControllerBase
local XTheatre6PoisonedController = XClass(XTheatre6AffixControllerBase, "XTheatre6PoisonedController")
XTheatre6PoisonedController.UpdateType = EUpdateType.Buff
XTheatre6PoisonedController.HitAffixTag = XGameplayTag.Missile_Theatre6_HitAffixType_Poisoned
XTheatre6PoisonedController.StackBuff = 1028103
XTheatre6PoisonedController.DmgTriggerBuff = 1028104
-- XTheatre6AffixControllerBase:RegisterControllerClass(XTheatre6PoisonedController, "Poisoned")


--region 按照固定间隔烧血的逻辑，经过数值调整改成了在技能命中时附加一次伤害

function XTheatre6PoisonedController:Ctor(proxy, npc)
    --self._dmgInterval = 5
    --self._dmgTime = 0
    self._PopCheck = 0
    self._dmgMagicId = 10281001
end

--function XTheatre6PoisonedController:Update(dt)
-- self:LogError(".....Poisoneding running")
--local time = self._time + dt
--self._time = time
--if time < self._dmgTime then return end
--self._dmgTime = time + self._dmgInterval
--self:CastDmg()
--end

function XTheatre6PoisonedController:OnLuaSkillStart(eventArgs)
    -- self:LogError(".....Poisoneding running")
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:GetBuffStacks(self._npcUUID,XTheatre6PoisonedController.StackBuff) > 0 then
        --self:LogError(".....剧毒控制器持有者用了个技能")
        --self:LogError(".....打印下持有者id"..self._npcUUID)
        --self:CastDmg()
        self:CastDmg()
    end
end

function XTheatre6PoisonedController:CastDmg()
    -- self:LogInfo("Poisoned Damage is Casted, Stack Buff Count = " .. self._buffCount)
    self._proxy:ApplyMagic(self._enemyUUID, self._npcUUID, self._dmgMagicId, 1) -- 视为对手对自己造成了一次伤害，参数1是发射者id，参数2是接收者id
    --self:LogError(".....造成伤害，打印下对面id"..self._enemyUUID)
    --self:LogError(".....造成伤害，打印下持有者id"..self._npcUUID)
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6PoisonedController.DmgTriggerBuff,1,1,1)
end

--endregion

function XTheatre6PoisonedController:AfterDamageCalc(eventArgs)
    --self:LogError(".....造成伤害后，打印下目标id"..eventArgs.Target)
    --self:LogError(".....打印技能使用的双方，打target"..eventArgs.Target)
    --self:LogError(".....打印技能使用的双方，打npcuuid"..self._npcUUID)
    if eventArgs.Target ~= self._npcUUID then return end
    if eventArgs.Id ~= self._dmgMagicId then return end
    --self:LogError(".....成功触发剧毒伤害了")
    local attack = self._proxy:GetNpcAttribValue(self._enemyUUID, 1) --取玩家的攻击属性
    self._buffCount = self._proxy:GetBuffStacks(self._npcUUID,XTheatre6PoisonedController.StackBuff)
    --self:LogError(".....看看剧毒层数"..self._buffCount)
    local extraDmg = self._buffCount * attack // 10
    --self:LogError(".....触发了剧毒增伤吗"..extraDmg)
    local PDSkillId = self._proxy:Theatre6GetWrestleDeriveSkill(self._npcUUID)
    if PDSkillId == 10283021 then
        extraDmg = extraDmg * (1 + self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) * 0.003  )
        --self:LogError(".....触发了携带拼刀技能2的强化剧毒，打印下剧毒伤害倍率"..extraDmg)
    end
    if self._proxy:GetBuffCountByKind(self._npcUUID,1025800) >= 1 then
        local DmgReduce = 1
        DmgReduce = DmgReduce * (1 + self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.PhysicalAmpP) / 10000)
        DmgReduce = DmgReduce * (1 - self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.PhysicalReductionP) / 10000)
        --self:LogError(".....打印下最终减伤"..DmgReduce)
        extraDmg = extraDmg * DmgReduce -- 存在PVP全减伤50%的特殊处理，伤害减半
        --self:LogError(".....触发减伤通知")
    end
    --self:LogError(".....准备改伤害，看看最终剧毒增伤正常吗"..extraDmg)
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, 0, extraDmg,
        eventArgs.FinalHackDamage)
    --1025113造成伤害时，修改造成的伤害量
    -- self:LogError(".....点燃层数"..self._buffCount)
    -- self:LogError(".....玩家攻击属性"..attack)
    -- self:LogError(".....伤害量修正值"..extraDmg)
end

--region 通过攻击给对方叠加点燃层数的逻辑

function XTheatre6PoisonedController:GetSkillCount()
    return self._atkCount
end

---@param count integer
function XTheatre6PoisonedController:AddSkillCount(count)
    self:AddAtkSkillCount(count)
end

function XTheatre6PoisonedController:OnAtkSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnAtkSkillCountChange(self, oldCount, newCount)
    if oldCount == 0 then
        self:RegisterAtkModifier()
    elseif newCount == 0 then
        self:UnregisterAtkModifier()
    end
end

--对于存在多段hit的子弹, 只允许第一段hit触发点燃效果
function XTheatre6PoisonedController:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate,
                                                      hitCount)
    if not XTheatre6AffixControllerBase.CheckCanTriggerByHit(self, missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate, hitCount) then return false end
    if hitCount > 1 then return false end
    return true
end

function XTheatre6PoisonedController:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
                                                srcType, triggeredTags, actionId, skillId, hitCount)
    if launcherNpcUUID ~= self._npcUUID then return end

    -- 只存在动态标签时,标记消耗技能次数
    if srcType == EHitTagSourceType.DynamicAtk then
        XTheatre6AffixControllerBase.OnLuaHitModify(self, missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
            srcType, triggeredTags, actionId, skillId, hitCount)
    end

    self:GetEnemyNpc():GetPoisonedController():CastStackBuff(1, self._npcUUID)
    self._proxy:Theatre6PopDamage(launcherNpcUUID, targetNpcUUID, 5, 0)
end

function XTheatre6PoisonedController:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XTheatre6PoisonedController:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end -- 对敌人挂上1028103buff时，触发计数，有计数时将在特殊子弹跳字
    if buffId == XTheatre6PoisonedController.StackBuff then
        self._PopCheck = 1
    end
end

function XTheatre6PoisonedController:OnLuaSpecialHit(eventArgs)
    if eventArgs._missileHitCount ~= 1 then return end
    if self._PopCheck == 1 then
        self._proxy:Theatre6PopDamage(self._npcUUID, self._enemyUUID, 23, 0)
        self._PopCheck = 0
    end
end

--endregion

return XTheatre6PoisonedController
