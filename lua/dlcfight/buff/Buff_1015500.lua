local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015500 : XBuffBase
local XBuffScript1015500 = XDlcScriptManager.RegBuffScript(1015500, "XBuffScript1015500", Base)

--效果说明：当自身处于【背水】状态时，获得Buff

local ConfigMagicIdDict = {
    [1015500] = 1015501,
    [1015502] = 1015503,
    [1015504] = 1015505,
    [1015506] = 1015507,
    [1015508] = 1015509,
    [1015510] = 1015511,
    [1015512] = 1015513,
    [1015514] = 1015515,
    [1015516] = 1015517,
    [1015518] = 1015519,
    [1015520] = 1015521,
    [1015522] = 1015523,
    [1015524] = 1015525,
    [1015526] = 1015527,
    [1015528] = 1015529,
    [1015530] = 1015531,
    [1015532] = 1015533,
    [1015534] = 1015535,
    [1015536] = 1015537,
    [1015538] = 1015539,
    [1015952] = 1015953, --增强Buff：自身血量低于20%时，造成伤害提升X%
    [1015542] = 1015543, --增强Buff：自身生命值低于20%时，受到伤害降低30.17%
    --强化效果部分
    [1016144] = 1016145,
    [1016146] = 1016147,
    [1016148] = 1016149,
    [1016150] = 1016151,
    [1016152] = 1016153,
}
local ConfigRuneIdDict = {
    [1015500] = 20500,
    [1015502] = 20502,
    [1015504] = 20504,
    [1015506] = 20506,
    [1015508] = 20508,
    [1015510] = 20510,
    [1015512] = 20512,
    [1015514] = 20514,
    [1015516] = 20516,
    [1015518] = 20518,
    [1015520] = 20520,
    [1015522] = 20522,
    [1015524] = 20524,
    [1015526] = 20526,
    [1015528] = 20528,
    [1015530] = 20530,
    [1015532] = 20532,
    [1015534] = 20534,
    [1015536] = 20536,
    [1015538] = 20538,
    [1015952] = 20952, --增强Buff：自身血量低于20%时，造成伤害提升X%
    [1015542] = 20542, --增强Buff：自身生命值低于20%时，受到伤害降低30.17%
    --强化效果部分
    [1016144] = 20506,
    [1016146] = 20514,
    [1016148] = 20522,
    [1016150] = 20530,
    [1016152] = 20538,
}

function XBuffScript1015500:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1
    self.signalId = 1015901     --【背水】状态标记，标记管理脚本见1015900
    self.signalCtrlId = 1015900 --【背水】状态管理Buff
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015950, --增强Buff[1]：背水类符纹的效果翻倍
        [2] = 1015952  --增强Buff[2]，自身血量低于20%时，造成伤害提升X%
    }
    self.enhRuneIdDict = {
        [1] = 20950, --增强Buff[1]对应的符纹Id
        [2] = 20952  --增强Buff[2]对应的符纹Id
    }
    --增强Buff[1]配置
    self.enhBuff1MagicLevel = 2          --背水类符纹的效果翻倍对应的等级
    --增强Buff[2]配置
    self.enhBuff2MagicArray = {
        1015967, --额外激活的血属性提升Buff
        1015968, --额外激活的灵属性提升Buff
        1015969  --额外激活的圣属性提升Buff
    }

    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【背水】管理Buff

end

---@param dt number @ delta time 
function XBuffScript1015500:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015500:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015500:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局处理
    if self._uuid == npcUUID and self.battleStartBuffId == buffId then
        --如果有增强Buff[1]存在，则需将后续Buff添加等级调整为2级
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
            self.magicLevel = self.enhBuff1MagicLevel
        end
    end

    --如果自身添加了【背水】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end

    --如果当前BuffID为强化Buff[2]，则需要额外添加3个Buff
    if self._buffId == self.enhBuffIdDict[2] and buffId == self.signalId then
        for _, enhBuff2MagicId in ipairs(self.enhBuff2MagicArray) do
            self._proxy:ApplyMagic(self._uuid, self._uuid, enhBuff2MagicId, self.magicLevel)
        end
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.enhRuneIdDict[2], 1)  --记录一次触发
    end

end

function XBuffScript1015500:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【背水】标记，则删除效果，并关闭宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
    --如果当前BuffID为强化Buff[2]，则需要额外移除3个Buff
    if self._buffId == self.enhBuffIdDict[2] and self.signalId == buffId then
        for _, enhBuff2MagicId in ipairs(self.enhBuff2MagicArray) do
            self._proxy:RemoveBuff(self._uuid, enhBuff2MagicId)
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015500:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015500:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015500

    