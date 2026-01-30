local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015508 : XBuffScript1015000
local XBuffScript1015508 = XDlcScriptManager.RegBuffScript(1015508, "XBuffScript1015508", Base)


--效果说明：自身血量低于x时，增加雷伤y点

function XBuffScript1015508:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015509
    self.magicKind = 1015509
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015508

    