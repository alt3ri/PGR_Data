local Base = require("Common/XFightBase")

---@class XBuffScript1015418 : XFightBase
local XBuffScript1015418 = XDlcScriptManager.RegBuffScript(1015418, "XBuffScript1015418", Base)

--效果：进入疲劳阶段时，获得10秒内衰减的100冰伤提升
function XBuffScript1015418:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 1     --宝珠生效CD，一共10级，如果需要在5秒内衰减，就把cd改为0.5
    self.magicId = 1015419 --魔法id
    self.magicLevel = 1 --初始魔法等级
    self.magicMaxLevel = 10 --最终魔法等级
    self.tiredBuffId = 999999   --疲劳buff id，id待定，待修改
    self.isTired = false     --疲劳状态判定
    ------------执行------------
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015418:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行 ------------
    --判断是否进入疲劳，没疲劳就返回
    if not self.isTired then
        return
    end

    --计算CD是否满足条件，没满足就返回
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then
        return
    end

    --计算当前Buff等级，如果有旧buff就删除旧buff，当buff等级小于等于最大值即可施加新buff
    if self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end
    if self.magicLevel <= self.magicMaxLevel then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加效果
        self.magicLevel = self.magicLevel + 1 --每秒等级加1
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --更新宝珠CD的Timer
    end

end

--region EventCallBack
function XBuffScript1015418:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1015418:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果目标不是自己就返回
    if not (npcUUID == self._uuid) then
        return
    end

    --如果buff不是疲劳就返回
    if buffId == self.tiredBuffId then
        return
    end

    --进入疲劳状态，开始计算宝珠CD
    self.isTired = true
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算计时器
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015418:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015418:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015418
