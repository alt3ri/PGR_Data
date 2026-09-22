local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281110 : XTheatre6SkillBase
local XBuffScript10281110 = XDlcScriptManager.RegBuffScript(10281110, "XBuffScript10281110", XTheatre6SkillBase)

--效果说明：· 获得2点【魅惑】；
--· 每造成过1次【失心】，此技能伤害倍率提升30%。

function XBuffScript10281110:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._critController = self:GetNpc():GetCritController()
    self._stackCount = 2
    self._damageMagicId = 10280001 --临时伤害id，要改
    --.extraPermyriad = 3000 --每触发过一次失心的增伤
    self.LostHeartCount = 0
    self.isDmgChanged = false
    self.extraPermyriadTatal = 0
    self.extraPermyriad = {
        [1] = 2000,
        [2] = 4000,
        [3] = 6000
    }
end

function XBuffScript10281110:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

--self:LogError(".....初始化完成")

function XBuffScript10281110:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hypnoController:CastStackBuff(self._stackCount,self._npcUUID)
    self.isDmgChanged = false
end

--function XBuffScript10281110:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end

function XBuffScript10281110:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self.isDmgChanged then return end
    self.extraPermyriadTatal = 0 --重置增伤
    if self.LostHeartCount > 0 then
        self.extraPermyriadTatal = self.extraPermyriad[self._lv] * self.LostHeartCount --增加伤害
    end
    local finalPermyriad = self.extraPermyriadTatal + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    self.isDmgChanged = true
end

function XBuffScript10281110:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= 1028102 then return end --触发失心标记
    self.LostHeartCount = self.LostHeartCount + 1
end

return XBuffScript10281110