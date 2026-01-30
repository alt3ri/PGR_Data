local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015662 : XBuffScript1015650
local XBuffScript1015662 = XDlcScriptManager.RegBuffScript(1015662, "XBuffScript1015662", Base)


--效果说明：疲劳阶段，雷伤增加10%

function XBuffScript1015662:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015663
    self.magicKind = 1015663
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015662

    