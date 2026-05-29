local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10252105 : XBuffBase
local XBuffScript10252105 = XDlcScriptManager.RegBuffScript(10252105, "XBuffScript10252105", Base)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10252105:Init()
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
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252103)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252104)
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252101)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252102)
    end
end

---@param dt number @ delta time 
function XBuffScript10252105:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript10252105:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10252105:Terminate()
    Base.Terminate(self)
end

return XBuffScript10252105
