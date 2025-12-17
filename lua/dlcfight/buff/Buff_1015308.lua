local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015308 : XBuffBase
local XBuffScript1015308 = XDlcScriptManager.RegBuffScript(1015308, "XBuffScript1015308", Base)

--效果说明：每存活10秒，【回复效率】增加X点（上限2X点）

------------配置------------
local ConfigMagicIdDict = {
    [1015308] = 1015309,
    [1015353] = 1015354,
    [1015355] = 1015356,
    [1015357] = 1015358,
    [1016128] = 1016129
}
local ConfigRuneIdDict = {
    [1015308] = 20308,
    [1015353] = 20353,
    [1015355] = 20355,
    [1015357] = 20357,
    [1016128] = 20357
}

function XBuffScript1015308:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1
    self.liveCount = 1
    self.liveMaxCount = 2
    self.timeDis = 10
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    self.initTimeTrigger = true
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    ------------执行------------
    self.timer = self._proxy:GetNpcTime(self._uuid)
end

---@param dt number @ delta time 
function XBuffScript1015308:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end

    if self.initTimeTrigger then
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.timeDis
        self.initTimeTrigger = false
    end

    if self._proxy:IsNpcDead(self._uuid) then
        return
    end

    if self.liveCount <= self.liveMaxCount and self._proxy:GetNpcTime(self._uuid) > self.timer then
        self.magicLevel = self.liveCount
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.liveCount = self.liveCount + 1
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.timeDis
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015308:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015308:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015308

    