local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025199 : XTheatre6SkillBase
local XBuffScript1025199 = XDlcScriptManager.RegBuffScript(1025199, "XBuffScript1025199", XTheatre6SkillBase)


--效果说明：进入战斗时，损失50%生命值

function XBuffScript1025199:Init()
    --初始化
    XTheatre6SkillBase.Init(self)
    ------------配置------------
    self.magicId = 10251502
    self.startBuffId = 1025112 --正式开始战斗标记
    ------------执行------------
    self.dmgRatio = 0.75 --损失生命值比例
end

function XBuffScript1025199:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAddBuff, self._npcUUID)
end

function XBuffScript1025199:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId ~= self.startBuffId then return end
    if casterNpcUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.magicId, 1, 0, 1)
end

function XBuffScript1025199:AfterDamageCalc(eventArgs)
    if eventArgs.Id ~= self.magicId then return end

    local lifeMaxValue = self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life)
    local dmg = lifeMaxValue * self.dmgRatio
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, dmg, eventArgs.ElementDamage,
        eventArgs.FinalHackDamage)
end

return XBuffScript1025199
