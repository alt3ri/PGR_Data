local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282080 : XTheatre6SkillBase
local XBuffScript10282080 = XDlcScriptManager.RegBuffScript(10282080, "XBuffScript10282080", XTheatre6SkillBase)

--效果说明：对手每累计受到13次【剧毒】伤害后触发：
--· 自身每有40/30/20点【先机】属性，获得1点【先机】属性
--· 获得13点【魅惑】。

function XBuffScript10282080:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.DmgTriggerCount = 0
    self.DmgTriggerTarget = 13
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._StackBuffPD = 0
    self._hypno = 13
    self.WrestlePointCheck = {
        [1] = 40,
        [2] = 30,
        [3] = 20
    }
end

function XBuffScript10282080:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
end


function XBuffScript10282080:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self.poisonedBuff = self:GetNpc():GetPoisonedController().DmgTriggerBuff
end

function XBuffScript10282080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
        self._StackBuffPD = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) // self.WrestlePointCheck[self._lv]
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025901,1,1,self._StackBuffPD)
        self._hypnoController:CastStackBuff(self._hypno,self._npcUUID)
    end
end

function XBuffScript10282080:AfterDamageCalc(eventArgs)
    if eventArgs.Target == self._npcUUID then return end
    if eventArgs.Id ~= 10281001 then return end
    self.DmgTriggerCount = self.DmgTriggerCount + 1
    if self.DmgTriggerCount == self.DmgTriggerTarget then
        self._level:RequestInsertSkill(self._npcUUID,self._skillId)
        self.DmgTriggerCount = 0
    end
end

return XBuffScript10282080