local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272130 : XTheatre6SkillBase
local XBuffScript10272130 = XDlcScriptManager.RegBuffScript(10272130, "XBuffScript10272130", XTheatre6SkillBase)

-- 效果说明：
-- 此技能仅通过【耀斑值】机制触发；
-- 释放当前Lua Buff关联的插入技能时，自身每有1点【体力】属性，伤害倍率提升1%
-- 获得20点【耀斑值】；
-- 释放当前Lua Buff关联的插入技能时，，并造成【击飞】。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272130:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._damageMagicIds = {             -- 当前技能过程中的伤害MagicId
        [10270017] = true,
        [10270018] = true,
        [10270019] = true,
        [10270020] = true,
    }
    self._damageBonusPermyriad = 100     -- 1%伤害倍率，万分比加算
    self._shouldModifyDamage = false     -- 是否处于伤害修改窗口
    self._sunController = self:GetNpc():GetSunController() -- 耀斑控制器
    self._hitFlyController = self:GetNpc():GetHitFlyController() -- 击飞控制器
    self.ChanceCheck = 0                -- 判断是否执行过加伤
end

---初始化事件回调注册
function XBuffScript10272130:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript10272130:OnEnterLevel(levelId)
    --XTheatre6SkillBase.OnEnterLevel(self, levelId)

end

---技能开始时执行当前绑定插入技效果
---@param eventArgs table 技能事件参数
function XBuffScript10272130:OnLuaSkillStart(eventArgs)
    self.ChanceCheck = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self:TriggerEffect()
end

---技能结束时兜底关闭伤害修改窗口
---@param eventArgs table 技能事件参数
function XBuffScript10272130:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end

    self._shouldModifyDamage = false
end

---触发技能效果
function XBuffScript10272130:TriggerEffect()
    self._sunController:CastStackBuff(20, self._npcUUID)
    self._shouldModifyDamage = true
    if self._hitFlyController then
        self._hitFlyController:AddSkillCount(1)
    end
end

---伤害计算前回调：给当前绑定技能过程中的伤害增加5%伤害倍率
---@param eventArgs table 伤害计算事件参数
function XBuffScript10272130:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if not self._shouldModifyDamage then return end
    if not self._damageMagicIds[eventArgs.Id] then return end
    if self.ChanceCheck == 0 then
        local finalPermyriad = eventArgs.PhysicalPermyriad + self._damageBonusPermyriad * self._proxy:GetNpcGameplayMaxAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
        self.ChanceCheck = 1
    end
end

---脚本终止函数
function XBuffScript10272130:Terminate()
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272130
