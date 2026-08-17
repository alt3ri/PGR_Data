local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272060 : XTheatre6SkillBase
local XBuffScript10272060 = XDlcScriptManager.RegBuffScript(10272060, "XBuffScript10272060", XTheatre6SkillBase)

-- 效果说明：
-- 当<坚毅>层数每次>7层时，释放当前Lua Buff关联的插入技能；
-- 自身每有1点【拼刀】属性，伤害倍率提升0.5%；
-- 消耗3层<坚毅>

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272060:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    -- 配置参数
    self.DamageMagicIds = {10270014, 10270015, 10270016}  -- 技能子弹魔法ID列表，包含所有需要处理的ID
    self.MinResolveStacks = 7           -- 触发插入技能所需的最小坚毅层数
    self.CurrentResolveCost = 3          -- 当前坚毅消耗层数
    self.BlockBuffId = 1025105           -- 坚毅BuffId
    self.DamageAttrName = ETheatre6AttribType.WrestlePoint -- 拼刀属性
    self.DamageBonusPermyriadPerAttr = 50 -- 每点拼刀属性提升10%伤害倍率，1000表示10%

    -- 本地变量初始化
    self._blockController = self:GetNpc():GetBlockController()
    self._lastResolveStacks = 0          -- 上一帧坚毅层数，用于记录变化
    self._hasRequestedInsertSkill = false -- 当前持续超过阈值期间是否已经插入过技能
    self._shouldModifyDamage = false     -- 是否处于伤害修改窗口
    self._damageBonusPermyriad = 0       -- 当前绑定技能额外伤害倍率，万分比
    self.ChanceCheck = 0
end

---更新函数：检查坚毅层数是否满足插入技能条件
---@param dt number 时间间隔
function XBuffScript10272060:Update(dt) --update理论上很耗，要看看实际表现评估下要不要改
    XTheatre6SkillBase.Update(self, dt)

    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
        if not self._blockController then
            return
        end
    end

    local resolveStacks = self._proxy:GetBuffStacks(self._npcUUID, self.BlockBuffId) or 0

    -- 坚毅回到阈值以下后，允许下一次重新超过阈值时再次触发
    if resolveStacks <= self.MinResolveStacks then
        self._hasRequestedInsertSkill = false
    end

    -- 坚毅层数大于10时，插入当前Buff绑定的Lua技能；持续大于10期间只插入一次
    if resolveStacks > self.MinResolveStacks and not self._hasRequestedInsertSkill and self._level then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self._hasRequestedInsertSkill = true
    end

    self._lastResolveStacks = resolveStacks
end

---技能开始时处理当前Buff绑定技能效果
---@param eventArgs table 技能事件参数
function XBuffScript10272060:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self:TriggerEffect()
end

---技能结束时兜底关闭伤害修改窗口
---@param eventArgs table 技能事件参数
function XBuffScript10272060:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self.ChanceCheck = 0
    self._shouldModifyDamage = false
    self._damageBonusPermyriad = 0

end

---初始化事件回调注册
function XBuffScript10272060:InitEventCallBackRegister()
    -- 注册伤害计算前事件，用于修改当前绑定技能伤害
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

---触发技能效果：计算增伤，消耗坚毅，并提升下次坚毅消耗
function XBuffScript10272060:TriggerEffect()
    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
    end

    -- 每次释放绑定技能时，都按当前拼刀属性重新计算额外伤害倍率
    local wrestlePoint = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, self.DamageAttrName)
    self._damageBonusPermyriad = wrestlePoint * self.DamageBonusPermyriadPerAttr
    self._shouldModifyDamage = true

    -- 消耗当前应消耗的坚毅层数
    if self._blockController then
        self._blockController:RemoveStackBuff(self.CurrentResolveCost)
        self._blockController:SetDefCountByBuff()
    end
end

---伤害计算前回调：只修改当前绑定技能的目标伤害Magic
---@param eventArgs table 伤害计算事件参数
function XBuffScript10272060:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end

    -- 检查当前MagicId是否在需要处理的列表中
    local isTargetMagic = false
    if self.ChanceCheck == 0 then -- 检测是否只改了一段伤害
        for _, magicId in ipairs(self.DamageMagicIds) do
            if eventArgs.Id == magicId then
                isTargetMagic = true
                break
            end
        end
        if not isTargetMagic then return end

        if not self._shouldModifyDamage then return end

        -- 按10272040写法处理：物理伤害倍率 = 原始倍率 + 额外倍率
        local finalPermyriad = eventArgs.PhysicalPermyriad + self._damageBonusPermyriad
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad,
                eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
        self.ChanceCheck = 1
    end
end

---事件处理函数
function XBuffScript10272060:HandleEvent(eventType, eventArgs)
    XTheatre6SkillBase.HandleEvent(self, eventType, eventArgs)
end

---脚本终止函数
function XBuffScript10272060:Terminate()
    -- 注销伤害计算前事件
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272060
