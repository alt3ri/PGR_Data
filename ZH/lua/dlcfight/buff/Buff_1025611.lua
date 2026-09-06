local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025611 : XTheatre6BuffBase
local XBuffScript1025611 = XDlcScriptManager.RegBuffScript(1025611, "XBuffScript1025611", XTheatre6BuffBase)

--效果说明：首次触发【失心】后，获得3点【魅惑】

function XBuffScript1025611:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    ------------执行------------
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.ChanceCheck = 0

end

function XBuffScript1025611:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
end

function XBuffScript1025611:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self._hypnoController.LostHeartTriggerBuff then return end --失心标记
    if self.ChanceCheck == 0 then
        self._hypnoController:CastStackBuff(3, self._npcUUID)
        self.ChanceCheck = 1       --仅生效一次
    end
end

function XBuffScript1025611:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

return XBuffScript1025611
