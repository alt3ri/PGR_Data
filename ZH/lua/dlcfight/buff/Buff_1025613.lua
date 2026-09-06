local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025613 : XTheatre6BuffBase
local XBuffScript1025613 = XDlcScriptManager.RegBuffScript(1025613, "XBuffScript1025613", XTheatre6BuffBase)

--效果说明：任意一方的【生命值】首次低于50%时，我方获得2点【魅惑】

function XBuffScript1025613:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self._hypnoController = self:GetNpc():GetHypnoController()
    ------------执行------------
    self.ChanceCheckSelf = 0
    self.ChanceCheckEnemy = 0
end

function XBuffScript1025613:InitEventCallBackRegister()  --监听受伤时事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1025613:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage,
                                             elementType, realDamage, isCritical, skillActionId, magicTags, customValue)
    if targetId == self._npcUUID then
        local curHealth = self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Life)
        local maxHealth = self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life)
        if curHealth * 2 < maxHealth then
            if     self.ChanceCheckSelf == 0 then
                self._hypnoController:CastStackBuff(2, self._npcUUID)
                self.ChanceCheckSelf = 1
            end
        end
    end
    if targetId ~= self._npcUUID then
        local curHealth = self._proxy:GetNpcAttribValue(self._enemyUUID, ENpcAttrib.Life)
        local maxHealth = self._proxy:GetNpcAttribMaxValue(self._enemyUUID, ENpcAttrib.Life)
        if curHealth * 2 < maxHealth then
            if     self.ChanceCheckEnemy == 0 then
                self._hypnoController:CastStackBuff(2, self._npcUUID)
                self.ChanceCheckEnemy = 1
            end
        end
    end
end


return XBuffScript1025613
