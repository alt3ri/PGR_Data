local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025110 : XBuffBase
local XBuffScript1025110 = XDlcScriptManager.RegBuffScript(1025110, "XBuffScript1025110", Base)


--效果说明：进入战斗时，自身每有1点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025110:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    self.originAttrib2 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.WrestlePoint)
    self.originAttrib3 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.OverClock)
    -- XLog.Error(".....当前【体力】属性"..self.originAttrib1)
    -- XLog.Error(".....当前【拼刀】属性"..self.originAttrib2)
    -- XLog.Error(".....当前【超算】属性"..self.originAttrib3)
end

return XBuffScript1025110

    