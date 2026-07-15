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
    -- 伤害段数
    self._damageTimes = 14
    -- 当前体力消耗
    self._nowCostTL = 0
    --坚毅buffId
    self._blockBuffId = self:GetNpc():GetBlockController().StackBuff
    --心眼buffId
    self._critBuffId = self:GetNpc():GetCritController().StackBuff

    --最终改伤万分比
    --self._exDamageRate = 0
    
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

function XBuffScript10262100:Update(dt)
    --确保玩家能被赋值
    if not self._player then
        self._player = self._npcUUID
    end
    --历史体力值
    if not self._nowTL then
        self._nowTL = self._proxy:GetNpcGameplayAttribValue(self._player,ETheatre6AttribType.Stamina)
    end
    --当前体力值
    local _nowTL2 = self._proxy:GetNpcGameplayAttribValue(self._player,ETheatre6AttribType.Stamina)
    
    --体力消耗记录
    if _nowTL2 > self._nowTL then
        self._nowTL = _nowTL2
        return
    end
    if _nowTL2 < self._nowTL then
        self._nowCostTL = self._nowCostTL + self._nowTL - _nowTL2
        self._nowTL = _nowTL2
        --如果超过目标，就插入技能
        if self._nowCostTL >= self._targetTL then
            self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            self._nowCostTL = 0
            return
        end
    end
end

function XBuffScript10262100:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --保底处理，如果不是自己/技能id不对，直接退出
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    --记录我方层数
    local _myBlock = self._proxy:GetBuffStacks(self._npcUUID,self._blockBuffId)
    local _myCrit = self._proxy:GetBuffStacks(self._npcUUID,self._critBuffId)
    local _enemyBlock = self._proxy:GetBuffStacks(self._enemyUUID,self._blockBuffId)
    local _enemyCrit = self._proxy:GetBuffStacks(self._enemyUUID,self._critBuffId)
    
    --清除我方和对方的层数
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._blockBuffId,_myBlock)
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._critBuffId,_myCrit)
    self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._blockBuffId,_enemyBlock)
    self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._critBuffId,_enemyCrit)
    
    --总层数记录
    local _totalCount = _myBlock+_myCrit+_enemyBlock+_enemyCrit
    if _totalCount <= 0 then 
        self._hasChangedDamage = false
        return
    end
    
    --判断要改多少伤害
    self._exDamageRate = _totalCount * self._extraDamage[self._lv] / self._damageTimes
end

--实际调整伤害
function XBuffScript10262100:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    
    if self._hasChangedDamage == false then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
end

function XBuffScript10262100:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --本技能放完后，取消加伤
    if self._hasChangedDamage == true then self._hasChangedDamage = false end
end

return XBuffScript10262100

