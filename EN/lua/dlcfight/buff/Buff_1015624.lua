local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015624 : XBuffScript1015600
local XBuffScript1015624 = XDlcScriptManager.RegBuffScript(1015624, "XBuffScript1015624", Base)


--效果说明：自身血量低于x时，增加护盾y点

function XBuffScript1015624:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015625
    self.magicKind = 1015625
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015624

    