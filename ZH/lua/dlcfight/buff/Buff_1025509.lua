local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025509 : XTheatre6BuffBase
local XBuffScript1025509 = XDlcScriptManager.RegBuffScript(1025509, "XBuffScript1025509", XTheatre6BuffBase)

--效果说明：每次【耀斑值】满时，恢复10点【体力值】。

function XBuffScript1025509:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.StaminaRecover = 10
    self.ChanceCheck = 0
    self.BuffId = 1027101 --耀斑buffid
    self._sunController = self:GetNpc():GetSunController()
    --self:LogError(".....回体力初始化")
    ------------执行------------
end

function XBuffScript1025509:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1025509:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) -- 获得buff时刷新增伤
    if buffId == self.BuffId then
        if npcUUID == self._npcUUID then
            local count = self._proxy:GetBuffStacks(self._npcUUID,self.BuffId)
            --self:LogError(".....给了耀斑"..count)
            if self._proxy:GetBuffStacks(self._npcUUID,self.BuffId) == 120 then

                if self.ChanceCheck == 0 then
                    self.ChanceCheck = 1
                    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,self.StaminaRecover,0)
                    --self:LogError(".....回体力")
                end
            end
        end
    end
end

function XBuffScript1025509:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:GetBuffCountByKind(self._npcUUID,self.BuffId) < 120 then -- 避免一些特定情况下场上放了多个技能但玩家的耀斑值没有被扣掉
        self.ChanceCheck = 0
    end
end

return XBuffScript1025509