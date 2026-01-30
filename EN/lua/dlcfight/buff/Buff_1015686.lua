local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015686 : XBuffScript1015650
local XBuffScript1015686 = XDlcScriptManager.RegBuffScript(1015686, "XBuffScript1015686", Base)


--效果说明：疲劳阶段，回复增加10%

function XBuffScript1015686:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015687
    self.magicKind = 1015687
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015686

    