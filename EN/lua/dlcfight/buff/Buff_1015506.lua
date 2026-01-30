local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015506 : XBuffScript1015000
local XBuffScript1015506 = XDlcScriptManager.RegBuffScript(1015506, "XBuffScript1015506", Base)


--效果说明：自身血量低于x时，增加火伤y点

function XBuffScript1015506:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015507
    self.magicKind = 1015507
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015506

    