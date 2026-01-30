---大世界玩家角色基类
---@class XBigWorldPlayerCharBase
local XBigWorldPlayerCharBase = XClass(nil, "XPlayerCharBase")

---@param proxy XDlcCSharpFuncs
function XBigWorldPlayerCharBase:Ctor(proxy)
    self._proxy = proxy
end

function XBigWorldPlayerCharBase:Init()
    self._uuid = self._proxy:GetSelfNpcId() ---@type number
end

---@param dt number @ delta time
function XBigWorldPlayerCharBase:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XBigWorldPlayerCharBase:HandleEvent(eventType, eventArgs)
end

function XBigWorldPlayerCharBase:Terminate()
    self._proxy = nil
    self._uuid = 0
end

return XBigWorldPlayerCharBase