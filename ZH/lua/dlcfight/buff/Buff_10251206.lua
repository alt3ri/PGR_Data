local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10251206 : XBuffBase
local XBuffScript10251206 = XDlcScriptManager.RegBuffScript(10251206, "XBuffScript10251206", Base)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10251206:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    local locktaregetid, npcid = self._proxy:GetLockTarget() --转换新索敌目标为npcuuid
    if npcid == 0 and locktaregetid == 0 then
        return
    end
    local targertangle, cameraAngle = self._proxy:GetCameraPosInfo(self._uuid, npcid)
    ----XLog.Warning("角度" .. cameraAngle)
    if cameraAngle <= 180 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251202)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251203)
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251204)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251205)
    end
end

---@param dt number @ delta time 
function XBuffScript10251206:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript10251206:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10251206:Terminate()
    Base.Terminate(self)
end

return XBuffScript10251206
