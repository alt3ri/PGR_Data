local XTheatre6AffixControllerBase = require "Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase"
local XGameplayTag = require "Enum/XGameplayTag"

local EUpdateType = XTheatre6AffixControllerBase.EAffixControllerUpdateType
local EHitTagSourceType = XTheatre6AffixControllerBase.EHitTagSourceType

---耀斑控制器:耀斑值攒满时，触发耀斑爆发
---挂在攻击方身上
---@class XTheatre6SunController:XTheatre6AffixControllerBase
local XTheatre6SunController = XClass(XTheatre6AffixControllerBase, "XTheatre6SunController")
XTheatre6SunController.UpdateType = EUpdateType.None
XTheatre6SunController.StackBuff = 1027101
XTheatre6SunController.StackBuffSun = 1027101 --耀斑层数buffid，要改id

function XTheatre6SunController:Ctor(proxy, npc)
    --self._needDmgFix = false
    self._dmgFixActId = nil
    self._maxSun = 120
    --self:LogError(".....耀斑控制器注册")
end

function XTheatre6SunController:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType == ETheatre6SkillType.Main then
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6SunController.StackBuff,0,0,10)
    end
    if eventArgs._skillType == ETheatre6SkillType.Insert then
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6SunController.StackBuff,0,0,15)
    end
    if eventArgs._skillType == ETheatre6SkillType.Dodge then
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6SunController.StackBuff,0,0,20)
    end
    if eventArgs._skillType == ETheatre6SkillType.Wrestle then
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,XTheatre6SunController.StackBuff,0,0,20)
    end
end

function XTheatre6SunController:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    ------------执行------------
    self.SkillId = self._proxy:Theatre6GetInsertDeriveSkill(self._npcUUID)
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,self.StackBuffSun)
    --self:LogError(".....看一下耀斑值"..self.originAttrib1)
    if self.originAttrib1 >= self._maxSun then
        --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.StackBuffAngry,1,0,1)
        --self:LogError(".....耀斑爆发")
        if self.SkillId ~= 0 then
            self._proxy:Theatre6PopDamage(self._npcUUID, self._npcUUID, 21, 0)
            self._level:RequestInsertSkill(self._npcUUID,self.SkillId)
        end
        --self:LogError("打印一下角色技能list"..self.SkillId)
        --self._needDmgFix = true
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffSun, self.originAttrib1)
    end
end


return XTheatre6SunController
