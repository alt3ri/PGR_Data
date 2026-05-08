local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251010 : XTheatre6SkillBase
local XBuffScript10251010 = XDlcScriptManager.RegBuffScript(10251010, "XBuffScript10251010", XTheatre6SkillBase)

--效果说明：如果上个【主动技能】造成【击飞】，则添加引燃标记buff（引燃标记buff可让技能造成2层【引燃】）。

function XBuffScript10251010:ScriptInit(isGainControl) --初始化
    self._hasHitFly = false --注册主动技能击飞检查开关标记
    self._canBurnSainBuffid = 10251104 --注册引燃标记buff
    self:LogError("....【主动技能1】初始化完成")
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._stackbuff = 1025104
    if self._lv == 1 then
        self._exBurnStacks = 1
    elseif self._lv == 2 then
        self._exBurnStacks = 2
    else
        self._exBurnStacks = 3
    end
end

function XBuffScript10251010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._BurnController = self:GetEnemyNpc():GetBurnController()
end

function XBuffScript10251010:OnLuaAffixHitFly(EventArgs)
    if EventArgs._launcherUUID ~= self._npcUUID then return end
    if self._hasHitFly then return end -- 如果已经上个技能已经造成过击飞则返回
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self._canBurnSainBuffid) --添加可引燃标记buff
    self._hasHitFly = true --打开上次主动技能击飞检查标记
end

function XBuffScript10251010:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._hasHitFly then --如果本次技能结束时击飞标记为开
        self._hasHitFly = false --关闭击飞技能标记
        return
    end
    if self._proxy:CheckBuffByKind(self._npcUUID, self._canBurnSainBuffid) then -- 删除标记buff保底
        self._proxy:RemoveBuff(self._npcUUID, self._canBurnSainBuffid)
    end
end

function XBuffScript10251010:OnLuaSpecialHit(eventArgs)
    if eventArgs._missileHitCount ~= 1 then return end
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:CheckBuffByKind(self._npcUUID, self._canBurnSainBuffid) then
        self._BurnController:CastStackBuff(self._exBurnStacks,self._enemyUUID)
    end
end

return XBuffScript10251010

    --没懂怎么实现的