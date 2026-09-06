local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025810 : XTheatre6BuffBase
local XBuffScript1025810 = XDlcScriptManager.RegBuffScript(1025810, "XBuffScript1025810", XTheatre6BuffBase)

--效果说明：涅缇娅对龙骑定制伤害加成。

function XBuffScript1025810:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------
end

return XBuffScript1025810
