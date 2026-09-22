local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10282120 : XTheatre6SkillBase
local XBuffScript10282120 = XDlcScriptManager.RegBuffScript(10282120, "XBuffScript10282120", XTheatre6SkillBase)

-- 效果说明： 使用【拼刀技能】后触发：
--· 获得2层<暴击>。
--· 每造成过1次【暴击】，此技能伤害倍率提升50%。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10282120:ScriptInit(isGainControl)
    --XTheatre6SkillBase.ScriptInit(self, isGainControl)

    --self.TLCost = 10                  -- 体力消耗量
    self._damageMagicId = 10280020 --临时伤害id，要改
    --self.extraPermyriad = 5000 --每触发过一次暴击的增伤
    self.extraPermyriadPerCrit = {
        [1] = 1500,
        [2] = 3000,
        [3] = 4500
    }
    self._critController = self:GetNpc():GetCritController()
    self._stackCount = 2
    self.isDmgChanged = false
    self.Count = 0
    self.SkillChanceCheck = 0
end


function XBuffScript10282120:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10282120:OnLuaSkillStart(eventArgs)
    self.isDmgChanged = false
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 1 then
        self.SkillChanceCheck = 0
        self.Count = self.Count + 1 --每次技能开始时才会计数，保证技能过程中的暴击不会计入当次技能的加伤
    end
    if eventArgs._skillType == ETheatre6SkillType.Wrestle then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
end

function XBuffScript10282120:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self._critController:AddSkillCount(self._stackCount)
end

function XBuffScript10282120:OnLuaAffixCritDamage(eventArgs)
    --self:LogError(".....抓到暴击")
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.SkillChanceCheck = 1
    end
end

function XBuffScript10282120:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self.isDmgChanged then return end
    local extraPermyriad = 0 --重置增伤
    if self.Count > 0 then
        extraPermyriad = self.extraPermyriadPerCrit[self._lv] * self.Count --增加伤害
    end
    local finalPermyriad = extraPermyriad + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    self.isDmgChanged = true
end

return XBuffScript10282120
