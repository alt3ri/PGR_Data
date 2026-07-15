local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272090 : XTheatre6SkillBase
local XBuffScript10272090 = XDlcScriptManager.RegBuffScript(10272090, "XBuffScript10272090", XTheatre6SkillBase)

-- 效果说明：自身【耀斑值】每次达到100点时触发：
--· 造成60/90/120%攻击伤害；
--· 耗尽【耀斑值】；
--· 【攻击】属性与【体力】属性提升10点；

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272090:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)


    --self._DamagePerSun = 300          -- 每点耀斑提高1%倍率
    self._damageMagicId = 1027208       -- 伤害Id
    self._TargetSun = 100               -- 耀斑值需求
    self._AddATK = 10                   -- 攻击提升
    self._AddTL = 10                    -- 体力提升
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._sunController = self:GetNpc():GetSunController()
    self.SunBuffId = 1027101            -- 耀斑BuffId
    self.ChanceCheck = 0                -- 每技能一次计数器
    --self.dmgTrigger = true
end

function XBuffScript10272090:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self._skillId then
        self:AddTheatre6Attrib(ETheatre6AttribType.Stamina, self._AddTL, self._npcUUID, self._npcUUID)
        self:AddAttrib(ENpcAttrib.Attack, self._AddATK, self._npcUUID, self._npcUUID)
        --self.dmgTrigger = true --刷新一下改伤害判断
        self._proxy:RemoveBuff(self._npcUUID,self.SunBuffId) --清空玩家的耀斑层数
    end
end

function XBuffScript10272090:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript10272090:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.SunBuffId then return end
    if self._proxy:GetBuffStacks( self._npcUUID,self.SunBuffId) >= self._TargetSun then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID, self._skillId)
            self.ChanceCheck = 1 -- 限制一下每个技能只做一次判断
        end
    else
        self.ChanceCheck = 0 -- 把可释放的次数判断挪到了耀斑值低于100时，这样玩家必须要把耀斑值耗到100以下之后才能再次触发此效果
    end
end

--function XBuffScript10272090:BeforeDamageCalc(eventArgs)
    --if eventArgs.Launcher ~= self._npcUUID then return end
    --if eventArgs.Id ~= self.dmgMagicId then return end
    --if not self.dmgTrigger then return end
    --self:LogError(".....播报下改了伤害") -- 现在没有正式的伤害id，所以不会触发消耗和增伤的逻辑
    --local extraDmg = eventArgs.PhysicalPermyriad + self._DamagePerSun * self._proxy:GetBuffStacks(self._npcUUID , self.SunBuffId) --取玩家身上的耀斑层数乘以每点耀斑伤害
    --self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, extraDmg, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    --关闭触发开关
    --self.dmgTrigger = false
--end

return XBuffScript10272090
