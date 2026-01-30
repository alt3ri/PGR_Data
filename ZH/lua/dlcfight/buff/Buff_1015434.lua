local Base = require("Buff/Buff_1015028")
---@class XBuffScript1015434 : XBuffScript1015028
local XBuffScript1015434 = XDlcScriptManager.RegBuffScript(1015434, "XBuffScript1015434", Base)


--效果说明：每2%【冰伤】可提升自身1%【回复强度】（此效果提升的上限为120%）

function XBuffScript1015434:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015435
    self.magicKind = 1015435
    self.attrib = ENpcAttrib.Element3AmpP

    self.magicIdShield = 1015231
    self.magicIdHeal = 1015339
    ------------执行------------

end

return XBuffScript1015434

