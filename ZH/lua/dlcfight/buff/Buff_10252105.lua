local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript10252105 : XTheatre6BuffBase
local XBuffScript10252105 = XDlcScriptManager.RegBuffScript(10252105, "XBuffScript10252105", XTheatre6BuffBase)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10252105:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    local npcid = self._enemyUUID--转换新索敌目标为npcuuid
    if npcid == 0 then
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

return XBuffScript10252105
