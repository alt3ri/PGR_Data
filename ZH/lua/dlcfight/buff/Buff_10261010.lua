local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261010 : XTheatre6SkillBase
local XBuffScript10261010 = XDlcScriptManager.RegBuffScript(10261010, "XBuffScript10261010", XTheatre6SkillBase)

--效果说明：每场战斗前2次使用此技能时，额外造成【击倒】，并提高80%攻击伤害。

function XBuffScript10261010:ScriptInit(isGainControl) --初始化
    self.skilCnt = 2                                   --技能使用次数
    self.extraPermyriad = 8000                         --额外伤害倍数，8000即80%
    self.dmgMagicId = 1026391                          --#TODO 需要修改为实际伤害的MagicId
    self.dmgTrigger = false                            --是否触发伤害调整
    self.stackCountHitDown = 1                         --击倒层数
end

function XBuffScript10261010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end

function XBuffScript10261010:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._missileHitCount ~= 1 then return end
    if self.skilCnt > 0 then
        --击倒
        self._HitDownController:AddSkillCount(self.stackCountHitDown)
        self.dmgTrigger = true
        self.skilCnt = self.skilCnt - 1
    end
end

function XBuffScript10261010:InitEventCallBackRegister()
    --调整技能倍率
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10261010:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self.dmgMagicId then return end
    if not self.dmgTrigger then return end
    --调整伤害倍率
    local permyriad = eventArgs.PhysicalPermyriad + self.extraPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, permyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    --关闭触发开关
    self.dmgTrigger = false
end

return XBuffScript10261010
