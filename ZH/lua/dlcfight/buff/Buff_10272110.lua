local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272110 : XTheatre6SkillBase
local XBuffScript10272110 = XDlcScriptManager.RegBuffScript(10272110, "XBuffScript10272110", XTheatre6SkillBase)

-- 效果说明：
-- 【超算】成功后，释放当前Lua Buff关联的插入技能；
-- 插入技能基础伤害由技能配置负责；
-- 插入技能释放时，【超算】属性提升30点；
-- 插入技能释放时，自身每有200点【超算】属性，获得1层<坚毅>。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272110:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._blockController = nil
    self._overClockAdd = 30
    self._overClockPerBlock = 200
end

---初始化事件回调注册
function XBuffScript10272110:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.Theatre6DodgeRollDiceEnd)
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript10272110:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._blockController = self:GetNpc():GetBlockController()
end

---处理超算成功事件
--function XBuffScript10272110:HandleEvent(eventType, eventArgs)
    --XTheatre6SkillBase.HandleEvent(self, eventType, eventArgs)

    --if eventType ~= EWorldEvent.Theatre6DodgeRollDiceEnd then return end
    --if eventArgs.WinnerUUID ~= self._npcUUID then return end
    --if not self._level then return end

    --self._level:RequestInsertSkill(self._npcUUID, self._skillId)
--end

---技能开始时执行当前绑定插入技效果
---@param eventArgs table 技能事件参数
function XBuffScript10272110:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType == ETheatre6SkillType.Dodge then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
    if eventArgs._skillId ~= self._skillId then return end

    self:TriggerEffect()
end

---触发技能效果
function XBuffScript10272110:TriggerEffect()
    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
    end

    self:AddTheatre6Attrib(ETheatre6AttribType.OverClock, self._overClockAdd, self._npcUUID, self._npcUUID)

    local currentOverClock = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock)
    local gainedStacks = math.floor(currentOverClock / self._overClockPerBlock)
    if gainedStacks > 0 and self._blockController then
        self._blockController:AddSkillCount(gainedStacks, self._npcUUID)
    end
end

---脚本终止函数
function XBuffScript10272110:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.Theatre6DodgeRollDiceEnd)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272110
