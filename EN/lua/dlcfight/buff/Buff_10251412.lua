local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10251412 : XBuffBase
local XBuffScript10251412 = XDlcScriptManager.RegBuffScript(10251412, "XBuffScript10251412", Base)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10251412:Init()
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
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251410)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251411)
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251408)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10251409)
    end
end

---@param dt number @ delta time 
function XBuffScript10251412:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript10251412:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10251412:Terminate()
    Base.Terminate(self)
end

return XBuffScript10251412
