local Base = require("Common/XFightBase")
---@class XBuffScript1011008 : XFightBase
local XBuffScript1011008 = XDlcScriptManager.RegBuffScript(1011008, "XBuffScript1011008", Base)

-- 每隔一段时间在角色周围发射不同的攻击子弹
function XBuffScript1011008:Init() --初始化
    Base.Init(self)
    -----------------------------配置------------------------
    self.cd = 2
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
    self.bulletId = 10111902  --要发射的子弹Id
    self.count = 3
end

---@param dt number @ delta time 
function XBuffScript1011008:Update(dt)
    Base.Update(self, dt)
    local isCdOk = self._proxy:GetFightTime(self._uuid) >= self.timer

    if not isCdOk then
        return
    end

    --------------------------触发效果--------------------------------------------------------------------
    local target =self._proxy:GetFightTargetId(self._uuid)
    if self.count == 3 then
        self.bulletId=10111901
    end
    if self.count == 2 then
        self.bulletId=10111902
    end
    if self.count == 1 then
        self.bulletId=10111903
    end
    
    if (not target) or (target==0) then
        return
    end

    self._proxy:LaunchMissile(self._uuid,target,self.bulletId,self.bulletId,0)

    -------------------------触发后要做的事--------------------------------------------------------------
    self.count = self.count - 1
    
    ----------------------结算-----------------------------------------------------------------------
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
    
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1011008:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1011008:Terminate()
    Base.Terminate(self)
end

return XBuffScript1011008
