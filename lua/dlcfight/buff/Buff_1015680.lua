local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015680 : XBuffScript1015650
local XBuffScript1015680 = XDlcScriptManager.RegBuffScript(1015680, "XBuffScript1015680", Base)


--效果说明：疲劳阶段，护盾增加10%

function XBuffScript1015680:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015681
    self.magicKind = 1015681
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015680

    