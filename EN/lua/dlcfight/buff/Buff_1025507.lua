local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025507 : XTheatre6BuffBase
local XBuffScript1025507 = XDlcScriptManager.RegBuffScript(1025507, "XBuffScript1025507", XTheatre6BuffBase)

--效果说明：持有【护盾】时，造成伤害提升10%。

function XBuffScript1025507:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.Count = 10
    self.DmgBuff = 1025906
    self.IfProtector = 0
    ------------执行------------
end

function XBuffScript1025507:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1025507:AfterDamageCalc(eventArgs) -- 受到或造成伤害时刷新增伤
    if self._proxy:GetNpcProtector(self._npcUUID) >= 0 then
        if self.IfProtector == 0 then
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.DmgBuff, 1, 0, self.Count)
            self.IfProtector = 1
        end
    else
        if self.IfProtector == 1 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self.DmgBuff,self.Count)
            self.IfProtector = 0
        end
    end
end

function XBuffScript1025507:OnNpcAddBuffEvent(eventArgs) -- 获得buff时刷新增伤
    if self._proxy:GetNpcProtector(self._npcUUID) >= 0 then
        if self.IfProtector == 0 then
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.DmgBuff, 1, 0, self.Count)
            self.IfProtector = 1
        end
    else
        if self.IfProtector == 1 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self.DmgBuff,self.Count)
            self.IfProtector = 0
        end
    end
end

return XBuffScript1025507
