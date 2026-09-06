local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---【超算】成功后，造成50%攻击伤害。
---扣除对手20点【体力值】；
---【超算】属性>230点时，伤害额外提高100%攻击。
---@class XBuffScript.10284030 : XTheatre6SkillBase
local XBuff10284030 = XDlcScriptManager.RegBuffScript(10284030, "XBuffScript10284030", XTheatre6SkillBase)

function XBuff10284030:ScriptInit(isGainControl) --初始化
    self.staminaDamage = 20
    self.extraPermyriad = 10000
    self.targetOverClockThreshold = 230
    self._damageMagicId = 10280023
    self.isDmgChanged = false   --是否已经改变
end

function XBuff10284030:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuff10284030:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self.isDmgChanged then return end
    ---如果超算属性达标
    if self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) > self.targetOverClockThreshold then
        local finalPermyriad = self.extraPermyriad + eventArgs.PhysicalPermyriad
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
        self.isDmgChanged = true
    end
end

function XBuff10284030:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -self.staminaDamage,0)
    self.isDmgChanged = false   --重置防重复开关
end


return XBuff10284030
