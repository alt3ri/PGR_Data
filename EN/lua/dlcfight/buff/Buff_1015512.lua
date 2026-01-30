local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015512 : XBuffScript1015000
local XBuffScript1015512 = XDlcScriptManager.RegBuffScript(1015512, "XBuffScript1015512", Base)


--效果说明：自身血量低于x时，增加雷伤y点

function XBuffScript1015512:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015513
    self.magicKind = 1015513
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015512

    