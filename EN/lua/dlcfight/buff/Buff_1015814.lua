local Base = require("Buff/Buff_1015800")
---@class XBuffScript1015814 : XBuffScript1015800
local XBuffScript1015814 = XDlcScriptManager.RegBuffScript(1015814, "XBuffScript1015814", Base)


--效果说明：敌人血量低于20%时，火伤增加40%

function XBuffScript1015814:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015815
    ------------执行------------
end

return XBuffScript1015814