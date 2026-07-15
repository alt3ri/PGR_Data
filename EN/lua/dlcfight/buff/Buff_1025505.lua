local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025505 : XTheatre6BuffBase
local XBuffScript1025505 = XDlcScriptManager.RegBuffScript(1025505, "XBuffScript1025505", XTheatre6BuffBase)

--效果说明：进入战斗时，获得【生命】属性10%的【护盾】。

function XBuffScript1025505:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    --公用的击倒id
    self._protectorMagicId = 1027505
    self.Protector = self:GetNpc():GetProtectorController()
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self._protectorMagicId)
    ------------执行------------
end

return XBuffScript1025505