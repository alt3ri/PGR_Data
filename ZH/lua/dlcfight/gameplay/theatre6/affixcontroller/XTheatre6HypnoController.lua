local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---魅惑控制器:魅惑攒满时，触发失心
---挂在攻击方身上
---@class XTheatre6HypnoController:XTheatre6AffixControllerBase
local XTheatre6HypnoController = XClass(XTheatre6AffixControllerBase, "XTheatre6HypnoController")
XTheatre6HypnoController.UpdateType = EUpdateType.None
XTheatre6HypnoController.StackBuff = 1028101
XTheatre6HypnoController.LostHeartTriggerBuff = 1028102 --失心触发buffid

function XTheatre6HypnoController:Ctor(proxy, npc)
    --self._needDmgFix = false
    self._dmgFixActId = nil
    self.SkillCount = 0
    self.TLCost = 15
    self.TLRecover = 15


    local PDSkillId = self._proxy:Theatre6GetWrestleDeriveSkill(self._npcUUID)
    if PDSkillId == 10283011 then
        self._maxHypno = 13 - ( self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) // 200  )

        if self._maxHypno < 9 then self._maxHypno = 9 end
    else
        self._maxHypno = 13
    end

    --self:LogError(".....魅惑控制器注册")
end

function XTheatre6HypnoController:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6HypnoController.StackBuff,0,0,1)
end

function XTheatre6HypnoController:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    ------------执行------------
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,self.StackBuff)
    if self.originAttrib1 >= self._maxHypno then
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6HypnoController.LostHeartTriggerBuff,0,0,1)
        --self:LogError(".....惑梦满")
    end
    if self.SkillCount == 1 then -- 计数-失心开始
        self.SkillCount = 2
        --self:LogError(".....失心标记步进1")
    elseif self.SkillCount == 2 then -- 计数-失心触发后，检查使用的是否是1号位技能
        self.SkillId = self._proxy:Theatre6GetMainSkill(self._npcUUID)[0]
        if self.SkillId == eventArgs._skillId then -- 检查到确实是1号位技能
            self.SkillCount = 0 -- 记录为成功触发
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID, XTheatre6HypnoController.LostHeartTriggerBuff, 1) -- 删除失心标记
            --self:LogError(".....失心标记删除")
        end
    end
end

function XTheatre6HypnoController:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XTheatre6HypnoController:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= XTheatre6HypnoController.LostHeartTriggerBuff then return end --触发失心标记
    self.SkillId = self._proxy:Theatre6GetMainSkill(self._npcUUID)[0]
    self.SkillCount = 1
    --self:LogError(".....挂上失心标记了")
    if self.SkillId and self.SkillId ~= 0 then
        self._proxy:Theatre6PopDamage(self._npcUUID, self._npcUUID, 24, 0)
        self._level:RequestInsertSkill(self._npcUUID,self.SkillId)
        self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._enemyUUID,ETheatre6AttribType.Stamina)
        if self.originAttrib1 > 0 then
            self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.TLCost, 0) --扣除对面15体力
            self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复自己15体力
        end
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, XTheatre6HypnoController.StackBuff, self._maxHypno)
        --self:LogError(".....挂上失心标记，清除buff")
    end
end



return XTheatre6HypnoController
