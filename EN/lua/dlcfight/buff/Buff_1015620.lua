local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015620 : XBuffScript1015600
local XBuffScript1015620 = XDlcScriptManager.RegBuffScript(1015620, "XBuffScript1015620", Base)


--效果说明：自身血量低于x时，增加火伤y点

function XBuffScript1015620:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015621
    self.magicKind = 1015621
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015620

    