local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015672 : XBuffScript1015650
local XBuffScript1015672 = XDlcScriptManager.RegBuffScript(1015672, "XBuffScript1015672", Base)


--效果说明：疲劳阶段，冰伤增加10%

function XBuffScript1015672:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015673
    self.magicKind = 1015673
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015672

    