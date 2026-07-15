local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025217 : XTheatre6BuffBase
local XBuffScript1025217 = XDlcScriptManager.RegBuffScript(1025217, "XBuffScript1025217", XTheatre6BuffBase)

--效果说明：进入战斗时，自身每有30点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025217:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint)
    self.originAttrib2 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock)
    self.originAttrib3 = (self.originAttrib1 + self.originAttrib2) // 30
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025903,1,0, self.originAttrib3)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,self.originAttrib3,1)
end

return XBuffScript1025217

    