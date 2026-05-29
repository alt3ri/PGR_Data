local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025303 : XTheatre6BuffBase
local XBuffScript1025303 = XDlcScriptManager.RegBuffScript(1025303, "XBuffScript1025303", XTheatre6BuffBase)


--效果说明：对手被【击飞】后，3秒内受到伤害提升15%。

function XBuffScript1025303:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
end


function XBuffScript1025303:OnLuaAffixHitFly(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._enemyUUID, self._enemyUUID, 1025304, 1) --304的效果是3秒内受伤增加15%
    self:LogError("303抓到了击飞效果"..self._npcUUID)
end



return XBuffScript1025303

    