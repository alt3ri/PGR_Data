local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025808 : XTheatre6BuffBase
local XBuffScript1025808 = XDlcScriptManager.RegBuffScript(1025808, "XBuffScript1025808", XTheatre6BuffBase)

--效果说明：白毛对神威定制伤害加成。

function XBuffScript1025808:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------
    self._proxy:AddNpcAttribAdditive(self._npcUUID,ENpcAttrib.PhysicalAmpP,1000)

end

return XBuffScript1025808
