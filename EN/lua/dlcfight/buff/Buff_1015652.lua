local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015652 : XBuffScript1015650
local XBuffScript1015652 = XDlcScriptManager.RegBuffScript(1015652, "XBuffScript1015652", Base)


--效果说明：疲劳阶段，火伤增加10%

function XBuffScript1015652:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015653
    self.magicKind = 1015653
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015652

    