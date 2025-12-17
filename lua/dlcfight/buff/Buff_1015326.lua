local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015326 : XBuffBase
local XBuffScript1015326 = XDlcScriptManager.RegBuffScript(1015326, "XBuffScript1015326", Base)

--效果说明：每次回复生命值时，提升X点火伤/雷伤/冰伤，上限2X点

------------配置------------
local ConfigMagicIdDict1 = {
    [1015326] = 1015327,
    [1015365] = 1015366,
    [1015369] = 1015370,
    [1015373] = 1015374,
    [1016132] = 1016133
}
local ConfigMagicIdDict2 = {
    [1015326] = 1015328,
    [1015365] = 1015367,
    [1015369] = 1015371,
    [1015373] = 1015375,
    [1016132] = 1016134
}
local ConfigMagicIdDict3 = {
    [1015326] = 1015329,
    [1015365] = 1015368,
    [1015369] = 1015372,
    [1015373] = 1015376,
    [1016132] = 1016135
}
local ConfigRuneIdDict = {
    [1015326] = 20326,
    [1015365] = 20365,
    [1015369] = 20369,
    [1015373] = 20373,
    [1016132] = 20373
}

function XBuffScript1015326:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = ConfigMagicIdDict1[self._buffId]
    self.magicId2 = ConfigMagicIdDict2[self._buffId]
    self.magicId3 = ConfigMagicIdDict3[self._buffId]
    self.magicLevel = 1
    self.count = 1
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
    self.maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    self.historyHp = self.maxHp
end

---@param dt number @ delta time 
function XBuffScript1015326:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.currentHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.changeHp = self.currentHp - self.historyHp
    self.historyHp = self.currentHp

    if self.changeHp > 0 and self.count <= 10 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId2, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId3, self.magicLevel)
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.count = self.count + 1
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015326:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)

end

function XBuffScript1015326:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015326

    