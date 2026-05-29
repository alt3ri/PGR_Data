local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025413 : XTheatre6BuffBase
local XBuffScript1025413 = XDlcScriptManager.RegBuffScript(1025413, "XBuffScript1025413", XTheatre6BuffBase)

--效果说明：获得【怒火】时，使自身【攻击】属性在本场战斗中提升3点。

function XBuffScript1025413:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025107
    --公用的怒火id
    self.originAttrib1 = 0
    ------------执行------------
end

function XBuffScript1025413:Update(dt)
    --每帧执行
end

function XBuffScript1025413:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._npcUUID == npcUUID and self.signalId == buffId then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025904,1,0,3) --攻击属性
    end

end

return XBuffScript1025413

--25行命名不对
--25行逻辑不对, 应该从主动技能启动的事件中触发
--主动技能启动的事件来自于肉鸽6的buff基类, 需要先继承肉鸽6的buff基类