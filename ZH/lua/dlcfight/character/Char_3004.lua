local Base = require("Common/XBigWorldCharBase")

---首席指挥官角色脚本
---@class XCharCommanderChief : XBigWorldCharBase
local XCharCommanderChief = XDlcScriptManager.RegCharScript(3004, "XCharCommanderChief", Base)

---@param proxy XDlcCSharpFuncs
function XCharCommanderChief:Ctor(proxy)
end

function XCharCommanderChief:CommonInit()
    Base.CommonInit(self)
end

---@param dt number @ delta time
function XCharCommanderChief:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharCommanderChief:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharCommanderChief Npc:%d HandleEvent etype:%d", self._npc, eventType))
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharCommanderChief:Terminate()
    Base.Terminate(self)
end

return XCharCommanderChief