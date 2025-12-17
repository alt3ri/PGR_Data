local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015304 : XBuffBase
local XBuffScript1015304 = XDlcScriptManager.RegBuffScript(1015304, "XBuffScript1015304", Base)

--效果说明：每受到5次攻击，可提升20.00%<color=#e0cdad>回复效率</color>，最多提升2次

------------配置------------
local ConfigMagicIdDict = {
    [1015304] = 1015305,
    [1015347] = 1015348,
    [1015349] = 1015350,
    [1015351] = 1015352,
    [1016126] = 1016127
}
local ConfigRuneIdDict = {
    [1015304] = 20304,
    [1015347] = 20347,
    [1015349] = 20349,
    [1015351] = 20351,
    [1016126] = 20351
}

function XBuffScript1015304:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1
    self.count = 1
    self.hit = 0
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015304:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015304:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015304:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if targetId == self._uuid then
        self.hit = self.hit + 1
        if self.count <= 2 and self.hit % 5 == 0 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            self.count = self.count + 1
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015304:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015304:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015304

    