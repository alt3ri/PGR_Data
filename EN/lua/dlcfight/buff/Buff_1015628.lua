local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015628 : XBuffScript1015600
local XBuffScript1015628 = XDlcScriptManager.RegBuffScript(1015628, "XBuffScript1015628", Base)


--效果说明：自身血量低于x时，增加护盾y点

function XBuffScript1015628:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015629
    self.magicKind = 1015629
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015628

    