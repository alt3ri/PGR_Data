local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015502 : XBuffScript1015000
local XBuffScript1015502 = XDlcScriptManager.RegBuffScript(1015502, "XBuffScript1015502", Base)


--效果说明：自身血量低于x时，增加火伤y点

function XBuffScript1015502:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015503
    self.magicKind = 1015503
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015502

    