local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261020 : XTheatre6SkillBase
local XBuffScript10261020 = XDlcScriptManager.RegBuffScript(10261020, "XBuffScript10261020", XTheatre6SkillBase)

--效果说明：
--· 获得10点【怒火】；
--· 自身处于【狂暴】状态下时，消耗30点【怒火】，并额外提高80/100/120%攻击伤害。
function XBuffScript10261020:ScriptInit(isGainControl) --初始化
    self._exBurnStacks = 0
    self.StackBuffAnger = 1025107                      --怒火buffId
    self.StackBuffBurst = 1025108                      --狂暴buffId
    self.dmgMagicId = 1026394                          --#TODO 需要修改为实际伤害的MagicId，5.10已确认
    self._angerCost = 30
    self._angerRecover = 10
    self.dictExtraPermyriad = {
        --不同等级提升的技能倍率
        [1] = 8000,
        [2] = 10000,
        [3] = 12000
    }
    self.dmgTrigger = false
end

function XBuffScript10261020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10261020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --非狂暴状态，直接结束
    local isBurst = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffBurst) >= 1
    --狂暴状态下消耗怒火，增加伤害
    if (not self.dmgTrigger) and isBurst then
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffAnger, self._angerCost)
        self.dmgTrigger = true
    end
    --获得怒火(先扣除再获得，让利给玩家)
    self:GetNpc():GetAngerController():CastStackBuff(self._angerRecover, self._npcUUID)
end

function XBuffScript10261020:InitEventCallBackRegister()
    --调整技能倍率
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10261020:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self.dmgMagicId then return end
    if not self.dmgTrigger then return end
    --调整伤害倍率
    local skillLevel = self._lv
    local permyriad = eventArgs.PhysicalPermyriad + self.dictExtraPermyriad[skillLevel]
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, permyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    --关闭触发开关
    self.dmgTrigger = false
end

return XBuffScript10261020
