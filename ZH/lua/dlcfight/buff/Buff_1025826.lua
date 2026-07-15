local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025826 : XTheatre6BuffBase
local XBuffScript1025826 = XDlcScriptManager.RegBuffScript(1025826, "XBuffScript1025826", XTheatre6BuffBase)

--效果说明：白毛常驻伤害加成。

function XBuffScript1025826:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------
    self._proxy:AddNpcAttribAdditive(self._npcUUID,ENpcAttrib.Attack5AmpP,1500)

end

return XBuffScript1025826
