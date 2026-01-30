local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015908 : XBuffBase
local XBuffScript1015908 = XDlcScriptManager.RegBuffScript(1015908, "XBuffScript1015908", Base)
--效果说明：关卡下发疲劳标记时，进入【疲劳】状态，

function XBuffScript1015908:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015909         --疲劳标记Buff
    self.signalLevel = 1
    self.tiredBuffId = 1010029        --疲劳效果初始时间/秒
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015942   --每间隔5秒，使双方获得2秒疲劳状态
    }
    self.enhRuneIdDict = {
        [1] = 20942
    }
    --强化Buff[1]配置
    self.enhBuff1SignalId = 1015943  --buff1触发标记

    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015908:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015908:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end
function XBuffScript1015908:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --获得关卡提供的疲劳标记时进入【疲劳】状态
    if npcUUID == self._uuid and buffId == self.tiredBuffId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
    end
    --当Buff[1]存在时，buff1标记触发时获得疲劳标记
    local isEnhBuff1Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1])
    if npcUUID == self._uuid and buffId == self.enhBuff1SignalId and isEnhBuff1Active then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
    end
end
function XBuffScript1015908:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --当Buff[1]存在时，且关卡提供的疲劳标记不存在时，buff1标记移除时移除疲劳标记
    local isEnhBuff1Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1])
    local isTiredBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.tiredBuffId)
    if npcUUID == self._uuid and buffId == self.enhBuff1SignalId and isEnhBuff1Active and (not isTiredBuffActive) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015908:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015908:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015908
