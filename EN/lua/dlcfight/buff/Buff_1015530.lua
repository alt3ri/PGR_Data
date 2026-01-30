local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015530 : XBuffScript1015000
local XBuffScript1015530 = XDlcScriptManager.RegBuffScript(1015530, "XBuffScript1015530", Base)


--效果说明：自身血量低于x时，增加护盾y点

function XBuffScript1015530:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015531
    self.magicKind = 1015531
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015530

    