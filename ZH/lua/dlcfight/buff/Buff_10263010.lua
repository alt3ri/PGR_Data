local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10263010 : XTheatre6SkillBase
local XBuffScript10263010 = XDlcScriptManager.RegBuffScript(10263010, "XBuffScript10263010", XTheatre6SkillBase)

--效果说明：
--· 自身每有1点【拼刀】属性，获得4点【怒火】；
--· 每次在【狂暴】状态下使用技能，此技能提高35%攻击伤害；
--· 造成5秒【晕眩】。

function XBuffScript10263010:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._damageMagicId = 10250016 --注册拼刀成功技1伤害id，临时
    self._AngerCount = 4
    self._PDCost = 1
    self.extraDamage = 0
    self.extraDamageBase = 3500
    self.StackBuffAnger = 1025107
    self.StackBuffAngry = 1025108
    --self:LogError(".....初始化完成")
    self.attackCount = 0
    self._hasChangedDamage = false
    self.ChanceCheck = 0
end

function XBuffScript10263010:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    ------------执行------------
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,self.StackBuffAngry)
    if self.originAttrib1 >= 1 then
        if self.ChanceCheck == 1 then
            self.extraDamage = self.extraDamage + self.extraDamageBase
        end
    end
    if eventArgs._skillId ~= self._skillId then return end
    self.originAttrib2 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.WrestlePoint)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    self._angerRecover = self.originAttrib2 / self._PDCost * self._AngerCount
    self._AngerController:CastStackBuff(self._angerRecover, self._npcUUID)
    self.ChanceCheck = 1
    self._hasChangedDamage = false
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
end

function XBuffScript10263010:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local finalPermyriad = self.extraDamage + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    self._hasChangedDamage = true
end

return XBuffScript10263010
