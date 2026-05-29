local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261120 : XTheatre6SkillBase
local XBuffScript10261120 = XDlcScriptManager.RegBuffScript(10261120, "XBuffScript10261120", XTheatre6SkillBase)

--效果说明：
--消耗自身【体力值】的20%，每消耗1点【体力值】，伤害额外提高12/16/20%攻击；

function XBuffScript10261120:ScriptInit(isGainControl) --初始化
    self.damageMagicId = 1026398                        --伤害magic
    self.extraPermyriad = {                             --提升伤害比例(万分比）
        [1] = 1200,
        [2] = 1600,
        [3] = 2000
    }                          
    self.totalExctraPermyriad = 0                      --总的提升伤害比例
    self.damageTimes = 2                               --伤害段数
    self.reduceStaminaCost = 1                         --每消耗x点体力，提升伤害
    self.dictReduceStaminaPermyriad = 2000             --额外扣除体力值（万分比）
    self.trigger = false --体力是否足够，满足后才会修改伤害
end

function XBuffScript10261120:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --保底处理，如果不是自己/技能id不对，直接退出
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    
    --体力处理
    local stamina = self._proxy:GetNpcGameplayAttribValue(self._uuid, ETheatre6AttribType.Stamina)
    local reduceStamina = math.floor(stamina * self.dictReduceStaminaPermyriad / 10000)
    if reduceStamina <= 0 then return end
    --扣除体力
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -reduceStamina, 0)
    
    --判断要改多少伤害
    self.totalExctraPermyriad = reduceStamina * self.extraPermyriad[self._lv] / self.reduceStaminaCost / self.damageTimes
    self.trigger = true
end

function XBuffScript10261120:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

--实际调整伤害
function XBuffScript10261120:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self.damageMagicId then return end
    --不满足体力条件时，不调整伤害
    if not self.trigger then return end
    local newPermyriad = eventArgs.PhysicalPermyriad + self.totalExctraPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, newPermyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
end

function XBuffScript10261120:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --本技能放完后，取消加伤
    if self.trigger == true then self.trigger = false end
end

return XBuffScript10261120
