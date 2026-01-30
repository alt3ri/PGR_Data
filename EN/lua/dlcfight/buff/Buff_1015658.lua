local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015658 : XBuffScript1015650
local XBuffScript1015658 = XDlcScriptManager.RegBuffScript(1015658, "XBuffScript1015658", Base)


--效果说明：疲劳阶段，雷伤增加10%

function XBuffScript1015658:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015659
    self.magicKind = 1015659
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015658

    