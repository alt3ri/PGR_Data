local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025807 : XTheatre6BuffBase
local XBuffScript1025807 = XDlcScriptManager.RegBuffScript(1025807, "XBuffScript1025807", XTheatre6BuffBase)

--效果说明：白毛对神威定制伤害加成。

function XBuffScript1025807:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    ------------执行------------
end

return XBuffScript1025807
