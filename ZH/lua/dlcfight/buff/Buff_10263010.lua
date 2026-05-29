local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10263010 : XTheatre6SkillBase
local XBuffScript10263010 = XDlcScriptManager.RegBuffScript(10263010, "XBuffScript10263010", XTheatre6SkillBase)

--效果说明：
--· 自身每有60点【拼刀】属性，获得10点【怒火】；
--· 每次在【狂暴】状态下使用技能，此技能提高30%攻击伤害；
--· 造成5秒【晕眩】。

function XBuffScript10263010:ScriptInit(isGainControl) --初始化
    self._damageMagicId = 1026297                      --注册拼刀成功技1伤害id，子弹id仍然临时 2026.5.20
    self._AngerCount = 10                              --满足拼刀需求时获得x怒火
    self._PDCost = 60                                  --拼刀属性需求
    self.extraDamage = 0                               --狂暴时额外伤害累计
    self.extraDamageBase = 3000                        --狂暴时额外伤害
    self.StackBuffAnger = 1025107                      --怒火Buff
    self.StackBuffAngry = 1025108                      --狂暴Buff
    self._hasChangedDamage = false                     --伤害修改防重复检测
end

function XBuffScript10263010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10263010:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --是否处于狂暴中
    local isAngry = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffAngry) >= 1
    if isAngry then
        self.extraDamage = self.extraDamage + self.extraDamageBase
        local cnt = self.extraDamage // self.extraDamageBase
    end
    --计算【怒火】获得值
    if eventArgs._skillId ~= self._skillId then return end
    local curWrestle = self._proxy:GetNpcGameplayAttribValue(self._uuid, ETheatre6AttribType.WrestlePoint)
    local angerRecover = curWrestle // self._PDCost * self._AngerCount
    self._AngerController:CastStackBuff(angerRecover, self._npcUUID)
    --重置额外伤害的重复检测(狂暴技能统计、额外增伤修改)
    self._hasChangedDamage = false
end

function XBuffScript10263010:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
end

function XBuffScript10263010:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10263010:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local finalPermyriad = self.extraDamage + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    self._hasChangedDamage = true
end

return XBuffScript10263010
