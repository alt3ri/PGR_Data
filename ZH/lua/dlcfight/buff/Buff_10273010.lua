local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10273010 : XTheatre6SkillBase
local XBuffScript10273010 = XDlcScriptManager.RegBuffScript(10273010, "XBuffScript10273010", XTheatre6SkillBase)

-- 效果说明：
-- 【拼刀】成功后，消耗自身10%【生命值】，并转化为双倍【护盾】；
-- 持有【护盾】时，自身每有80点【拼刀】属性，吸取对手10点【攻击】属性；
-- 【拼刀】成功后，造成5秒【眩晕】。
-- 详细说明被动逻辑：玩家持有任意一个护盾类的效果（暂时判定为只有护盾总值大于0），吸取攻击力的效果就生效，护盾碎了吸攻击效果同时消失；同一时间，吸攻击效果只生效一次，不叠加

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10273010:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)
    self.Protector = self:GetNpc():GetProtectorController()
    self.ShieldBuffId = 1027301         -- 护盾Buff/MagicId
    self.StunDuration = 5               -- 眩晕持续时间
    self.WrestlePerDrain = 80           -- 每次吸取需要80点拼刀
    self.AttackPerDrain = 10            -- 每次吸取10点攻击
    self._selfDamageMagicId = 10278002  -- 扣除生命值的伤害Magic
    self._selfDamageRatio = 0.1         -- 扣除最大生命值的10%
    self._isAttackDrainActive = false   -- 当前是否已经生效吸攻
    self._drainCount = 0                -- 当前添加的吸取Buff数量
end

---初始化事件回调注册
function XBuffScript10273010:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)
    self._proxy:RegisterEvent(EWorldEvent.NpcChangeProtector)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    --self:LogError(".....初始化通知")
end

---进入关卡时检查当前护盾状态
---@param levelId number 关卡ID
function XBuffScript10273010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    --self:LogError(".....进入关卡通知")
    self:RefreshAttackDrainByProtector(self._proxy:GetNpcProtector(self._npcUUID))
end

---处理拼刀成功事件
function XBuffScript10273010:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId == self._skillId then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.ShieldBuffId, 1, 0, 1)
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self._selfDamageMagicId, 1, 0, 1)
        --local life = self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Life)
        --local ChangedLife = life * 0.9
        --self._proxy:SetNpcGameplayEnergy(self._npcUUID, ENpcAttrib.Life, ChangedLife)
        if self._enemyUUID then
            self._proxy:Theatre6AddNpcStun(self._enemyUUID, self.StunDuration)
        end
    end
end

---伤害计算后回调：写入生命消耗实际伤害
---@param eventArgs table 伤害计算事件参数
function XBuffScript10273010:AfterDamageCalc(eventArgs)
    if eventArgs.Id ~= self._selfDamageMagicId then return end
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Target ~= self._npcUUID then return end

    local maxLife = self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Life)
    local damage = maxLife * self._selfDamageRatio
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, 0, damage,
            eventArgs.FinalHackDamage)
    --self:LogError(".....伤害计算通知")
end

---获得护盾时检查是否需要开启吸攻被动
function XBuffScript10273010:XNpcAddProtectorArgs(launcherId, targetId, value, totalValue, magicId)
    if targetId ~= self._npcUUID then return end

    self:RefreshAttackDrainByProtector(totalValue)
    --self:LogError(".....加盾通知")
end

---护盾变化时检查吸攻被动是否需要开启或还原
function XBuffScript10273010:XNpcChangeProtectorArgs(launcherId, targetId, value, totalValue)
    if targetId ~= self._npcUUID then return end
    --self:LogError(".....改盾通知")
    self:RefreshAttackDrainByProtector(totalValue)
end

---根据当前护盾状态刷新吸攻被动
function XBuffScript10273010:RefreshAttackDrainByProtector(totalProtector)
    if totalProtector > 0 then
        self:ApplyAttackDrain()
    else
        self:RevertAttackDrain()
        --self:LogError(".....盾刷新通知")
    end
end

---持有护盾时生效一次吸攻，不重复叠加
function XBuffScript10273010:ApplyAttackDrain()
    if self._isAttackDrainActive then return end
    if not self._enemyUUID then return end

    local wrestlePoint = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.WrestlePoint)
    if wrestlePoint <= 0 then return end

    local targetAttack = self._proxy:GetNpcAttribValue(self._enemyUUID, ENpcAttrib.Attack)
    local drainCountByWrestle = math.floor(wrestlePoint / self.WrestlePerDrain)
    local drainCountByAttack = math.floor(targetAttack / self.AttackPerDrain)
    local drainCount = math.min(drainCountByWrestle, drainCountByAttack)
    if drainCount <= 0 then return end

    self._isAttackDrainActive = true
    self._drainCount = drainCount
    self._proxy:ApplyMagic(self._npcUUID,self._enemyUUID,10273012,1,1,drainCount) --减少攻击属性
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,10273011,1,1,drainCount) --提升攻击属性
    --self:LogError(".....盾吸取攻击通知")
end

---护盾消失时移除本次添加的吸取Buff
function XBuffScript10273010:RevertAttackDrain()
    if not self._isAttackDrainActive then return end
    if self._drainCount <= 0 then
        self._isAttackDrainActive = false
        self._drainCount = 0
        return
    end

    self._proxy:RemoveBuff(self._npcUUID,10273011)
    self._proxy:RemoveBuff(self._enemyUUID,10273012)

    self._isAttackDrainActive = false
    self._drainCount = 0
    --self:LogError(".....盾碎了的通知")
end

---脚本终止函数
function XBuffScript10273010:Terminate()
    self:RevertAttackDrain()
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddProtector)
    self._proxy:UnregisterEvent(EWorldEvent.NpcChangeProtector)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    XTheatre6SkillBase.Terminate(self)
    --self:LogError(".....方法初始化通知")
end

return XBuffScript10273010
