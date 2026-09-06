local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10284010 : XTheatre6SkillBase
local XBuffScript10284010 = XDlcScriptManager.RegBuffScript(10284010, "XBuffScript10284010", XTheatre6SkillBase)

--效果说明：· 造成【失心】；
--· {被动}每有75点【超算】属性，造成【失心】时，额外吸取对手1点【体力值】；
--· 造成【击飞】。

function XBuffScript10284010:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.LostHeartTriggerBuff = self:GetNpc():GetHypnoController().LostHeartTriggerBuff
    self._stackbuff = 1028101
    self._stackCount = 6
    self._stackCountHitFly = 1
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self.ChanceCheck = 0
end


--self:LogError(".....初始化完成")

function XBuffScript10284010:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._HitFlyController:AddSkillCount(self._stackCountHitFly)
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.LostHeartTriggerBuff)

end

--function XBuffScript10284010:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end

function XBuffScript10284010:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript10284010:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.LostHeartTriggerBuff then return end --触发失心标记
    self.SkillId = self._proxy:Theatre6GetMainSkill(self._npcUUID)
    self.TLCost = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock) // 75
    self.TLRecover = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock) // 75
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复自己N体力
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.TLCost, 0) --扣除对面N体力
end


return XBuffScript10284010