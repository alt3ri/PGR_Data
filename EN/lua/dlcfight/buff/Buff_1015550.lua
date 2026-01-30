local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015550 : XBuffBase
local XBuffScript1015550 = XDlcScriptManager.RegBuffScript(1015550, "XBuffScript1015550", Base)
--效果说明：当添加【定时】标记时，获得增益

local ConfigMagicIdDict = {
    [1015550] = 1015551,
    [1015552] = 1015553,
    [1015554] = 1015555,
    [1015556] = 1015557,
    [1015558] = 1015559,
    [1015560] = 1015561,
    [1015562] = 1015563,
    [1015564] = 1015565,
    [1015566] = 1015567,
    [1015568] = 1015569,
    [1015570] = 1015571,
    [1015572] = 1015573,
    [1015574] = 1015575,
    [1015576] = 1015577,
    [1015578] = 1015579,
    [1015580] = 1015581,
    [1015582] = 1015583,
    [1015584] = 1015585,
    [1015586] = 1015587,
    [1015588] = 1015589,
    [1015932] = 1015933, --每间隔5秒，提升5%最大生命值，最多提升20%
    [1015938] = 1015939, --每间隔5秒，永久提升概率类符纹的触发概率5%（最大20%）
    [1015942] = 1015943, --每间隔5秒，使双方获得2秒疲劳状态
    --强化效果部分
    [1016154] = 1016155,
    [1016156] = 1016157,
    [1016158] = 1016159,
    [1016160] = 1016161,
    [1016162] = 1016163,
}
local ConfigRuneIdDict = {
    [1015550] = 20550,
    [1015552] = 20552,
    [1015554] = 20554,
    [1015556] = 20556,
    [1015558] = 20558,
    [1015560] = 20560,
    [1015562] = 20562,
    [1015564] = 20564,
    [1015566] = 20566,
    [1015568] = 20568,
    [1015570] = 20570,
    [1015572] = 20572,
    [1015574] = 20574,
    [1015576] = 20576,
    [1015578] = 20578,
    [1015580] = 20580,
    [1015582] = 20582,
    [1015584] = 20584,
    [1015586] = 20586,
    [1015588] = 20588,
    [1015932] = 20932,
    [1015938] = 20938,
    [1015942] = 20942,
    --强化效果部分
    [1016154] = 20556,
    [1016156] = 20564,
    [1016158] = 20572,
    [1016160] = 20580,
    [1016162] = 20588,
}

function XBuffScript1015550:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1 --初始buff等级1级
    self.signalId = 1015911         --【定时】状态标记，标记管理脚本见1015910
    self.signalCtrlId = 1015910     --【定时】状态管理Buff
    self.battleStartBuffId = 1015992    --战斗开始标记buff

    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015590, --增强Buff[1]：带有【每隔X秒】条件的效果，成功触发后的效果提升100%
        [2] = 1015930, --增强Buff[2]，自身生命低于20%时，定时类符纹属性提升效果提升100%
        [3] = 1015944, --增强Buff[3]，疲劳阶段，定时类符纹的属性提升效果效果提升100%
    }
    self.enhRuneIdDict = {
        [1] = 20590, --增强Buff[1]对应的符纹Id
        [2] = 20930, --增强Buff[2]对应的符纹Id
        [3] = 20944, --增强Buff[3]对应的符纹Id
    }
    --增强Buff[1]配置
    self.enhBuff1MagicLevel = 1     --增强Buff[1]提升的效果等级
    --增强Buff[2]配置
    self.enhBuff2MagicLevel = 1     --增强Buff[2]提升的效果等级
    self.enhBuff2SignalId = 1015901 --【背水】标记Id
    self.enhBuff2SignalCtrlId = 1015900 --【背水】标记控制Buff
    --增强Buff[3]配置
    self.enhBuff3MagicLevel = 1     --增强Buff[3]提升的效果等级
    self.enhBuff3SignalId = 1015909 --【疲劳】标记Id
    self.enhBuff3SignalCtrlId = 1015908 --【疲劳】标记控制Buff
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【定时】管理Buff

end

---@param dt number @ delta time
function XBuffScript1015550:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end


--region EventCallBack
function XBuffScript1015550:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015550:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【定时】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        local calMagicLevel = self.magicLevel
        --若有强化Buff[1]则提升效果
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
            calMagicLevel = calMagicLevel + self.enhBuff1MagicLevel
        end
        --若有强化Buff[2]且处于【背水】状态下则提升效果
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2]) and self._proxy:CheckBuffByKind(self._uuid, self.enhBuff2SignalId) then
            calMagicLevel = calMagicLevel + self.enhBuff2MagicLevel
        end
        --若有强化Buff[3]且处于【疲劳】状态下则提升效果
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[3]) and self._proxy:CheckBuffByKind(self._uuid, self.enhBuff3SignalId) then
            calMagicLevel = calMagicLevel + self.enhBuff3MagicLevel
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, calMagicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
    --开始战斗处理
    if self._uuid == npcUUID and self.battleStartBuffId == buffId then
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2]) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.enhBuff2SignalCtrlId, 1)   --为自己添加【背水】管理Buff
        end
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[3]) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.enhBuff3SignalCtrlId, 1)   --为自己添加【疲劳】管理Buff
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015550:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015550:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015550
