local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1010013 : XFightBase
local XBuffScript1010013 = XDlcScriptManager.RegBuffScript(1010013, "XBuffScript1010013", Base)

--效果说明：每隔一秒在敌人位置生成攻击子弹
function XBuffScript1010013:Init()--初始化
    Base.Init(self)
    -----------------------------配置------------------------
    self.cd = 1
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
    self.bulletId = 10100614
end

---@param dt number @ delta time 
function XBuffScript1010013:Update(dt)
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
function XBuffScript1010013:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1010013:Terminate()
    Base.Terminate(self)
end

return XBuffScript1010013
