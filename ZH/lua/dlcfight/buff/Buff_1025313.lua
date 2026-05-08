local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025313 : XBuffBase
local XBuffScript1025313 = XDlcScriptManager.RegBuffScript(1025313, "XBuffScript1025313", Base)


--效果说明：进入战斗时，自身每有1点【超算】属性或【拼刀】属性，【体力】属性提升1点。

function XBuffScript1025313:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025103
    --公用的击飞id
    self.originAttrib3 = 0
    self.originAttrib4 = 10
    self.ChanceCheck = 0
    ------------执行------------
end

function XBuffScript1025313:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Life)*2
    self.originAttrib2 = self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
    if self.originAttrib1 <= self.originAttrib2 then
        if self.ChanceCheck == 0 then
            self.originAttrib4 = self.originAttrib4 + self.originAttrib3 * 5
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1025910,1,0, self.originAttrib4)
            self.ChanceCheck = 1
        end
    end
end

function XBuffScript1025313:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._uuid == npcUUID and self.signalId == buffId then
        self.originAttrib3 = self.originAttrib3 + 1
        --触发晕眩时，计数器+1
    end

end

return XBuffScript1025313

    