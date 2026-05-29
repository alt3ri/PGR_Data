local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025227 : XTheatre6BuffBase
local XBuffScript1025227 = XDlcScriptManager.RegBuffScript(1025227, "XBuffScript1025227", XTheatre6BuffBase)


--效果说明：进入战斗时，自身每有1点【体力】属性，自身【生命值上限】在本场战斗中提升3点，并恢复等量【生命值】。

function XBuffScript1025227:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.BuffId = 1025905 --生命buffid
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    XLog.Error("....."..self.originAttrib1)
    self.originAttrib2 = self.originAttrib1 * 3
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId,1,0, self.originAttrib2)
end

return XBuffScript1025227

