local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025219 : XBuffBase
local XBuffScript1025219 = XDlcScriptManager.RegBuffScript(1025219, "XBuffScript1025219", Base)


--效果说明：进入战斗时，自身每有1点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025219:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------

end

function XBuffScript1025219:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Life)
    self.originAttrib2 = self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
    self.originAttrib3 = ((self.originAttrib2-self.originAttrib1)/self.originAttrib2)//5
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025909,1,0, self.originAttrib3)
    --不太对，这样会变成每帧都加buff，一直叠层
    --但好像1015300是这么写的，回头试一下数值对不对吧
end

return XBuffScript1025219

    