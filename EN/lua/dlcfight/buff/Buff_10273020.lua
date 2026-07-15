local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10273020 : XTheatre6SkillBase
local XBuffScript10273020 = XDlcScriptManager.RegBuffScript(10273020, "XBuffScript10273020", XTheatre6SkillBase)

-- 效果说明：
-- 【拼刀】成功后释放当前Lua Buff关联的插入技能；
-- 释放当前绑定技能时，自身每有100点【拼刀】属性，获得1层<坚毅>，至多5层；
-- 自身触发【格挡】时，扣除对手5点【体力值】与5点【超算值】。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10273020:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self.WrestlePerBlock = 100          -- 每100点拼刀获得1层坚毅
    self.MaxBlockStacks = 5             -- 最多获得5层坚毅
    self.DrainAmount = 5                -- 格挡时扣除对手体力值与超算值
    self._blockController = nil         -- 坚毅控制器
    self.ChanceCheck = 0
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript10273020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._blockController = self:GetNpc():GetBlockController()
end

---技能开始时执行当前绑定技能效果
---@param eventArgs table 技能事件参数
function XBuffScript10273020:OnLuaSkillStart(eventArgs)
    self.ChanceCheck = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self:TriggerSkillEffect()

end

---触发当前绑定技能效果
function XBuffScript10273020:TriggerSkillEffect()
    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
    end

    local wrestlePoint = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.WrestlePoint)
    local blockStacks = math.min(math.floor(wrestlePoint / self.WrestlePerBlock), self.MaxBlockStacks)
    if blockStacks <= 0 or not self._blockController then return end
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
    self._blockController:AddSkillCount(blockStacks, self._npcUUID)
end

---自身触发格挡时扣除对手体力值与超算值
---@param eventArgs table 格挡事件参数
function XBuffScript10273020:OnLuaAffixBlock(eventArgs)
    if eventArgs._targetUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.DrainAmount, 0)
        self.TargetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID) --检测对手的超算值，如果超算值不足就扣除当前超算值
        if self.TargetCS <= self.DrainAmount then self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.TargetCS)
        else self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.DrainAmount)
        end
        self.ChanceCheck = 1 --避免一个技能触发多段计数
    end
end

return XBuffScript10273020
