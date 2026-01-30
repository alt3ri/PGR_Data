local Base = require("Buff/Buff_1015226")
---@class XBuffScript1015228 : XBuffScript1015226
local XBuffScript1015228 = XDlcScriptManager.RegBuffScript(1015228, "XBuffScript1015228", Base)


--效果说明：每获得2.5%额外【护盾强度】，提升1%雷伤，至多提升160%雷伤

function XBuffScript1015228:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015229
    self.magicKind = 1015229
    ------------执行------------
end

return XBuffScript1015228

    