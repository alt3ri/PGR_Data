local Base = require("Buff/Buff_1015226")
---@class XBuffScript1015230 : XBuffScript1015226
local XBuffScript1015230 = XDlcScriptManager.RegBuffScript(1015230, "XBuffScript1015230", Base)


--效果说明：每获得2.5%额外【护盾强度】，提升1%冰伤，至多提升160%冰伤

function XBuffScript1015230:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015231
    self.magicKind = 1015231
    ------------执行------------
end

return XBuffScript1015230

    