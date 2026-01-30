local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015922 : XBuffBase
local XBuffScript1015922 = XDlcScriptManager.RegBuffScript(1015922, "XBuffScript1015922", Base)

--效果说明：敌人生命首次低于20%时，重复触发一次开局类符纹的属性提升效果，时间持续5秒（若开局效果未结束，则延长5秒）

function XBuffScript1015922:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.runeId = 20922            --符纹ID赋值
    self.magicLevel = 1
    self.signal1Id = 1015905     --【斩杀】状态标记，标记管理脚本见1015904
    self.signal1CtrlId = 1015904 --【斩杀】状态管理Buff
    self.signal2Id = 1015907     --【开局】状态标记，标记管理脚本见1015908
    self.signal2Time = 5         --【开局】持续时间
    self.effectTrigger = 0       --阶段标记
    self.timer = 0
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【斩杀】管理Buff

end

---@param dt number @ delta time 
function XBuffScript1015922:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --进入计时阶段后，且计时器满足条件后再走后续逻辑
    if self.effectTrigger == 2 and self._proxy:GetNpcTime(self._uuid) >= self.timer then
        self._proxy:RemoveBuff(self._uuid, self.signal2Id)
        self.effectTrigger = 3
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
end

--region EventCallBack
function XBuffScript1015922:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015922:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --已经触发过，无需运行后续步骤
    if self.effectTrigger ~= 0 then
        return
    end
    --如果自身添加了【斩杀】标记，进入后续触发逻辑
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        --若身上没有【开局】标记，则触发效果，并打开宝珠特效
        if self._proxy:CheckBuffByKind(self._uuid, self.signal2Id) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            --开启计时器
            self.timer = self._proxy:GetNpcTime(self._uuid) + self.signal2Time
            self.effectTrigger = 2  --进入计时阶段
        else
            self.effectTrigger = 1  --等待【开局】效果结束后，再生效
        end
    end
end

function XBuffScript1015922:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【开局】标记，且Trigger为1，则触发效果
    if self._uuid == npcUUID and self.signal2Id == buffId and self.effectTrigger == 1 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        --开启计时器
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.signal2Time
        self.effectTrigger = 2  --进入计时阶段
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015922:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015922:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015922
