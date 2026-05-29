local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262020 : XTheatre6SkillBase
local XBuffScript10262020 = XDlcScriptManager.RegBuffScript(10262020, "XBuffScript10262020", XTheatre6SkillBase)

--效果说明：每次进入【狂暴】后触发：
--· 造成120%攻击伤害；
--· 消耗50点【怒火】，造成【击倒】；
--· 每次使用此技能，伤害额外提高80%攻击。

function XBuffScript10262020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._Count = 0
    self.ChanceCheck = 0
    self._stackCountHitDown = 0
    self._angerCost = 50
    self._damageMagicId = 10250044 --注册超算成功技1伤害id，目前是临时的
    if self._skillId == 10262021 then self._exDamageRateBase = 8000
    else if self._skillId == 10262022 then self._exDamageRateBase = 8000
    else self._exDamageRateBase = 8000
    end
    end
end

function XBuffScript10262020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end


function XBuffScript10262020:OnNpcAddBuffEvent(eventArgs)
    if eventArgs.BuffId ~= 1026101 then return end
    self._level:RequestInsertSkill(self._uuid,self.TargetSkill)
end

function XBuffScript10262020:OnLuaAttackerChange(eventArgs)
    ---出手权交换时重置计数
    if eventArgs._newAttackerUUID == self._npcUUID then
    self.ChanceCheck = 1
    end
end

function XBuffScript10262020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffAnger, self._angerCost)
    self._HitDownController:AddSkillCount(self._stackCountHitDown)
    self._hasChangedDamage = false
    self._Count = self._Count + 1
end

function XBuffScript10262020:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10262020:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    self._exDamageRate = self._Count * self._exDamageRateBase
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end

return XBuffScript10262020

--无法获取到击飞事件