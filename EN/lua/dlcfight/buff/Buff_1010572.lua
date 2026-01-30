local Base = require("Common/XFightBase")
---@class XBuffScript1010572 : XFightBase
local XBuffScript1010572 = XDlcScriptManager.RegBuffScript(1010572, "XBuffScript1010572", Base)

-- 每隔一段时间在角色周围发射不同的攻击子弹
function XBuffScript1010572:Init() --初始化
    Base.Init(self)
    -----------------------------配置------------------------
    self.cd = 1
    self.bulletId = 10111617  --默认要发射的子弹
    self.count = 4
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
end

---@param dt number @ delta time 
function XBuffScript1010572:Update(dt)
    Base.Update(self, dt)
    
    local isCdOk = self._proxy:GetFightTime(self._uuid) >= self.timer

    if not isCdOk then
        return
    end

    --------------------------触发效果--------------------------------------------------------------------
    local target =self._proxy:GetFightTargetId(self._uuid)

    if (not target) or (target==0) then
        return
    end
    
    self._proxy:LaunchMissile(self._uuid,target,self.bulletId,self.bulletId,0)

    -------------------------触发后要做的事--------------------------------------------------------------
    self.count = self.count - 1

    ----------------------结算-----------------------------------------------------------------------
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)
    
end

return XBuffScript1010572
