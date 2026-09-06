local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025806 : XTheatre6BuffBase
local XBuffScript1025806 = XDlcScriptManager.RegBuffScript(1025806, "XBuffScript1025806", XTheatre6BuffBase)

--效果说明：白毛对涅缇娅定制伤害加成。

function XBuffScript1025806:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------
end

return XBuffScript1025806
