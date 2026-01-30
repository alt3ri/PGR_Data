local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015638 : XBuffScript1015600
local XBuffScript1015638 = XDlcScriptManager.RegBuffScript(1015638, "XBuffScript1015638", Base)


--效果说明：自身血量低于x时，增加护盾y点

function XBuffScript1015638:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015639
    self.magicKind = 1015639
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015638

    