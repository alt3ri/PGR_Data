local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---怒火控制器:怒火攒满时获得狂暴，怒火耗尽时消除狂暴
---挂在攻击方身上
---@class XTheatre6AngerController:XTheatre6AffixControllerBase
local XTheatre6AngerController = XClass(XTheatre6AffixControllerBase, "XTheatre6AngerController")
XTheatre6AngerController.UpdateType = EUpdateType.None
XTheatre6AngerController.StackBuff = 1025107
XTheatre6AngerController.StackBuffAnger = 1025107 --怒火buffid
XTheatre6AngerController.StackBuffAngry = 1025108 --狂暴buffid
XTheatre6AngerController.DictAngerRemoveSkill = { --怒火扣除Skill列表，手动维护
    [1026102] = true,
    [1026108] = true,
    [1026202] = true,
    [1026206] = true
}
XTheatre6AngerController.DictAngerAddSkill = { --怒火增加Skill列表，手动维护
    [1026301] = true,
    [1026401] = true,
    [1026102] = true,
    [1026105] = true,
    [1026106] = true,
    [1026107] = true,
    [1026203] = true,
    [1026204] = true,
    [1026209] = true,
    [1026505] = true
}

function XTheatre6AngerController:Ctor(proxy, npc)
    self.StaminaRecoverPermyriad = 2000
    self._needDmgFix = false
    self._dmgFixActId = nil
    self._maxAnger = 100
    self._angerCost = 10
    -- self:LogError(".....怒火控制器注册")
    self._dmgAddValue = 2000 --怒火期间增伤20%
end

function XTheatre6AngerController:GetSkillCount()
    return self._atkCount
end

---@param count integer
function XTheatre6AngerController:AddSkillCount(count)
    self:AddAtkSkillCount(count)
end

function XTheatre6AngerController:OnAtkSkillCountChange(oldCount, newCount)
    XTheatre6AffixControllerBase.OnAtkSkillCountChange(self, oldCount, newCount)
    self:SetBuffByAtkCount()
    if oldCount == 0 then
        self:RegisterAtkModifier()
    elseif newCount == 0 then
        self:UnregisterAtkModifier()
    end
end

function XTheatre6AngerController:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    ------------执行------------
    self.originAttrib1 = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffAngry)
    if self.originAttrib1 >= 1 then
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffAnger, self._angerCost)
        --self:LogError(".....玩家处于狂暴"..self.originAttrib1)
        self.originAttrib2 = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffAnger)
        if self.originAttrib2 <= 0 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffAngry, 1)
            --self:LogError(".....玩家怒火归零，退出狂暴"..self._npcUUID)
            self._needDmgFix = false
            self._npc:SetHandSideUx(nil)
        end
    else
        self.originAttrib2 = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffAnger)
        --self:LogError(".....抓到怒火点数"..self.originAttrib2)
        if self.originAttrib2 >= self._maxAnger then
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.StackBuffAngry, 1, 0, 1)
            --self:LogError(".....玩家怒火满，进入狂暴"..self._npcUUID)
            self._proxy:Theatre6PopDamage(self._npcUUID, self._npcUUID, 2, 0)
            self._needDmgFix = true
            self._npc:SetHandSideUx("FxUiTheatre6FightViolenTips")
        end
    end
end

function XTheatre6AngerController:BeforeDamageCalc(eventArgs)
    if not self._needDmgFix then return end
    if eventArgs.SkillActionId == self._dmgFixActId then return end
    if eventArgs.Target == self._npcUUID then return end
    --self:LogInfo("怒火控制器增伤")
    self._proxy:AddDamageMagicContextValue(eventArgs.ContextId, ENpcAttrib.Attack2AmpP, self._dmgAddValue, 0)
end

return XTheatre6AngerController
