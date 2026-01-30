local Base = require("Common/XFightBase")

---@class XBuffScript1015782 : XBuffBase
local XBuffScript1015782 = XDlcScriptManager.RegBuffScript(1015782, "XBuffScript1015782", Base)
--效果说明：开局前10秒回复效率提升30%
--1015790,开局效果提升+20%
--1015792,开局效果持续时间+5s
--1015794,持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
function XBuffScript1015782:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.BuffTimer =  0 --初始计时器
    self.PhaseTimer = 0 --开局阶段计时器
    self.BuffId = 1015783   --回复效率+30%的buffid
    self.magicLevel = 1 --初始buff等级1级
    self.Spmagiclevel = 2   --有开局效果提升buff时候的buff等级
    self.baseDuration = 12  --基础持续时间间隔
    self.HitCount = 0 --命中计数器
    self.StrengthenBuffId = 1015790 --开局效果提升的buffid
    self.OverTimeBuffId = 1015792 --开局效果持续时间+5s的buff
    self.HitBuffId = 1015794  --持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
    self.skillType = 2    --跟战斗约定的起手技能类型，待定
    self.isActive = false  --buff激活状态
    self.extraTime = 0            -- 额外延长的时间
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015782:Update(dt) --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.PhaseTimer = self.PhaseTimer + dt

    -- 仅在开局前10秒内激活
    if self.PhaseTimer <= 10 and not self.isActive then
        -- 初始化持续时间（包含OverTimeBuffId的加成）
        if self._proxy:CheckBuffByKind(self._uuid,self.OverTimeBuffId) then
            self.baseDuration = self.baseDuration + 5
        end
        if self._proxy:CheckBuffByKind(self._uuid,self.StrengthenBuffId) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.BuffId,self.Spmagiclevel)
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.BuffId,self.magicLevel)
        end
        self.isActive = true
    end

    -- BUFF激活期间处理
    if self.isActive then
        self.BuffTimer = self.BuffTimer + dt
        local totalDuration = self.baseDuration + self.extraTime
        -- 超时移除
        if self.BuffTimer >= totalDuration then
            self._proxy:RemoveBuff(self._uuid,self.BuffId)
        end
    end
end


--region EventCallBack
function XBuffScript1015782:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end

function XBuffScript1015782:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if self.isActive and launcherId == self._uuid then
        -- 只有持有1015794时才计数
        if self._proxy:CheckBuffByKind(self._uuid,self.HitBuffId) then
            self.hitCount = self.hitCount + 1
            if self.hitCount >= 5 then
                self.extraTime = self.extraTime + 1
                self.hitCount = 0
                self.BuffTimer = math.max(0, self.BuffTimer - 1) -- 时间轴补偿
            end
        end
    end
end
function XBuffScript1015782:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end
    if buffId ~= self._buffId then
        return
    end
    if self._proxy:CheckBuffByKind(self._uuid, self.BuffId) then
        return
    else
        self.isActive = false
        self.BuffTimer = 0
        self.extraTime = 0
        self.hitCount = 0
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015782:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015782:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015782
