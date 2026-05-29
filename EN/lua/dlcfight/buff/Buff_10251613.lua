local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251613 : XTheatre6SkillBase
local XBuffScript10251613 = XDlcScriptManager.RegBuffScript(10251613, "XBuffScript10251613", XTheatre6SkillBase)
---累计受到5次技能时触发：造成300%攻击伤害；
---【超算】属性在本场战斗中提升30/60/100点；
---【攻击】属性在本场战斗中提升20点；

function XBuffScript10251613:ScriptInit(isGainControl) --初始化
    ---受到攻击计数
    self.hitCount = 0
    self.targetHitCount = 5
    if self._skillId == 10252131 then self.addOverClock = 30
    else if self._skillId == 10252132 then self.addOverClock = 60
    else self.addOverClock = 100
    end
    end
    self._addAttack = 20
    --self:LogError("目标插入式技能13注册完成")
end

function XBuffScript10251613:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcDamage, self._npcUUID)
end

function XBuffScript10251613:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID == self._npcUUID then return end
    self.hitCount = self.hitCount + 1
    if self.hitCount >= self.targetHitCount then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self.hitCount = 0
    end
end


function XBuffScript10251613:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self:AddTheatre6Attrib(ETheatre6AttribType.OverClock, self.addOverClock, self._enemyUUID, self._npcUUID)
    self:AddAttrib(ENpcAttrib.Attack, self._addAttack, self._npcUUID, self._npcUUID)
    --self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -self._staminaDamage,0)
end

return XBuffScript10251613
