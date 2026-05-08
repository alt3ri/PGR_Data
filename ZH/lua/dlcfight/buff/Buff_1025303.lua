local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025303 : XBuffBase
local XBuffScript1025303 = XDlcScriptManager.RegBuffScript(1025303, "XBuffScript1025303", Base)


--效果说明：进入战斗时，自身每有1点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025303:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025101
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    self.originAttrib2 = self.originAttrib1*3
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025904, self.originAttrib2)
end

function XBuffScript1025303:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

function XBuffScript1025303:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1025304, 1)
    end

end

return XBuffScript1025303

    