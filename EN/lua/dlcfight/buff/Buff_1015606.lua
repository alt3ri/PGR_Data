local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015606 : XBuffScript1015600
local XBuffScript1015606 = XDlcScriptManager.RegBuffScript(1015606, "XBuffScript1015606", Base)


--效果说明：自身血量低于x时，增加火伤y点

function XBuffScript1015606:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015607
    self.magicKind = 1015607
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015606

    