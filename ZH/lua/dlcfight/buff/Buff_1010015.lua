local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1010015 : XFightBase
local XBuffScript1010015 = XDlcScriptManager.RegBuffScript(1010015, "XBuffScript1010015", Base)

--效果说明：延迟一段时间给自己发射一颗子弹攻击自己。
function XBuffScript1010015:Init() --初始化
    Base.Init(self)
    -----------------------------配置------------------------
    self.cd = 1
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
    self.bulletId = 10100916
end

---@param dt number @ delta time 
function XBuffScript1010015:Update(dt)
    Base.Update(self, dt)
    local isCdOk = self._proxy:GetFightTime(self._uuid) >= self.timer

    if not isCdOk then
        return
    end
    if not self._proxy:CheckNpc(self._casterUUID) or not self._proxy:CheckNpc(self._uuid) then --目标或自己死了后续就不执行
        return
    end
    --------------------------触发效果--------------------------------------------------------------------
    self._proxy:LaunchMissile(self._casterUUID,self._uuid,self.bulletId,self.bulletId,0)
    
    ----------------------结算-----------------------------------------------------------------------
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1010015:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1010015:Terminate()
    Base.Terminate(self)
end

return XBuffScript1010015
