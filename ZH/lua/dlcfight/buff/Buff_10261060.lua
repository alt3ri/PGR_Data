local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261060 : XTheatre6SkillBase
local XBuffScript10261060 = XDlcScriptManager.RegBuffScript(10261060, "XBuffScript10261060", XTheatre6SkillBase)

--效果说明：
-- · 如果上个技能造成【击倒】，额外获得20点【怒火】。
-- · 自身处于【狂暴】状态下时，额外造成【击倒】。
function XBuffScript10261060:ScriptInit(isGainControl) --初始化
    self.isFllowHitDown = false                        --注册标记，是否跟随击倒
    self.angerRecover = 20                             --怒火恢复量
    self.burstBuffId = 1025108                         --狂暴buffId
    self.hitDownStack = 1                              --击倒层数
    --注册怒火控制器
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10261060:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    --注册击倒控制器
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end

function XBuffScript10261060:OnLuaAffixHitDown(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --如果开关已经打开，直接返回
    if self.isFllowHitDown then return end
    self.isFllowHitDown = true
end

function XBuffScript10261060:OnLuaSkillStart(eventArgs)
    --如果是本技能，且开关打开，则获得怒火
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self._skillId and self.isFllowHitDown then
        self._AngerController:CastStackBuff(self.angerRecover, self._npcUUID)
    end
    --关闭击倒标记
    self.isFllowHitDown = false
end

function XBuffScript10261060:OnLuaSpecialHit(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --判断是否处于狂暴状态
    local isBurst = self._proxy:GetBuffStacks(self._npcUUID, self.burstBuffId) >= 1
    if not isBurst then return end
    --处于狂暴状态，造成击倒
    self._HitDownController:AddSkillCount(self.hitDownStack)
end

return XBuffScript10261060