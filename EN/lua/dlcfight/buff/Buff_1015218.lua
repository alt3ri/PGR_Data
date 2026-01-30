local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015218 : XBuffBase
local XBuffScript1015218 = XDlcScriptManager.RegBuffScript(1015218, "XBuffScript1015218", Base)

--效果说明：释放技能时，提升自身X%【护盾强度】，上限2X%

------------配置------------
local ConfigMagicIdDict = {
    [1015218] = 1015219,
    [1015249] = 1015250,
    [1015251] = 1015252,
    [1015253] = 1015254,
    [1016118] = 1016119
}
local ConfigRuneIdDict = {
    [1015218] = 20218,
    [1015249] = 20249,
    [1015251] = 20251,
    [1015253] = 20253,
    [1016118] = 20253
}

function XBuffScript1015218:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1
    self.count = 1
    self.countMax = 2
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    self.addTable = { false, false }
    self.isAddTable = { false, false }
    ------------执行------------
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)       -- 注册触发ComboStart事件
end

---@param dt number @ delta time 
function XBuffScript1015218:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    for i in ipairs(self.addTable) do
        if self.addTable[i] and not self.isAddTable[i] then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            self.isAddTable[i] = true
        end
    end
end

--region EventCallBack

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015218:HandleLuaEvent(eventType, eventArgs)
    --自定义事件
    Base.HandleLuaEvent(self, eventType, eventArgs)
    if eventType == EFightLuaEvent.AutoChessItemSkillComboStart then
        if self.count <= self.countMax and eventArgs.NpcUUid == self._uuid then
            self.addTable[self.count] = true
            self.count = self.count + 1
        end
    end
end
--endregion

function XBuffScript1015218:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015218

    