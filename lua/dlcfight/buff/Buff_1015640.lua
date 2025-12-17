local Base = require("Buff/Buff_1015600")
---@class XBuffScript1015640 : XBuffScript1015600
local XBuffScript1015640 = XDlcScriptManager.RegBuffScript(1015640, "XBuffScript1015640", Base)


--效果说明：自身血量高于70%/80%/90%时，造成伤害提升40/50/60%

function XBuffScript1015640:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015641
    self.magicKind = 1015641
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015640

    