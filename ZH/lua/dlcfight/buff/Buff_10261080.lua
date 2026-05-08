local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261080 : XTheatre6SkillBase
local XBuffScript10261080 = XDlcScriptManager.RegBuffScript(10261080, "XBuffScript10261080", XTheatre6SkillBase)

--效果说明：
-- · 自身处于【狂暴】状态下时，耗尽【怒火】，每消耗1点【怒火】，伤害提高2/3/4%攻击。

function XBuffScript10261080:ScriptInit(isGainControl) --初始化
    self.burstBuffId = 1025108                         --狂暴buffId
    self.angerBuffId = 1025107                         --怒火buffId
    self.dmgMagicId = 1026394                          --#TODO 错误的伤害magicid，需要修改为实际伤害的MagicId
    self.angerCostStack = 1                            --每消耗x层怒火，提升伤害
    self.hasChangedDamage = false                      --是否已经改变过伤害，防止多次触发
    self.dictExtraPermyriad = {
        --不同等级提升的技能倍率
        [1] = 200,
        [2] = 300,
        [3] = 400
    }
    --注册怒火控制器
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10261080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --将是否已经改变伤害的标记重置
    self._hasChangedDamage = false
end

function XBuffScript10261080:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10261080:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self.dmgMagicId then return end
    --如果已经修改过倍率了，直接返回
    if self._hasChangedDamage then return end
    --判断是否处于狂暴状态
    local isBurst = self._proxy:GetBuffStacks(self._npcUUID, self.burstBuffId) >= 1
    if not isBurst then return end
    --获取怒火层数，计算技能倍率提升
    local angerStack = self._proxy:GetBuffStacks(self._npcUUID, self.angerBuffId)
    local exPerymyriad = angerStack//self.angerCostStack * self.dictExtraPermyriad[self._lv]
    local newPermyriad = eventArgs.PhysicalPermyriad + exPerymyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, newPermyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    --消除所有怒火层数
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.angerBuffId, angerStack)
    --标记已经修改过伤害
    self._hasChangedDamage = true
end

return XBuffScript10261080