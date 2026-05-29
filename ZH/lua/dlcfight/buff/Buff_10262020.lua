local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262020 : XTheatre6SkillBase
local XBuffScript10262020 = XDlcScriptManager.RegBuffScript(10262020, "XBuffScript10262020", XTheatre6SkillBase)

--效果说明：每次进入【狂暴】后触发：
--· 造成120%攻击伤害；
--· 消耗30点【怒火】，造成【击倒】；
--· 每次使用此技能，伤害额外提高40/60/80%攻击。

function XBuffScript10262020:ScriptInit(isGainControl) --初始化
    self._Count             = 0
    self._stackCountHitDown = 1
    self._angerCost         = 30
    self._damageMagicId     = 1026202 --注册超算成功技1伤害id，5.10已换
    self.StackBuffAnger     = 1025107 --怒火
    self._hasChangedDamage  = false   --是否已经改变过伤害
    self.angryBuffId        = 1025108 --狂暴Buff
    self.dictExDmgRateBase  = {
        --不同等级提升的技能倍率
        [1] = 4000,
        [2] = 6000,
        [3] = 8000
    }
end

function XBuffScript10262020:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10262020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetNpc():GetHitDownController()
end

function XBuffScript10262020:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --狂暴时触发技能
    if npcUUID ~= self._uuid then return end
    if buffId ~= self.angryBuffId then return end
    self._level:RequestInsertSkill(self._uuid, self._skillId)
end

function XBuffScript10262020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --重置伤害改变记录
    self._hasChangedDamage = false
    --触发逻辑：判断当前怒火是否足够释放额外效果
    local curAngerStack = self._proxy:GetBuffStacks(self._uuid, self.StackBuffAnger)
    if curAngerStack < self._angerCost then return end
    --触发效果：减少怒火buff层数 + 击倒
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffAnger, self._angerCost)
    self._HitDownController:AddSkillCount(self._stackCountHitDown)
end

function XBuffScript10262020:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local exDamageRate = self._Count * self.dictExDmgRateBase[self._lv]
    local FinalDMGRate = eventArgs.PhysicalPermyriad + exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    self._Count = self._Count + 1
    self._hasChangedDamage = true
end

return XBuffScript10262020
