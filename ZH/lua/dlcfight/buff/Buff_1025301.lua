local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025301 : XBuffBase
local XBuffScript1025301 = XDlcScriptManager.RegBuffScript(1025301, "XBuffScript1025301", Base)


--效果说明：造成【击飞】时，自身【攻击】属性在本场战斗中提升3点。

function XBuffScript1025301:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025101
    ------------执行------------
end

function XBuffScript1025301:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

function XBuffScript1025301:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1025904,1,0, 3)
    end

end

return XBuffScript1025301

    