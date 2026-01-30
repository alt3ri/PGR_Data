local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015600 : XBuffBase
local XBuffScript1015600 = XDlcScriptManager.RegBuffScript(1015600, "XBuffScript1015600", Base)

--效果说明：当自身处于【浑身】状态时时，获得Buff

local ConfigMagicIdDict = {
    [1015600] = 1015601,
    [1015602] = 1015603,
    [1015604] = 1015605,
    [1015606] = 1015607,
    [1015608] = 1015609,
    [1015610] = 1015611,
    [1015612] = 1015613,
    [1015614] = 1015615,
    [1015616] = 1015617,
    [1015618] = 1015619,
    [1015620] = 1015621,
    [1015622] = 1015623,
    [1015624] = 1015625,
    [1015626] = 1015627,
    [1015628] = 1015629,
    [1015630] = 1015631,
    [1015632] = 1015633,
    [1015634] = 1015635,
    [1015636] = 1015637,
    [1015638] = 1015639,
    [1015640] = 1015641,
    [1015642] = { 1015643, 1015644, 1015645, 1015646 }, --增强Buff，可同时获得3个效果
    --强化效果部分
    [1016164] = 1016165,
    [1016166] = 1016167,
    [1016168] = 1016169,
    [1016170] = 1016171,
    [1016172] = 1016173,

}
local ConfigRuneIdDict = {
    [1015600] = 20600,
    [1015602] = 20602,
    [1015604] = 20604,
    [1015606] = 20606,
    [1015608] = 20608,
    [1015610] = 20610,
    [1015612] = 20612,
    [1015614] = 20614,
    [1015616] = 20616,
    [1015618] = 20618,
    [1015620] = 20620,
    [1015622] = 20622,
    [1015624] = 20624,
    [1015626] = 20626,
    [1015628] = 20628,
    [1015630] = 20630,
    [1015632] = 20632,
    [1015634] = 20634,
    [1015636] = 20636,
    [1015638] = 20638,
    [1015640] = 20640,
    [1015642] = 20642,
    --强化效果部分
    [1016164] = 20606,
    [1016166] = 20614,
    [1016168] = 20622,
    [1016170] = 20630,
    [1016172] = 20638,
}

function XBuffScript1015600:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1
    self.signalId = 1015903     --【浑身】状态标记，标记管理脚本见1015900
    self.signalCtrlId = 1015902 --【浑身】状态管理Buff
    self.enhBuffIdDict = {
        [1] = 1015642, --增强Buff[1]，触发浑身状态时，造成的伤害增加，Buff为数组形式需单独处理
        [2] = 1015954, --带有【自身血量高于X%时触发】条件的所有属性提升效果额外触发一次，效果叠加(等级+1）
        [3] = 1015956, --带有【自身血量高于X%时触发】条件的所有触发效果翻倍（等级+1）
    }
    --增强Buff[2]配置
    self.enhBuff2Level = 1
    --增强Buff[3]配置
    self.enhBuff3Level = 1
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【浑身】管理Buff

end

---@param dt number @ delta time 
function XBuffScript1015600:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015600:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015600:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【浑身】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then

        local isEnhBuff2Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2])
        local isEnhBuff3Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[3])
        local magicLevel = self.magicLevel
        if isEnhBuff2Active then
            magicLevel = magicLevel + self.enhBuff2Level
        end
        if isEnhBuff3Active then
            magicLevel = magicLevel + self.enhBuff3Level
        end
        if self._buffId == self.enhBuffIdDict[1] then
            --若是强化Buff[1]触发的效果，则需要添加3个强化效果
            for i in ipairs(self.magicId) do
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId[i], self.magicLevel)
            end
        else
            --不是强化Buff[1]时，仅添加1个强化效果即可
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        end
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
    end
end

function XBuffScript1015600:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【浑身】标记，则删除效果，并关闭宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        if self._buffId == self.enhBuffIdDict[1] then
            --若是强化Buff[1]触发的效果，则需要移除3个强化效果
            for i in ipairs(self.magicId) do
                self._proxy:RemoveBuff(self._uuid, self.magicId[i])
            end
        else
            --不是强化Buff[1]时，仅移除1个强化效果即可
            self._proxy:RemoveBuff(self._uuid, self.magicId)
        end
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015600:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015600:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015600

    