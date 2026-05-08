local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251030 : XTheatre6SkillBase
local XBuffScript10251030 = XDlcScriptManager.RegBuffScript(10251030, "XBuffScript10251030", XTheatre6SkillBase)

--效果说明：如果此次技能可以暴击，则额外造成1层【引燃】

function XBuffScript10251030:ScriptInit(isGainControl) --初始化
    self._stackbuff = 1025104
    if self._lv == 1 then
        self._stackCount = 1
    elseif self._lv == 2 then
        self._stackCount = 2
    else
        self._stackCount = 3
    end
end

function XBuffScript10251030:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId) --初始化
    --self._BurnController = self:GetEnemyNpc():GetBurnController()
    --self:LogError("....【主动技能3】初始化完成")
end


function XBuffScript10251030:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    if eventArgs._missileHitCount ~= 1 then return end
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:CheckBuffByKind(self._npcUUID, self._stackbuff) then
        self:GetEnemyNpc():GetBurnController():CastStackBuff(self._stackCount, self._enemyUUID)
    end
end

return XBuffScript10251030

--OnLuaSpecialHit无法拿到skillId等待补全ing
