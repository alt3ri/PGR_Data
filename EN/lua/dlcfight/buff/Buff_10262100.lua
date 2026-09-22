local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262100 : XTheatre6SkillBase
local XBuffScript10262100 = XDlcScriptManager.RegBuffScript(10262100, "XBuffScript10262100", XTheatre6SkillBase)

--效果说明：每消耗100体力后触发：
--自身处于【狂暴】时，额外清空双方的<心眼>、<坚毅>层数，每清空一层，伤害额外提高10/20/30%攻击。

function XBuffScript10262100:ScriptInit(isGainControl) --初始化
    --注册技能伤害id
    self._damageMagicId = 1026210
    -- 当前消耗的体力
    self._costTL = 0
    -- 目标体力消耗
    self._targetTL = 100
    -- 额外伤害，万分比
    self._extraDamage = {
        [1] = 1000,
        [2] = 2000,
        [3] = 3000
    }
    -- 伤害段数，基于伤害段数的实现太变态了，改成了和其他技能一样改单段伤害
    --self._damageTimes = 14
    -- 当前体力消耗
    self._nowCostTL = 0
    --坚毅buffId
    self._blockBuffId = self:GetNpc():GetBlockController().StackBuff
    --心眼buffId
    self._critBuffId = self:GetNpc():GetCritController().StackBuff
    --给两边挂上两种控制器，方便后面清层数
    self._blockController = self:GetNpc():GetBlockController()
    self._critController = self:GetNpc():GetCritController()
    self.AngryBuff = self:GetNpc():GetAngerController().StackBuffAngry

    --最终改伤万分比，不能注释，注释了在抓不到值的时候会报错
    self._exDamageRate = 0
    self._hasChangedDamage = true
    self._totalCostTL = 0
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript10262100:HandleEvent(eventType, eventArgs)
    XTheatre6SkillBase.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10262100:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10262100:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        local skillConfig = self._proxy:Theatre6GetSkillConfig(eventArgs._skillId)
        local TLCost = skillConfig.CostTL
        self._totalCostTL = self._totalCostTL + TLCost
        --self:LogError("现在记录体力=***"..self._totalCostTL)
        if self._totalCostTL >= self._targetTL then
            self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            self._totalCostTL = self._totalCostTL - self._targetTL
            return
        end
        if eventArgs._skillId ~= self._skillId then return end
        if self._hasChangedDamage == true then self._hasChangedDamage = false end
    end
end

function XBuffScript10262100:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --保底处理，如果不是自己/技能id不对，直接退出
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hasChangedDamage = true
    if self._proxy:GetBuffCountByKind(self._npcUUID,self.AngryBuff) == 0 then return end

    --记录我方层数
    local _myBlock = self._proxy:GetBuffStacks(self._npcUUID,self._blockBuffId)
    --self:LogError("我方格挡".._myBlock)
    local _myCrit = self._proxy:GetBuffStacks(self._npcUUID,self._critBuffId)
    --self:LogError("我方暴击".._myCrit)
    local _enemyBlock = self._proxy:GetBuffStacks(self._enemyUUID,self._blockBuffId)
    --self:LogError("敌方格挡".._enemyBlock)
    local _enemyCrit = self._proxy:GetBuffStacks(self._enemyUUID,self._critBuffId)
    --self:LogError("敌方暴击".._enemyCrit)

    --清除我方和对方的层数
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._blockBuffId,_myBlock)
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._critBuffId,_myCrit)
    self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._blockBuffId,_enemyBlock)
    self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._critBuffId,_enemyCrit)

    self._blockController:RemoveDefSkillCount(_myBlock)
    self._critController:RemoveAtkSkillCount(_myCrit)
    self:GetEnemyNpc():GetBlockController():RemoveDefSkillCount(_enemyBlock)
    self:GetEnemyNpc():GetCritController():RemoveAtkSkillCount(_enemyCrit)
    
    --总层数记录
    local _totalCount = _myBlock + _myCrit + _enemyBlock + _enemyCrit
    --self:LogError("打印下总层数".._totalCount)
    if _totalCount <= 0 then 
        self._hasChangedDamage = false
        return
    end
    
    --判断要改多少伤害
    self._exDamageRate = _totalCount * self._extraDamage[self._lv]
    --self:LogError("打印下总伤害"..self._exDamageRate)
end

--实际调整伤害
function XBuffScript10262100:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    
    if self._hasChangedDamage == false then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    --self:LogError("打印下我改伤害了吗")
    self._hasChangedDamage = false
end

return XBuffScript10262100

