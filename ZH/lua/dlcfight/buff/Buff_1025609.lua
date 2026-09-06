local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025609 : XTheatre6BuffBase
local XBuffScript1025609 = XDlcScriptManager.RegBuffScript(1025609, "XBuffScript1025609", XTheatre6BuffBase)

--效果说明：受到的伤害降低5%，进入战斗时获得1点【魅惑】

function XBuffScript1025609:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025909, 1, 0, 5) --给自己5%减伤
    ------------执行------------
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._hypnoController:CastStackBuff(1, self._npcUUID)
end

return XBuffScript1025609