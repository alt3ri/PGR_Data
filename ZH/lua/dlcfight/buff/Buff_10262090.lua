local BurnBuff = require("Gameplay/Theatre6/AffixController/XTheatre6BurnController").StackBuff
local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262090 : XTheatre6SkillBase
local XBuffScript10262090 = XDlcScriptManager.RegBuffScript(10262090, "XBuffScript10262090", XTheatre6SkillBase)

--效果说明：本场战斗中首次任意一方生命值低于30%时触发：
--获得100点【怒火】；
--本场战斗中每获得或消耗过一次【怒火】，恢复自身8点【体力值】。

function XBuffScript10262090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --生命值比例
    self._propHP = 3000
    -- 体力回复
    self._recoverTL = 8
    -- 怒火回复值
    self._recoverAnger = 100
    -- 我方生命最大值
    self._maxHP = self._proxy:GetNpcGameplayAttribMaxValue(self._npcUUID,1)
    -- 我方所需生命值
    self._targetHP = self._maxHP * self._propHP / 10000
    -- 是否已经使用
    self._isUsed = 0
    -- 怒火变化初始次数
    self._angerChange = 0
    -- 怒火控制器
    self._AngerController = self:GetNpc():GetAngerController()
    -- 怒火初始值
    self._angerValue = 0
    self.timer = 0
    self._canUpdate = false
    XLog.Warning("初始化完成")
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript10262090:HandleEvent(eventType, eventArgs)
    XTheatre6SkillBase.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10262090:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript10262090:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._canUpdate = true
    -- self.timer = self._proxy:GetNpcTime(self._uuid) + 2
    self:LogError("....关卡初始化初始化完成")
end

function XBuffScript10262090:Update(dt)
    -- 获取下敌人最大血量
    XLog.Warning("Update中" .. tostring(self._canUpdate))
    
    if not self._canUpdate or not self._enemyUUID then return end
    
    XLog.Warning("我方目标生命：".. tostring(self._enemyUUID))

    -- local canUpdate = 0
    -- canUpdate = (self._proxy:GetNpcTime(self._uuid) > self.timer) and self._canUpdate

    
    XLog.Warning("Update中" ..self._canUpdate)
    -- local canUpdate = 0
    -- canUpdate = (self._proxy:GetNpcTime(self._uuid) > self.timer) and self._canUpdate
    XLog.Warning("我方目标生命："..self._enemyUUID)

    -- if not canUpdate then return end

    if self._enemyHP == null then
        self._enemyMaxHP = self._proxy:GetNpcAttribMaxValue(self._enemyUUID,1)
        self._enemyTargetHP = self._enemyMaxHP * self._propHP / 10000
    end
    --如果技能已经加过队列了就不放了
    if self._isUsed == 1 then return end
    
    --获取怒火变化次数
    local _angerNowValue = self._AngerController:GetSkillCount()
    if _angerNowValue ~= self._angerValue then
        self._angerChange = self._angerChange + 1
        self._angerValue = _angerNowValue
    end

    local _nowHP = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,1)
    local _enemyNowHP = self._proxy:GetNpcGameplayAttribValue(self._enemyUUID,1)
    
    XLog.Warning("我方目标生命："..self._targetHP)
    XLog.Warning("敌方目标生命："..self._enemyTargetHP)
    
    if _nowHP < self._targetHP or _enemyNowHP < self._enemyTargetHP then
        self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
        self._isUsed = 1
    end
end

function XBuffScript10262090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --保底处理，如果不是自己/技能id不对，直接退出
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    --回怒火
    self._AngerController:AddSkillCount(self._recoverAnger)
    self._angerChange = self._angerChange + 1
    --判断要回多少体力
    local _recover = self._angerChange * self._recoverTL
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,_recover,0)
end

return XBuffScript10262090

