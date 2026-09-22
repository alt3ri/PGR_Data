local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282060 : XTheatre6SkillBase
local XBuffScript10282060 = XDlcScriptManager.RegBuffScript(10282060, "XBuffScript10282060", XTheatre6SkillBase)

--效果说明：   对手身上的【剧毒】层数每次>=10层时触发：
--· 清空对手【剧毒】层数；
--· 获得3/4/5点【魅惑】，每使用过1次此技能，额外获得1点【魅惑】，至多额外获得5点。

function XBuffScript10282060:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.HypnoDefaultCount = {
        --不同等级的默认魅惑层数
        [1] = 3,
        [2] = 4,
        [3] = 5
    }
    local HypnoExtraCountMax = 5
    self.HypnoCountMax = HypnoExtraCountMax + self.HypnoDefaultCount[self._lv]
    self.PoisonedTarget = 10
    self.Poisoned = 0
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self.poisonedBuff = self:GetNpc():GetPoisonedController().StackBuff
    self.UseCount = 0
end

function XBuffScript10282060:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript10282060:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10282060:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
        self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self.poisonedBuff,999) -- 移除目标的剧毒
        local hypnoCount = self.UseCount + self.HypnoDefaultCount[self._lv]
        if hypnoCount > self.HypnoCountMax then hypnoCount = self.HypnoCountMax end --处理一下魅惑层数上限
        self._hypnoController:CastStackBuff(hypnoCount, self._npcUUID)
        self.UseCount = self.UseCount + 1
        self.Poisoned = 0
    end
end

function XBuffScript10282060:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._npcUUID then return end
    if buffId ~= self.poisonedBuff then return end --中毒
    self.Poisoned = self.Poisoned + 1
    if self.Poisoned == self.PoisonedTarget then
        self._level:RequestInsertSkill(self._npcUUID,self._skillId)
    end
end

return XBuffScript10282060