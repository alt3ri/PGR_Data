local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272020 : XTheatre6SkillBase
local XBuffScript10272020 = XDlcScriptManager.RegBuffScript(10272020, "XBuffScript10272020", XTheatre6SkillBase)

-- 效果说明：
-- 一次出手期间，累计使用3次【主动技能】后释放当前Lua Buff关联的插入技能；
-- 插入技能释放时，耗尽自身当前【体力值】，每消耗15/12/10点获得1层<坚毅>；
-- 插入技能释放时造成【击飞】。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272020:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._activeSkillCount = 0          -- 一次出手期间主动技能使用次数
    self._blockController = nil         -- 坚毅控制器
    self._hitFlyController = nil        -- 击飞控制器
    self._blockBuffId = 1025105         -- 坚毅BuffId
    --self._blockThreshold = 10         -- 触发体力转坚毅的坚毅层数上限
    if self._skillId == 10272021 then self._staminaPerBlock = 15
    else if self._skillId == 10272022 then self._staminaPerBlock = 12
    else self._staminaPerBlock = 10
    end
    end
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript10272020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._blockController = self:GetNpc():GetBlockController()
    self._hitFlyController = self:GetNpc():GetHitFlyController()
end

---技能开始时统计主动技能次数，或执行当前绑定插入技效果
---@param eventArgs table 技能事件参数
function XBuffScript10272020:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    if eventArgs._skillId == self._skillId then
        self:TriggerEffect()
        return
    end

    if eventArgs._skillType ~= ETheatre6SkillType.Main then return end

    self._activeSkillCount = self._activeSkillCount + 1
    if self._activeSkillCount < 3 then return end

    self._activeSkillCount = 0
    if self._level then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
end

---出手权变化时重置主动技能计数，避免跨出手累计
---@param eventArgs table 出手权变化事件参数
--function XBuffScript10272020:OnLuaAttackerChange(eventArgs)
    --if eventArgs._newAttackerUUID == self._npcUUID then
        --self._activeSkillCount = 0
    --end
--end

---触发插入技能效果
function XBuffScript10272020:TriggerEffect()
    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
    end
    if not self._hitFlyController then
        self._hitFlyController = self:GetNpc():GetHitFlyController()
    end

    --local blockStacks = self._proxy:GetBuffStacks(self._npcUUID, self._blockBuffId) or 0
    --if blockStacks <= self._blockThreshold then
    local currentStamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina)
    local staminaToConsume = math.max(0, currentStamina)
    if staminaToConsume > 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -staminaToConsume, 0)
    end

    local gainedStacks = math.floor(staminaToConsume / self._staminaPerBlock)
    if gainedStacks > 0 and self._blockController then
        self._blockController:AddSkillCount(gainedStacks, self._npcUUID)
    end
    --end

    if self._hitFlyController then
        self._hitFlyController:AddSkillCount(1)
    end
end

---脚本终止函数
function XBuffScript10272020:Terminate()
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272020
