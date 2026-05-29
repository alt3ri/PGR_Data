local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025311 : XTheatre6BuffBase
local XBuffScript1025311 = XDlcScriptManager.RegBuffScript(1025207, "XBuffScript1025311", XTheatre6BuffBase)

--效果说明：处于【点燃】状态的对手，每有1层【点燃】则造成的伤害降低2%。

function XBuffScript1025311:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self._proxy:ApplyMagic(self._enemyUUID, self._enemyUUID, 1025312,1,0, 1) --给对面发个1025312
end

return XBuffScript1025311

    