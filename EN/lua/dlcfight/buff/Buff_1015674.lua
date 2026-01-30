local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015674 : XBuffScript1015650
local XBuffScript1015674 = XDlcScriptManager.RegBuffScript(1015674, "XBuffScript1015674", Base)


--效果说明：疲劳阶段，护盾增加10%

function XBuffScript1015674:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015675
    self.magicKind = 1015675
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015674

    