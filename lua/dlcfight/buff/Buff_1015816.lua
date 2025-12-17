local Base = require("Buff/Buff_1015800")
---@class XBuffScript1015816 : XBuffScript1015800
local XBuffScript1015816 = XDlcScriptManager.RegBuffScript(1015816, "XBuffScript1015816", Base)


--效果说明：敌人血量低于20%时，火伤增加40%

function XBuffScript1015816:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015817
    ------------执行------------
end

return XBuffScript1015816