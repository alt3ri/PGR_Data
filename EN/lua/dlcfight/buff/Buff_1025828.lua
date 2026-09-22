local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025828 : XTheatre6BuffBase
local XBuffScript1025828 = XDlcScriptManager.RegBuffScript(1025828, "XBuffScript1025828", XTheatre6BuffBase)

--效果说明：涅缇娅对其他角色加成。

function XBuffScript1025828:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------

end

return XBuffScript1025828
