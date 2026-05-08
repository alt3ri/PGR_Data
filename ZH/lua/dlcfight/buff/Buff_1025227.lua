local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025227 : XBuffBase
local XBuffScript1025227 = XDlcScriptManager.RegBuffScript(1025227, "XBuffScript1025227", Base)


--效果说明：进入战斗时，自身每有1点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025227:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    XLog.Error("....."..self.originAttrib1)
    self.originAttrib2 = self.originAttrib1 * 3
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025905,1,0, self.originAttrib2)
end

function XBuffScript1025227:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

return XBuffScript1025227

