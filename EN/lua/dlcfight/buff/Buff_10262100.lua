local BurnBuff = require("Gameplay/Theatre6/AffixController/XTheatre6BurnController").StackBuff
local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262100 : XTheatre6SkillBase
local XBuffScript10262100 = XDlcScriptManager.RegBuffScript(10262100, "XBuffScript10262100", XTheatre6SkillBase)

--效果说明：累计消耗150体力后触发：
--自身处于【狂暴】时，额外清空双方的<心眼>、<坚毅>层数，每清空一层，伤害额外提高50%攻击。

function XBuffScript10262100:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --Todo,替换正式的伤害magic，注册技能伤害id
    self._damageMagicId = 10250011
    -- 当前消耗的体力
    self._costTL = 0
    -- 目标体力消耗
    self._targetTL = 150
    -- 额外伤害
    self._extraDamage = 5000
    -- 自身
    self._player = self._npcUUID
    -- 当前体力消耗
    self._nowCostTL = 0
    -- 坚毅控制器
    self._blockController = self:GetNpc():GetBlockController()
    -- 心眼控制器
    self._critController = self:GetNpc():GetCritController()
    -- 敌人坚毅控制器
    self._enemyBlockController = null
    -- 敌人心眼控制器
    self._enemyCritController = null

    XLog.Warning("初始化完成")
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
        XLog.Warning("当前消耗："..self._nowCostTL)
        self._nowTL = _nowTL2
        --如果超过目标，就插入技能
        if self._nowCostTL >= self._targetTL then
            XLog.Warning("开始插入"..self._nowCostTL)
            self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
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
    local _myBlock = self._blockController:GetSkillCount()
    local _myCrit = self._critController:GetSkillCount()
    --敌人赋值
    if self._enemyBlockController == null then
        local _enemy = self._enemyUUID:GetNpc()
        if _enemy == null then return end
        self._enemyBlockController = _enemy:GetBlockController()
        self._enemyCritController = _enemy:GetCritController()
    end
    local _enemyBlock = self._enemyBlockController:GetSkillCount()
    local _enemyCrit = self._enemyCritController:GetSkillCount()
    
    --清除我方和对方的层数
    self._blockController:ClearStackBuff()
    self._critController:ClearStackBuff()
    self._enemyBlockController:ClearStackBuff()
    self._enemyCritController:ClearStackBuff()
    
    --总层数记录
    local _totalCount = _myBlock+_myCrit+_enemyBlock+_enemyCrit
    if _totalCount <= 0 then return end
    XLog.Warning("总层数：".._totalCount)
    self._hasChangedDamage = false
    --判断要改多少伤害
    self._exDamageRate = _totalCount * self._extraDamage
end

--实际调整伤害
function XBuffScript10262100:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    --if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end

return XBuffScript10262100

