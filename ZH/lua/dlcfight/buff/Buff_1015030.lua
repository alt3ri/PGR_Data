local Base = require("Buff/Buff_1015028")
---@class XBuffScript1015030 : XBuffScript1015028
local XBuffScript1015030 = XDlcScriptManager.RegBuffScript(1015030, "XBuffScript1015030", Base)


--效果说明：每2%【火伤】可提升自身1%【回复强度】（此效果提升的上限为120%）

function XBuffScript1015030:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015031
    self.magicKind = 1015031
    self.attrib = ENpcAttrib.Element1AmpP

    self.magicIdShield = 1015227
    self.magicIdHeal = 1015335
    ------------执行------------

end

return XBuffScript1015030

