local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015670 : XBuffScript1015650
local XBuffScript1015670 = XDlcScriptManager.RegBuffScript(1015670, "XBuffScript1015670", Base)


--效果说明：疲劳阶段，冰伤增加10%

function XBuffScript1015670:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015671
    self.magicKind = 1015671
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015670

    