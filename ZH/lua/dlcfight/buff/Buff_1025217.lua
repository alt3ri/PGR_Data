local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025217 : XBuffBase
local XBuffScript1025217 = XDlcScriptManager.RegBuffScript(1025217, "XBuffScript1025217", Base)


--效果说明：进入战斗时，自身每有1点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025217:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.WrestlePoint)
    self.originAttrib2 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.OverClock)
    self.originAttrib3 = self.originAttrib1 + self.originAttrib2
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025903,1,0, self.originAttrib3)
end

return XBuffScript1025217

    