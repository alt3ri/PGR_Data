local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281080 : XTheatre6SkillBase
local XBuffScript10281080 = XDlcScriptManager.RegBuffScript(10281080, "XBuffScript10281080", XTheatre6SkillBase)

--效果说明：· 命中处于【剧毒】的对手时，获得1层<暴击>；
--· 造成【击飞】。

function XBuffScript10281080:ScriptInit(isGainControl) --初始化
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._StackBuffPoisoned = 1028103
    self._stackCount = 1
    self._stackCountPoison = 1
    self._stackCountHitFly = 1
    self._critController = self:GetNpc():GetCritController()
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10281080:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end


--self:LogError(".....初始化完成")

function XBuffScript10281080:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._HitFlyController:AddSkillCount(self._stackCountHitFly)
end


function XBuffScript10281080:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._stackCount = self._proxy:GetBuffCountByKind(self._enemyUUID,self._StackBuffPoisoned)
    if self._stackCount >= 1 then
        self._critController:AddSkillCount(self._stackCountPoison)
    end
end



return XBuffScript10281080