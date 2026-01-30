---@class XBigWorldCharBase
---@field _uuid number 当前脚本挂载的NpcId
---@field _proxy XDlcCSharpFuncs
local XBigWorldCharBase = XClass(nil, "FightBase")

---@param proxy XDlcCSharpFuncs
function XBigWorldCharBase:Ctor(proxy)
    self._proxy = proxy
end

function XBigWorldCharBase:CommonInit()
    self._uuid = self._proxy:GetSelfNpcId()
end

function XBigWorldCharBase:Init()
    self:CommonInit()
end

function XBigWorldCharBase:GainControl()
    self:CommonInit()
end

---@param dt number @ delta time
function XBigWorldCharBase:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XBigWorldCharBase:HandleEvent(eventType, eventArgs)
end

---@param eventType number 来自EFightLuaEvent
---@param eventArgs table
function XBigWorldCharBase:HandleLuaEvent(eventType, eventArgs)
end

function XBigWorldCharBase:CancelControl()
end

---@desc 生命周期里CleanUp的上一步，可以理解为脚本专用的CleanUp
---@desc 回收前调用
function XBigWorldCharBase:Terminate()
    
end


return XBigWorldCharBase
