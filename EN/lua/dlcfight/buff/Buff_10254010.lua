local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10254010 : XTheatre6SkillBase
local XBuffScript10254010 = XDlcScriptManager.RegBuffScript(10254010, "XBuffScript10254010", XTheatre6SkillBase)

--效果说明：· 每有3点【超算】属性，额外造成1层【点燃】；扣除对手30点【体力值】

function XBuffScript10254010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId) --初始化
    self._BurnController = self:GetEnemyNpc():GetBurnController()
    --self:LogError("....【超算成功技能1】初始化完成")
end
function XBuffScript10254010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._overClockAttrib = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock)
    --self:LogError(".....抓到超算属性"..self._overClockAttrib)
    self._exBurnStacks = self._overClockAttrib // 80 --额外点燃层数 等于超算点数整除80
end
function XBuffScript10254010:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    local _, MissileActionId = self._proxy:GetMissileActionId(eventArgs._missileUUID)
    local skillId = self._proxy:Theatre6GetSkillByAction(self._uuid,MissileActionId)
    if skillId ~= self._skillId then return end

    if eventArgs._missileHitCount ~= 1 then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -30, 0) --扣除30体力
    self._exBurnStack = self._exBurnStacks + 3
    --if self._exBurnStacks == 0 then return end
    self._BurnController:CastStackBuff(self._exBurnStacks,self._enemyUUID)
end


return XBuffScript10254010

--点燃层数改了下，不知道有没有在表里的关键帧挂点燃，挂了的话这边得回滚