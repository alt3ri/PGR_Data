local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015650 : XBuffBase
local XBuffScript1015650 = XDlcScriptManager.RegBuffScript(1015650, "XBuffScript1015650", Base)

--效果说明：【疲劳】状态下，获得增益
local ConfigMagicIdDict = {
    [1015650] = 1015651,
    [1015652] = 1015653,
    [1015654] = 1015655,
    [1015656] = 1015657,
    [1015658] = 1015659,
    [1015660] = 1015661,
    [1015662] = 1015663,
    [1015664] = 1015665,
    [1015666] = 1015667,
    [1015668] = 1015669,
    [1015670] = 1015671,
    [1015672] = 1015673,
    [1015674] = 1015675,
    [1015676] = 1015677,
    [1015678] = 1015679,
    [1015680] = 1015681,
    [1015682] = 1015683,
    [1015684] = 1015685,
    [1015686] = 1015687,
    [1015688] = 1015689,
    --强化效果部分
    [1016174] = 1016175,
    [1016176] = 1016177,
    [1016178] = 1016179,
    [1016180] = 1016181,
    [1016182] = 1016183,
}
local ConfigRuneIdDict = {
    [1015650] = 20650,
    [1015652] = 20652,
    [1015654] = 20654,
    [1015656] = 20656,
    [1015658] = 20658,
    [1015660] = 20660,
    [1015662] = 20662,
    [1015664] = 20664,
    [1015666] = 20666,
    [1015668] = 20668,
    [1015670] = 20670,
    [1015672] = 20672,
    [1015674] = 20674,
    [1015676] = 20676,
    [1015678] = 20678,
    [1015680] = 20680,
    [1015682] = 20682,
    [1015684] = 20684,
    [1015686] = 20686,
    [1015688] = 20688,
    --强化效果部分
    [1016174] = 20656,
    [1016176] = 20664,
    [1016178] = 20672,
    [1016180] = 20680,
    [1016182] = 20688,
}

function XBuffScript1015650:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1 --初始buff等级1级
    self.signalId = 1015909         --【疲劳】状态标记，标记管理脚本见1015908
    self.signalCtrlId = 1015908     --【疲劳】状态管理Buff

    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015958       --带有【进入疲劳阶段】条件的效果提升100%
    }
    self.enhRuneIdDict = {
        [1] = 20958       --带有【进入疲劳阶段】条件的效果提升100%
    }
    --增强Buff[1]列表
    self.enhBuff1MagicLevel = 1     --带有Buff[1]时，等级加1
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【定时】管理Buff

end

---@param dt number @ delta time 
function XBuffScript1015650:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015650:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end

function XBuffScript1015650:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【疲劳】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        local calMagicLevel = self.magicLevel
        --如果有Buff[1]存在，需要提升等级
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
            calMagicLevel = calMagicLevel + self.enhBuff1MagicLevel
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, calMagicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end

function XBuffScript1015650:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【疲劳】标记，则删除效果，并关闭宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
end

--endregion
---@param eventType number
---@param eventArgs userdata
function XBuffScript1015650:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015650:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015650

    