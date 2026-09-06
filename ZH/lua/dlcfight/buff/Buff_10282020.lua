local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282020 : XTheatre6SkillBase
local XBuffScript10282020 = XDlcScriptManager.RegBuffScript(10282020, "XBuffScript10282020", XTheatre6SkillBase)

--效果说明：· 每累计造成13/11/9层【剧毒】时触发：
--· 触发1次【剧毒】伤害；
--· 获得1点【魅惑】。

function XBuffScript10282020:ScriptInit(isGainControl) --初始化
    self._stackCount = 1
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._hypnoController = self:GetNpc():GetHypnoController()
    --self.PoisonedCount = 1 -- 造成的剧毒伤害次数
    self.PoisonedTimeCount = 0 --剧毒计数器
    self.PoisonedTimeTarget = {
        --不同等级的默认剧毒层数
        [1] = 13,
        [2] = 11,
        [3] = 9
    }

end

function XBuffScript10282020:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript10282020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self.poisonedBuff = self:GetNpc():GetPoisonedController().StackBuff
end

function XBuffScript10282020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self._skillId then
        self._poisonedController:CastDmg()
        self._hypnoController:CastStackBuff(self._stackCount, self._npcUUID)
    end
end

function XBuffScript10282020:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._npcUUID then return end
    if buffId ~= self.poisonedBuff then return end --中毒
    self.PoisonedTimeCount = self.PoisonedTimeCount + 1
    if self.PoisonedTimeCount == self.PoisonedTimeTarget[self._lv]  then
        self._level:RequestInsertSkill(self._npcUUID,self._skillId)
        self.PoisonedTimeCount = 0
    end
end

return XBuffScript10282020