local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025827 : XTheatre6BuffBase
local XBuffScript1025827 = XDlcScriptManager.RegBuffScript(1025827, "XBuffScript1025827", XTheatre6BuffBase)

--效果说明：维罗妮卡对其他角色加成。

function XBuffScript1025827:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------

end

return XBuffScript1025827
