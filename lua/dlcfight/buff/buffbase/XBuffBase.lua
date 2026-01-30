local Base = require("Common/XFightBase")
---所有Buff脚本的基类
---@class XBuffBase : XFightBase
---@field _uuid number buff目标NpcUUID
---@field _casterUUID number 施加buff的NpcUUID
---@field _buffId number buff配置Id
---@field _buffUUID number buff运行时的UUID
local XBuffBase = XClass(Base,"XBuffBase")

--region 脚本生命周期
function XBuffBase:_BaseInit() --初始化
    self._uuid = self._proxy:GetSelfBuffNpcUUID()
    self._casterUUID = self._proxy:GetSelfBuffCasterNpcUUID()
    self._buffId = self._proxy:GetSelfBuffId()
    self._buffUUID = self._proxy:GetSelfBuffUUID()
    self:InitLuaEvent()
    self:InitEventCallBackRegister()
end

---@param dt number @ delta time 
function XBuffBase:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XBuffBase:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffBase:HandleLuaEvent(eventType, eventArgs)
    Base.HandleLuaEvent(self, eventType, eventArgs)
end

function XBuffBase:Terminate()
    Base.Terminate(self)
end
--endregion

return XBuffBase
