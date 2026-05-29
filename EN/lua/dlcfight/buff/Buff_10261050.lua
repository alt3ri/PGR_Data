local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261050 : XTheatre6SkillBase
local XBuffScript10261050 = XDlcScriptManager.RegBuffScript(10261050, "XBuffScript10261050", XTheatre6SkillBase)

--效果说明：
--·自身持有<坚毅>时，造成【击倒】并获得20点【怒火】。

function XBuffScript10261050:ScriptInit(isGainControl) --初始化
    self.blockBuffId = 1025106                         --坚毅buffId
    self.blockBuffStack = 1                            --目标坚毅层数
    self._angerRecover = 20                            --怒火恢复量
    self._stackCountHitDown = 1                        --击倒层数
end

function XBuffScript10261050:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    --初始化怒火、击倒控制器
    self._AngerController = self:GetNpc():GetAngerController()
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end

function XBuffScript10261050:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._missileHitCount ~= 1 then return end

    --判断是否处于坚毅状态
    local isBlockActive = self._proxy:GetBuffStacks(self._npcUUID, self.blockBuffId) >= self.blockBuffStack
    --非坚毅状态，直接结束
    if not isBlockActive then return end
    --处于坚毅状态，获得怒火，造成击倒
    self._AngerController:CastStackBuff(self._angerRecover, self._npcUUID)
    self._HitDownController:AddSkillCount(self._stackCountHitDown)
end

return XBuffScript10261050
