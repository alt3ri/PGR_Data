local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript10252207 : XTheatre6BuffBase
local XBuffScript10252207 = XDlcScriptManager.RegBuffScript(10252207, "XBuffScript10252207", XTheatre6BuffBase)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10252207:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    local npcid = self._enemyUUID--转换新索敌目标为npcuuid
    if npcid == 0 then
        return
    end
    local targertangle, cameraAngle = self._proxy:GetCameraPosInfo(self._uuid, npcid)
    ----XLog.Warning("角度" .. cameraAngle)
    if cameraAngle >= 180 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252205)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252206)
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252203)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10252204)
    end
end

return XBuffScript10252207
