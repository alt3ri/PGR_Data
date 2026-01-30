local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015618 : XBuffScript1015600
local XBuffScript1015618 = XDlcScriptManager.RegBuffScript(1015618, "XBuffScript1015618", Base)


--效果说明：自身血量低于x时，增加火伤y点

function XBuffScript1015618:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015619
    self.magicKind = 1015619
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015618

    