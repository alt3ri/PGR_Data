local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015528 : XBuffScript1015000
local XBuffScript1015528 = XDlcScriptManager.RegBuffScript(1015528, "XBuffScript1015528", Base)


--效果说明：自身血量低于x时，增加护盾y点

function XBuffScript1015528:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015529
    self.magicKind = 1015529
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015528

    