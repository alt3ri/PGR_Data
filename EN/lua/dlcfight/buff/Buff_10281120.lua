local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281120 : XTheatre6SkillBase
local XBuffScript10281120 = XDlcScriptManager.RegBuffScript(10281120, "XBuffScript10281120", XTheatre6SkillBase)

--效果说明：· 每使用过1次此技能，此技能伤害倍率提升20/40/60%；
--· 每通过【失心】触发过1次此技能，此技能伤害倍率提升30%；

function XBuffScript10281120:ScriptInit(isGainControl) --初始化
    self._StackBuffLostHeart = 1028102
    self._stackCountUse = 0
    self._stackCountLostHeart = 0
    self._damageMagicId = 10280009 --临时，要改
    self.extraPermyriadPerUse = {
        --不同等级的默认剧毒层数
        [1] = 2000,
        [2] = 4000,
        [3] = 6000
    }
    self.extraPermyriadTotal = 0
    self.extraPermyriadPerLostHeart = 3000
    self.isDmgChanged = false
end

function XBuffScript10281120:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10281120:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.isDmgChanged = false
end

function XBuffScript10281120:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.isDmgChanged = true
    self._stackCountUse = self._stackCountUse + 1
    local Check = self._proxy:GetBuffCountByKind(self._npcUUID,self._StackBuffLostHeart)
    if Check ~= 0 then -- 检测是不是失心触发的，是就额外叠加一层
        self._stackCountLostHeart = self._stackCountLostHeart + 1
    end
end

function XBuffScript10281120:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self.isDmgChanged then return end
    self.extraPermyriadTotal = 0 --重置增伤
    if self._stackCountUse > 0 then
        self.extraPermyriadTotal = self.extraPermyriadPerLostHeart * self._stackCountLostHeart + self.extraPermyriadPerUse[self._lv] * self._stackCountUse --增加伤害
    end
    local finalPermyriad = self.extraPermyriadTotal + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    self.isDmgChanged = true
end

return XBuffScript10281120