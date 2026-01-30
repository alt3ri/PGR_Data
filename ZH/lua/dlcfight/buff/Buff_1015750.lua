local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015750 : XBuffBase
local XBuffScript1015750 = XDlcScriptManager.RegBuffScript(1015750, "XBuffScript1015750", Base)
--效果说明：【开局】状态下，获得增益

local ConfigMagicIdDict = {
    [1015750] = 1015751,
    [1015752] = 1015753,
    [1015754] = 1015755,
    [1015756] = 1015757,
    [1015758] = 1015759,
    [1015760] = 1015761,
    [1015762] = 1015763,
    [1015764] = 1015765,
    [1015766] = 1015767,
    [1015768] = 1015769,
    [1015770] = 1015771,
    [1015772] = 1015773,
    [1015774] = 1015775,
    [1015776] = 1015777,
    [1015778] = 1015779,
    [1015780] = 1015781,
    [1015782] = 1015783,
    [1015784] = 1015785,
    [1015786] = 1015787,
    [1015788] = 1015789,
    [1015794] = 1015795, --【战斗前10秒内】自身伤害提升50%
    --强化效果部分
    [1016194] = 1016195,
    [1016196] = 1016197,
    [1016198] = 1016199,
    [1016200] = 1016201,
    [1016202] = 1016203,
}
local ConfigRuneIdDict = {
    [1015750] = 20750,
    [1015752] = 20752,
    [1015754] = 20754,
    [1015756] = 20756,
    [1015758] = 20758,
    [1015760] = 20760,
    [1015762] = 20762,
    [1015764] = 20764,
    [1015766] = 20766,
    [1015768] = 20768,
    [1015770] = 20770,
    [1015772] = 20772,
    [1015774] = 20774,
    [1015776] = 20776,
    [1015778] = 20778,
    [1015780] = 20780,
    [1015782] = 20782,
    [1015784] = 20784,
    [1015786] = 20786,
    [1015788] = 20788,
    [1015794] = 20794, --【战斗前10秒内】自身伤害提升50%
    --强化效果部分
    [1016194] = 20756,
    [1016196] = 20764,
    [1016198] = 20772,
    [1016200] = 20780,
    [1016202] = 20788,
}

function XBuffScript1015750:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1 --初始buff等级1级
    self.signalId = 1015907         --【开局】状态标记，标记管理脚本见1015906
    self.signalCtrlId = 1015906     --【开局】状态管理Buff
    self.enhBuffIdDict = {
        [1] = 1015790, --增强Buff[1]，开局效果提升（2级效果）
        [2] = 1015794, --【战斗前10秒内】自身伤害提升50%
    }
    --增强Buff[1]配置
    self.magicLevelEnhance = 2   --有开局效果提升buff时候的buff等级
    --增强Buff[2]配置
    self.enhBuff2MagicIds = { 1015796, 1015797, 1015798 }   --全属性增伤Buff
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【开局】管理Buff
end

---@param dt number @ delta time
function XBuffScript1015750:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end


--region EventCallBack
function XBuffScript1015750:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end

function XBuffScript1015750:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【开局】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        --如果有增强Buff[1]存在，则将Buff等级替换为2级
        local isEnhBuff1Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1])
        if isEnhBuff1Active then
            self.magicLevel = self.magicLevelEnhance
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        --如果有增强Buff[2]存在，则额外添加buff
        local isEnhBuff2Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2])
        if isEnhBuff2Active then
            for _, magicId in ipairs(self.enhBuff2MagicIds) do
                self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, self.magicLevel)
            end
        end
    end
end

function XBuffScript1015750:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【开局】标记，则删除效果，并关闭宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
        --如果有增强Buff[2]存在，则额外移除buff
        local isEnhBuff2Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2])
        if isEnhBuff2Active then
            for _, magicId in ipairs(self.enhBuff2MagicIds) do
                self._proxy:RemoveBuff(self._uuid, magicId)
            end
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015750:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015750:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015750
