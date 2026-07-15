local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272010 : XTheatre6SkillBase
local XBuffScript10272010 = XDlcScriptManager.RegBuffScript(10272010, "XBuffScript10272010", XTheatre6SkillBase)

-- 效果说明：
-- 获得出手权后，释放当前Lua Buff关联的插入技能；
-- 本场战斗中自身每造成过1次【格挡】，当前绑定技能伤害提升60%攻击；

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272010:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self.BlockDamageBonus = 6000        -- 每次格挡提供60%伤害倍率，万分比加算
    --self.StaminaRecoveryPerStack = 10   -- 每消耗1层坚毅恢复10点体力值
    --self.CritThreshold = 5              -- 消耗层数超过5层时必定暴击
    self._damageMagicIds = {            -- 当前绑定技能伤害MagicId，如表格变更需要同步
        [10270030] = true,
        [10270031] = true,
    }
    self._blockBuffId = 1025105         -- 坚毅BuffId
    self._blockController = nil         -- 坚毅控制器
    self._blockSuccessCount = 0         -- 本场战斗自身成功格挡次数
    self._damageBonusPermyriad = 0      -- 当前技能额外伤害倍率
    self._forceCrit = false             -- 当前技能是否强制暴击
    self._shouldModifyDamage = false    -- 是否处于伤害修改窗口
    self.ChanceCheckBlock = 0
    self.ChanceCheckDmg = 0
    self.ChanceCheck = 0
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript10272010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._blockController = self:GetNpc():GetBlockController()
end

---获得出手权后插入当前绑定技能
---@param eventArgs table 出手权变化事件参数
function XBuffScript10272010:OnLuaAttackerChange(eventArgs)
    if eventArgs._newAttackerUUID ~= self._npcUUID then return end
    if not self._level then return end
    if self.ChanceCheck == 0 then
    self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self.ChanceCheck = 1
    end
end

---自身成功格挡时累计次数
---@param eventArgs table 格挡事件参数
function XBuffScript10272010:OnLuaAffixBlock(eventArgs)
    if eventArgs._targetUUID ~= self._npcUUID then return end
    if self.ChanceCheckBlock == 0 then
        self._blockSuccessCount = self._blockSuccessCount + 1
        self.ChanceCheckBlock = 1
    end
end

---技能开始时准备当前绑定技能效果
---@param eventArgs table 技能事件参数
function XBuffScript10272010:OnLuaSkillStart(eventArgs)
    self.ChanceCheck = 0
    self.ChanceCheckBlock = 0
    self.ChanceCheckDmg = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self:PrepareSkillEffect()
end

---技能结束时关闭伤害修改窗口
---@param eventArgs table 技能事件参数
function XBuffScript10272010:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self._shouldModifyDamage = false
    self._damageBonusPermyriad = 0
    self._forceCrit = false
end

---初始化事件回调注册
function XBuffScript10272010:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

---准备当前绑定技能效果
function XBuffScript10272010:PrepareSkillEffect()
    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
    end

    self._damageBonusPermyriad = self._blockSuccessCount * self.BlockDamageBonus
    --self._forceCrit = false
    self._shouldModifyDamage = true

    --local blockStacks = self._proxy:GetBuffStacks(self._npcUUID, self._blockBuffId) or 0
    --if blockStacks <= 0 then return end

    --if self._blockController then
        --self._blockController:ClearStackBuff()
    --else
        --self._proxy:RemoveBuff(self._npcUUID, self._blockBuffId)
    --end

    --local staminaRecovery = blockStacks * self.StaminaRecoveryPerStack
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, staminaRecovery, 0)

    --if blockStacks > self.CritThreshold then
        --self._forceCrit = true
    --end
end

---伤害计算前回调：应用格挡次数增伤和必暴
---@param eventArgs table 伤害计算事件参数
function XBuffScript10272010:BeforeDamageCalc(eventArgs)
    if not self._shouldModifyDamage then return end
    if eventArgs.Launcher ~= self._npcUUID then return end
    if not self._damageMagicIds[eventArgs.Id] then return end
    if self.ChanceCheckDmg == 0 then
        local finalDamageRate = eventArgs.PhysicalPermyriad + self._damageBonusPermyriad
        --local isCrit = eventArgs.IsCrit or self._forceCrit
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalDamageRate, eventArgs.ElementPermyriad,
                eventArgs.HackDamage, eventArgs.HackPermyriad)
        self.ChanceCheckDmg = 1
    end
end

---脚本终止函数
function XBuffScript10272010:Terminate()
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272010
