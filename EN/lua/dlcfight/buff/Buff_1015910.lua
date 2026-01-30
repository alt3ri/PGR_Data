local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015910 : XBuffBase
local XBuffScript1015910 = XDlcScriptManager.RegBuffScript(1015910, "XBuffScript1015910", Base)
--效果说明：每间隔指定时间，触发一次【定时】状态（定时的标记会不断累加层数，检测到层数变化时，视为触发一次符纹）

function XBuffScript1015910:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015911         --定时标记Buff
    self.signalLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalTime = 5           --定时触发间隔
    self.timer = 0          --计时器
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015940, --强化Buff[1]：每间隔5秒，定时符纹的间隔有20%概率缩短0.5秒（最短缩短至2秒）
        [2] = 1015592, --强化Buff[2]：带有【每隔X秒】条件的效果，所需的触发时间间隔减2秒。
    }
    self.enhRuneIdDict = {
        [1] = 20940,
        [2] = 20592,
    }

    --强化Buff[1]配置
    self.enhBuff1SignalId = 1015941     --Buff[1]成功触发标记
    self.enhBuff1Time = 0.5             --每层标记缩短的时间
    self.enhBuff1MinTime = 2            --最短时间

    --强化Buff[2]配置
    self.enhBuff2Time = 2               --Buff[2]装备时减少的时间
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015910:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end

    local calSignalTime = self.signalTime
    --如果存在Buff[1]，则根据标记层数额外减少时间
    if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
        local calEnhBuff1Time = self._proxy:GetBuffStacks(self._uuid, self.enhBuff1SignalId) * self.enhBuff1Time
        if self.signalTime - calEnhBuff1Time <= self.enhBuff1MinTime then
            calSignalTime = self.enhBuff1MinTime
        else
            calSignalTime = self.signalTime - calEnhBuff1Time
        end
    end
    --当时间满到达计时器时间时，触发一次效果
    if self._proxy:GetNpcTime(self._uuid) > self.timer then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + calSignalTime
    end
end

--region EventCallBack
function XBuffScript1015910:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015910:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，设定一次计时器
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --如果有Buff[2]，则将时间缩短
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2]) then
            self.signalTime = self.signalTime - self.enhBuff2Time
        end
        --初始化计时器
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.signalTime
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015910:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015910:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015910
