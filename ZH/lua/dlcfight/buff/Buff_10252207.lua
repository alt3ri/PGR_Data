local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10252207 : XBuffBase
local XBuffScript10252207 = XDlcScriptManager.RegBuffScript(10252207, "XBuffScript10252207", Base)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10252207:Init()
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
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252205)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252206)
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252203)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252204)
    end
end

---@param dt number @ delta time 
function XBuffScript10252207:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript10252207:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10252207:Terminate()
    Base.Terminate(self)
end

return XBuffScript10252207
