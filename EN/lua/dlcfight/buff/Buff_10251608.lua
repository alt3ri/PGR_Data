local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---首次使用任意技能后触发
-- · 造成50%攻击伤害；
-- · 每损失1%生命值，该技能伤害提升1%攻击
-- · 自身每有60点【体力】属性，获得1层<心眼>。
---@class XBuffScript.10251608 : XTheatre6SkillBase
local XBuff10251608 = XDlcScriptManager.RegBuffScript(10251608, "XBuffScript10251608", XTheatre6SkillBase)

function XBuff10251608:ScriptInit(isGainControl) --初始化
    ---技能首次触发判定
    self.trigger = false
    ---属性判定
    --self.staminaThreshold = 150
    ---添加伤害提升和治疗提升buff的id
    self._damageMagicId = 10250042
    self.magicLevel = 1
    if self._skillId == 10252121 then self.staminaPerCrit = 60
    else if self._skillId == 10252122 then self.staminaPerCrit = 50
    else self.staminaPerCrit = 40
    end
    end
    self._exDamageRate_Hp = 10000 --损血为100%时增伤为万分之10000
    --self:LogError(".....目标插入式技能12注册完成")
    self._critController = self:GetNpc():GetCritController()
    self._hasChangedDamage = false
end

function XBuff10251608:OnLuaSkillEnd(eventArgs)
    self._hasChangedDamage = false
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if not self.trigger then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self.trigger = true
    end
    if eventArgs._skillId ~= self._skillId then return end
    local stamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina)
    self.buffStacks = stamina // self.staminaPerCrit
    self._critController:AddSkillCount(self.buffStacks)
    --self:LogError(".....增加暴击层数"..self.buffStacks)
end

function XBuff10251608:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuff10251608:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local lostHp = self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life) - self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Life)
    self._exDamageRate = lostHp * self._exDamageRate_Hp // self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life)
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
    --self:LogError(".....增加伤害"..self._exDamageRate)
end


return XBuff10251608
