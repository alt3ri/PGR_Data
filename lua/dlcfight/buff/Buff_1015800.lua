local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015800 : XBuffBase
local XBuffScript1015800 = XDlcScriptManager.RegBuffScript(1015800, "XBuffScript1015800", Base)

local ConfigMagicIdDict = {
    [1015800] = 1015801,
    [1015802] = 1015803,
    [1015804] = 1015805,
    [1015806] = 1015807,
    [1015808] = 1015809,
    [1015810] = 1015811,
    [1015812] = 1015813,
    [1015814] = 1015815,
    [1015816] = 1015817,
    [1015818] = 1015819,
    [1015820] = 1015821,
    [1015822] = 1015823,
    [1015824] = 1015825,
    [1015826] = 1015827,
    [1015828] = 1015829,
    [1015830] = 1015831,
    [1015832] = 1015833,
    [1015834] = 1015835,
    [1015836] = 1015837,
    [1015838] = 1015839,
    [1015962] = 1015963, --敌人血量低于20%时，自身造成伤害提升50%
    [1015973] = 1015974, --自身生命百分比高于对方时，自身攻击力提升100%，并视为满足【敌人血量低于X%】的条件，触发相关效果。
    --强化效果部分
    [1016204] = 1016205,
    [1016206] = 1016207,
    [1016208] = 1016209,
    [1016210] = 1016211,
    [1016212] = 1016213,
}
local ConfigRuneIdDict = {
    [1015800] = 20800,
    [1015802] = 20802,
    [1015804] = 20804,
    [1015806] = 20806,
    [1015808] = 20808,
    [1015810] = 20810,
    [1015812] = 20812,
    [1015814] = 20814,
    [1015816] = 20816,
    [1015818] = 20818,
    [1015820] = 20820,
    [1015822] = 20822,
    [1015824] = 20824,
    [1015826] = 20826,
    [1015828] = 20828,
    [1015830] = 20830,
    [1015832] = 20832,
    [1015834] = 20834,
    [1015836] = 20836,
    [1015838] = 20838,
    [1015962] = 20962, --敌人血量低于20%时，自身造成伤害提升50%
    [1015973] = 20973, --自身生命百分比高于对方时，自身攻击力提升x%，并视为满足【敌人血量低于X%】的条件，触发相关效果。
    --强化效果部分
    [1016204] = 20806,
    [1016206] = 20814,
    [1016208] = 20822,
    [1016210] = 20830,
    [1016212] = 20838,
}

--效果说明：处于【斩杀】状态时，获得增幅

function XBuffScript1015800:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1
    self.signalId = 1015905     --【斩杀】状态标记，标记管理脚本见1015904
    self.signalCtrlId = 1015904 --【斩杀】状态管理Buff
    self.enhBuffIdDict = {
        [1] = 1015842, --增强Buff[1]：带有【敌人血量低于X%】条件的所有触发效果提升100%
        [2] = 1015962, --增强Buff[2]：敌人血量低于20%时，自身造成伤害提升50%
    }
    self.enhRuneIdDict = {
        [1] = 20842, --增强Buff[1]：带有【敌人血量低于X%】条件的所有触发效果提升100%
        [2] = 20962, --增强Buff[2]：敌人血量低于20%时，自身造成伤害提升50%
    }
    --Buff[1]强化配置，效果说明：有此Buff时，读取2级数值
    self.magicLevelEnhance = 2          --强化后的Buff等级
    --Buff[2]强化配置
    self.enhBuff2MagicId = { 1015970, 1015971, 1015972 }        --全属性伤害提升Buff
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【斩杀】管理Buff

end

---@param dt number @ delta time 
function XBuffScript1015800:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015800:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015800:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【斩杀】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        --如果有增强Buff[1]存在，则将Buff等级替换为2级
        local isEnhBuff1Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1])
        local isEnhBuff2Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2])
        if isEnhBuff1Active then
            self.magicLevel = self.magicLevelEnhance
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        --如果有增强Buff[2]存在，则额外添加效果
        if isEnhBuff2Active then
            for _, magicId in ipairs(self.enhBuff2MagicId) do
                self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, self.magicLevel)
            end
        end
    end
end

function XBuffScript1015800:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【斩杀】标记，则删除效果，并关闭宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
        --如果有增强Buff[2]存在，则额外删除效果
        local isEnhBuff2Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2])
        if isEnhBuff2Active then
            for _, magicId in ipairs(self.enhBuff2MagicId) do
                self._proxy:RemoveBuff(self._uuid, magicId)
            end
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015800:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015800:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015800
