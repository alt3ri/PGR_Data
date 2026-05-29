local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025413 : XTheatre6BuffBase
local XBuffScript1025413 = XDlcScriptManager.RegBuffScript(1025413, "XBuffScript1025413", XTheatre6BuffBase)

--效果说明：获得【怒火】时，使自身【攻击】属性在本场战斗中提升2点。

function XBuffScript1025413:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.signalId = 1025107        --公用的怒火id
    self.trigger = false           --重复触发开关，每个技能仅能触发1次
    self.value = 2
    ------------执行------------
end

function XBuffScript1025413:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --防重复检测
    self.trigger = false
end

function XBuffScript1025413:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) -- OnNpcAddBuffEvent
end

function XBuffScript1025413:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self.trigger then return end
    if self._npcUUID == npcUUID and self.signalId == buffId then
        self:AddAttrib(ENpcAttrib.Attack, self.value, self._npcUUID, self._npcUUID)
        self.trigger = true
    end
end

return XBuffScript1025413
