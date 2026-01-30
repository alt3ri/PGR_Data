local Base = require("Buff/Buff_1015028")
---@class XBuffScript1015130 : XBuffScript1015028
local XBuffScript1015130 = XDlcScriptManager.RegBuffScript(1015130, "XBuffScript1015130", Base)


--效果说明：每2%【雷伤】可提升自身1%【护盾强度】（此效果提升的上限为120%）

function XBuffScript1015130:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015131
    self.magicKind = 1015131
    self.attrib = ENpcAttrib.Element2AmpP

    self.magicIdShield = 1015229
    self.magicIdHeal = 1015337
    ------------执行------------

end

return XBuffScript1015130

    