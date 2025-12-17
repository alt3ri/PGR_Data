local Base = require("Buff/Buff_1015800")
---@class XBuffScript1015838 : XBuffScript1015800
local XBuffScript1015838 = XDlcScriptManager.RegBuffScript(1015838, "XBuffScript1015838", Base)


--效果说明：敌人血量低于20%时，火伤增加40%

function XBuffScript1015838:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015839
    ------------执行------------
end

return XBuffScript1015838