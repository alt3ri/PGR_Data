local Base = require("Common/XFightBase")

---@class XBuffScript1015220 : XFightBase
local XBuffScript1015220 = XDlcScriptManager.RegBuffScript(1015220, "XBuffScript1015220", Base)

--效果说明：获得护盾时，提升自身5点【护盾强度】，上限100点
function XBuffScript1015220:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015221
    self.magicLevel = 1
    self.count = 1
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015220:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015220:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)           -- OnNpcAddBuffEvent
end

function XBuffScript1015220:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue, MagicId)
    if TargetId == self._uuid and self.count <= 20 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.count = self.count + 1
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015220:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015220:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015220

    