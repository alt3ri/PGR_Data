local BurnBuff = require("Gameplay/Theatre6/AffixController/XTheatre6BurnController").StackBuff
local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251040 : XTheatre6SkillBase
local XBuffScript10251040 = XDlcScriptManager.RegBuffScript(10251040, "XBuffScript10251040", XTheatre6SkillBase)

--效果说明：对手每有2层【点燃】，则额外造成1层【引燃】，最多五层

function XBuffScript10251040:ScriptInit(isGainControl) --初始化
    self._stackCount = 0
    self._exBurnStacks = 0
    if self._lv == 1 then
        self.MaxBurn = 3
    elseif self._lv == 2 then
        self.MaxBurn = 4
    else
        self.MaxBurn = 5
    end
end

function XBuffScript10251040:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._BurnController = self:GetEnemyNpc():GetBurnController()
    -- self:LogError("....【主动技能4】初始化完成")
end

function XBuffScript10251040:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:CheckBuffByKind(self._enemyUUID, BurnBuff) then
        self._targetBurnStacks = self._proxy:GetBuffStacks(self._enemyUUID, BurnBuff)
        self._exBurnStacks = self._targetBurnStacks // 3  --额外点燃层数等于目标点燃层数整除3
        if self._exBurnStacks >= self.MaxBurn then
            self._exBurnStacks = self.MaxBurn
        end
    end
end

function XBuffScript10251040:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    if eventArgs._missileHitCount ~= 1 then return end
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._exBurnStacks == 0 then return end
    -- XLog.Warning("释放前目标点燃层数" .. self._targetBurnStacks)
    self._BurnController:CastStackBuff(self._exBurnStacks, self._enemyUUID)
    self._targetBurnStacks = self._proxy:GetBuffStacks(self._enemyUUID, BurnBuff)
    -- XLog.Warning("释放后目标点燃层数" .. self._targetBurnStacks)
end

return XBuffScript10251040

--OnLuaSpecialHit无法拿到skillId等待补全ing
