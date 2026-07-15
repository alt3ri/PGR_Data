local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272030 : XTheatre6SkillBase
local XBuffScript10272030 = XDlcScriptManager.RegBuffScript(10272030, "XBuffScript10272030", XTheatre6SkillBase)

-- 效果说明：
-- 自身获得3次【护盾】时，释放当前Lua Buff关联的插入技能；
-- 插入技能释放时，额外造成伤害，伤害量等于自身当前【护盾】的30/45/60%；

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272030:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._shieldGainCount = 0        -- 护盾获得次数
    self._damageMagicId = 10270126   -- 关联的伤害Magic
    --self._attackIncreaseValue = 5  -- 攻击属性提升值
    self._pendingExtraDamage = 0     -- 待写入的额外伤害
    self.ShieldNum = {
        [1] = 0.3,
        [2] = 0.45,
        [3] = 0.6                    -- 技能释放次数需求
    }
    self.ChanceCheck = 0
end

---初始化事件回调注册
function XBuffScript10272030:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
end

---获得护盾事件：累计2次后插入技能
function XBuffScript10272030:XNpcAddProtectorArgs(launcherId, targetId, value, totalValue, magicId)
    if targetId ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then -- 检测同一个技能是否获得了多次护盾
        self._shieldGainCount = self._shieldGainCount + 1
        self.ChanceCheck = 1
        if self._shieldGainCount >= 3 then
            if self._level then
                self._level:RequestInsertSkill(self._npcUUID, self._skillId)
            end
            self._shieldGainCount = 0
        end
    end
end

---技能开始时执行当前绑定插入技效果
---@param eventArgs table 技能事件参数
function XBuffScript10272030:OnLuaSkillStart(eventArgs)
    self.ChanceCheck = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self:TriggerEffect()
end

---触发技能效果
function XBuffScript10272030:TriggerEffect()
    local shieldValue = self._proxy:GetNpcProtector(self._npcUUID)
    self._pendingExtraDamage = math.floor(shieldValue * self.ShieldNum[self._lv])

    if self._pendingExtraDamage > 0 then
        self._proxy:ApplyMagic(self._npcUUID, self._enemyUUID, self._damageMagicId, 1, 0, 1)
    end

    --self:AddAttrib(ENpcAttrib.Attack, self._attackIncreaseValue, self._npcUUID, self._npcUUID)
end

---伤害计算后回调：把临时伤害Magic改成护盾30%的固定伤害
---@param eventArgs table 伤害计算事件参数
function XBuffScript10272030:AfterDamageCalc(eventArgs)
    if self._pendingExtraDamage <= 0 then return end
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._proxy:GetBuffCountByKind(self._npcUUID,1025800) >= 1 then
        self._pendingExtraDamage = self._pendingExtraDamage // 2 -- 存在PVP全减伤50%的特殊处理，伤害减半
        --self:LogError(".....触发减伤通知")
    end
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self._pendingExtraDamage, eventArgs.ElementDamage,
            eventArgs.FinalHackDamage)
    self._pendingExtraDamage = 0
end

---脚本终止函数
function XBuffScript10272030:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddProtector)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272030
