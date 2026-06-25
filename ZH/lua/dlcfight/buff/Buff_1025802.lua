local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025802 : XTheatre6BuffBase
local XBuffScript1025802 = XDlcScriptManager.RegBuffScript(1025802, "XBuffScript1025802", XTheatre6BuffBase)

--效果说明：白毛对神威定制伤害加成。

function XBuffScript1025802:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------
end

return XBuffScript1025802
