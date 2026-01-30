local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015654 : XBuffScript1015650
local XBuffScript1015654 = XDlcScriptManager.RegBuffScript(1015654, "XBuffScript1015654", Base)


--效果说明：疲劳阶段，火伤增加10%

function XBuffScript1015654:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015655
    self.magicKind = 1015655
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015654

    