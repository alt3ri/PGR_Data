local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282050 : XTheatre6SkillBase
local XBuffScript10282050 = XDlcScriptManager.RegBuffScript(10282050, "XBuffScript10282050", XTheatre6SkillBase)

--效果说明：本场战斗中首次累计造成4/3/2次【失心】后触发：
--· 造成100%攻击伤害；
--· 对手每有4点【战意】属性，自身吸取其1点【战意】属性；
--· 造成【击飞】。

function XBuffScript10282050:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.LostHeartTimeCount = 0
    self.LostHeartTimeCountTarget = {
        --不同等级的默认剧毒层数
        [1] = 4,
        [2] = 3,
        [3] = 2
    }
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self.AddTLBuff = 1028105 -- 获得战意属性buff
    self.SubtractTLBuff = 1028106 -- 减少战意属性buff
    self.LostHeartBuff = self:GetNpc():GetHypnoController().LostHeartTriggerBuff
    self.ChanceCheck = 0
end

function XBuffScript10282050:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript10282050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
        local Stamina = self._proxy:GetNpcGameplayAttribMaxValue(self._enemyUUID,ETheatre6AttribType.Stamina) // 4
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.AddTLBuff,1,1,Stamina)
        self._proxy:ApplyMagic(self._enemyUUID,self._enemyUUID,self.SubtractTLBuff,1,1,Stamina)
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,Stamina)
        if self._proxy:GetNpcGameplayAttribValue(self._enemyUUID,ETheatre6AttribType.Stamina) > self._proxy:GetNpcGameplayAttribMaxValue(self._enemyUUID,ETheatre6AttribType.Stamina) then
            local StaminaCost = self._proxy:GetNpcGameplayAttribValue(self._enemyUUID,ETheatre6AttribType.Stamina) - self._proxy:GetNpcGameplayAttribMaxValue(self._enemyUUID,ETheatre6AttribType.Stamina)
            self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID,-StaminaCost) -- 修改敌方体力值，使其实时体力值不要溢出体力值上限
        end
        self._HitFlyController:AddSkillCount(1)
    end
end

function XBuffScript10282050:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.LostHeartBuff then return end --失心
    self.LostHeartTimeCount = self.LostHeartTimeCount + 1
    if self.LostHeartTimeCount == self.LostHeartTimeCountTarget[self._lv]  then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            self.ChanceCheck = 1
        end
    end
end

return XBuffScript10282050