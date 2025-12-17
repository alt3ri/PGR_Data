local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015682 : XBuffScript1015650
local XBuffScript1015682 = XDlcScriptManager.RegBuffScript(1015682, "XBuffScript1015682", Base)


--效果说明：疲劳阶段，回复增加10%

function XBuffScript1015682:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015683
    self.magicKind = 1015683
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015682

    