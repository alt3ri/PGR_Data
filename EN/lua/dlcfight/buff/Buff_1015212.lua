local Base = require("Common/XFightBase")

---@class XBuffScript1015212 : XFightBase
local XBuffScript1015212 = XDlcScriptManager.RegBuffScript(1015212, "XBuffScript1015212", Base)

--效果说明：护盾被移除时，提升自身50的冰火雷伤，持续2秒
function XBuffScript1015212:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = 1015213
    self.magicId2 = 1015238
    self.magicId3 = 1015239
    self.magicLevel = 1
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015212:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015212:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcChangeProtector)           -- OnNpcAddBuffEvent
end

function XBuffScript1015212:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)
    if TargetId == self._uuid and TotalValue == 0 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId2, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId3, self.magicLevel)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015212:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015212:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015212

    