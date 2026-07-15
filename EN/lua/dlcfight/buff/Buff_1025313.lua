local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025313 : XTheatre6BuffBase
local XBuffScript1025313 = XDlcScriptManager.RegBuffScript(1025313, "XBuffScript1025313", XTheatre6BuffBase)

--效果说明： 自身【生命值】首次降低至【生命】属性的50%时，恢复10点【战意值】，自身在本场战斗中每造成过1次【击飞】，额外恢复5点【战意值】

function XBuffScript1025313:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025103
    --公用的击飞id
    self.originAttrib3 = 0 --击飞计数器
    self.StaminaPerHitFly = 5 --每次击飞给的体力值
    self.originAttrib4 = 10 --基础体力值
    self.ChanceCheck = 0 --唯一次数限制
    self.Check = 0
    ------------执行------------
end

function XBuffScript1025313:InitEventCallBackRegister()  --监听受伤时事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1025313:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --每帧执行
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.Life)*2
    self.originAttrib2 = self._proxy:GetNpcAttribMaxValue(self._npcUUID,ENpcAttrib.Life)
    if self.originAttrib1 <= self.originAttrib2 then
        if self.ChanceCheck == 0 then
            self.originAttrib4 = self.originAttrib4 + self.originAttrib3 * self.StaminaPerHitFly
            self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.originAttrib4, 0) --根据基础属性和击飞次数恢复体力
            self.ChanceCheck = 1
        end
    end
end

function XBuffScript1025313:OnLuaAffixHitFly(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.Check == 1 then return end
    self.originAttrib3 = self.originAttrib3 + 1
    self.Check = 1
end

function XBuffScript1025313:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.Check = 0
end

return XBuffScript1025313

    