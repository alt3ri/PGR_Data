local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272050 : XTheatre6SkillBase
local XBuffScript10272050 = XDlcScriptManager.RegBuffScript(10272050, "XBuffScript10272050", XTheatre6SkillBase)

-- 效果说明：
-- 每累计获得300点【耀斑值】时，释放当前Lua Buff关联的插入技能；
-- 插入技能释放时，获得1层<坚毅>；
-- 插入技能释放时，自身每有20点【攻击】属性，获得1点【耀斑值】。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272050:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._flareThreshold = 300      -- 每累计300点耀斑触发一次
    self._totalFlareGained = 0      -- 本轮累计获得耀斑值
    self._lastFlareStacks = 0       -- 上次记录的当前耀斑层数
    self._sunBuffId = 1027101       -- 耀斑BuffId
    self._attackPerFlare = 20       -- 每20点攻击获得1点耀斑
    self._sunController = nil       -- 耀斑控制器
    self._blockController = nil     -- 坚毅控制器
end

---初始化事件回调注册
function XBuffScript10272050:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

---进入关卡时初始化控制器和当前耀斑层数
---@param levelId number 关卡ID
function XBuffScript10272050:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._sunController = self:GetNpc():GetSunController()
    self._blockController = self:GetNpc():GetBlockController()
    self._lastFlareStacks = self:GetCurrentFlareStacks()
end

---获取当前耀斑层数
---@return number
function XBuffScript10272050:GetCurrentFlareStacks()
    return self._proxy:GetBuffStacks(self._npcUUID, self._sunBuffId) or 0
end

---耀斑增加事件：累计耀斑获得量并按阈值触发插入技能
function XBuffScript10272050:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self._sunBuffId then return end

    local currentFlareStacks = self:GetCurrentFlareStacks()
    local addedFlare = currentFlareStacks - self._lastFlareStacks
    if addedFlare < 0 then
        addedFlare = currentFlareStacks
    end

    self._lastFlareStacks = currentFlareStacks
    if addedFlare <= 0 then return end

    self._totalFlareGained = self._totalFlareGained + addedFlare
    while self._totalFlareGained >= self._flareThreshold do
        self._totalFlareGained = self._totalFlareGained - self._flareThreshold
        if self._level then
            self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        end
    end
end

---耀斑移除只同步当前层数，不清空累计进度
function XBuffScript10272050:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self._sunBuffId then return end

    self._lastFlareStacks = self:GetCurrentFlareStacks()
end

---技能开始时执行当前绑定插入技效果
---@param eventArgs table 技能事件参数
function XBuffScript10272050:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self:TriggerEffect()
end

---触发技能效果
function XBuffScript10272050:TriggerEffect()
    if not self._blockController then
        self._blockController = self:GetNpc():GetBlockController()
    end
    if not self._sunController then
        self._sunController = self:GetNpc():GetSunController()
    end

    if self._blockController then
        self._blockController:AddSkillCount(1, self._npcUUID)
    end

    local attack = self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Attack)
    --self:LogError(".....耀斑获取通知"..attack)
    local flareGain = math.floor(attack / self._attackPerFlare)
    --self:LogError(".....耀斑获取通知"..flareGain)
    if flareGain > 0 and self._sunController then
        self._sunController:CastStackBuff(flareGain, self._npcUUID)
    end
end

---脚本终止函数
function XBuffScript10272050:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcRemoveBuff)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272050
