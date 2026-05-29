local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261030 : XTheatre6SkillBase
local XBuffScript10261030 = XDlcScriptManager.RegBuffScript(10261030, "XBuffScript10261030", XTheatre6SkillBase)

--效果说明：
--· 消耗20点【超算值】，获得1层<坚毅>。。
--· 造成【击倒】

function XBuffScript10261030:ScriptInit(isGainControl) --初始化
    self.overClockCost = 20                            --超算值消耗
    self._stackCount = 1                               --坚毅层数
    self._stackCountHitDown = 1                        --击倒层数
end

function XBuffScript10261030:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuffScript10261030:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --判断超算是否足够触发坚毅/格挡
    self.curOverClock = self._proxy:Theatre6GetNpcRuntimeOverClock(self._npcUUID)
    if self.curOverClock < self.overClockCost then return end
    --如果足够，设置为扣减后的超算值
    self._proxy:Theatre6CastNpcRuntimeOverClock(self._npcUUID, self.overClockCost)
    self._blockController:AddSkillCount(self._stackCount)
end

function XBuffScript10261030:OnLuaSpecialHit(eventArgs)
    --造成击倒
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._missileHitCount ~= 1 then return end
    self._HitDownController:AddSkillCount(self._stackCountHitDown)
end

return XBuffScript10261030
