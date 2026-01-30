local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015912 : XBuffBase
local XBuffScript1015912 = XDlcScriptManager.RegBuffScript(1015912, "XBuffScript1015912", Base)
--效果说明：每间隔指定时间，触发一次【概率】状态（概率的标记会不断累加层数，检测到添加标记时，视为触发一次符纹）

function XBuffScript1015912:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015913        --概率标记Buff
    self.signalLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalTime = 5           --概率触发间隔
    self.timer = 0          --计时器
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015946 --疲劳阶段，概率类符纹的触发间隔降低3秒
    }
    self.enhRuneIdDict = {
        [1] = 20946
    }
    --增强Buff[1]配置
    self.enhBuff1SignalId = 1015909     --【疲劳】标记
    self.enhBuff1SignalCtrlId = 1015908 --【疲劳】管理脚本
    self.enhBuff1Time = 3               --触发CD减少值
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015912:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end
    local signalTime = self.signalTime
    --若有Buff[1]存在，且处于疲劳阶段，则减少时间
    if self._proxy:CheckBuffByKind(self._uuid,self.enhBuff1SignalId) and self._proxy:CheckBuffByKind(self._uuid,self.enhBuffIdDict[1]) then
        signalTime = signalTime - self.enhBuff1Time
    end
    --当时间满到达计时器时间时，添加一层标记
    if self._proxy:GetNpcTime(self._uuid) > self.timer then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + signalTime
    end
end

--region EventCallBack
function XBuffScript1015912:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end
function XBuffScript1015912:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，设定一次计时器
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.signalTime
        --有Buff[1]存在时，添加疲劳状态管理
        if self._proxy:CheckBuffByKind(self._uuid,self.enhBuffIdDict[1]) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self.enhBuff1SignalCtrlId,1)
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015912:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015912:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015912
