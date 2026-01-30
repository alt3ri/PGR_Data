local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015668 : XBuffScript1015650
local XBuffScript1015668 = XDlcScriptManager.RegBuffScript(1015668, "XBuffScript1015668", Base)


--效果说明：疲劳阶段，冰伤增加10%

function XBuffScript1015668:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015669
    self.magicKind = 1015669
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015668

    