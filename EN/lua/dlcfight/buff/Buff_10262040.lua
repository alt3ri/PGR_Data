local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262040 : XTheatre6SkillBase
local XBuffScript10262040 = XDlcScriptManager.RegBuffScript(10262040, "XBuffScript10262040", XTheatre6SkillBase)

--效果说明：每次【狂暴】结束时触发：
--· 造成80%攻击伤害；
--· 获得30点【怒火】；
--· 恢复自身30点【体力值】；

function XBuffScript10262040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._damageMagicId = 10250044 --注册超算成功技1伤害id，目前是临时的
    self._angerRecover = 10
    self.TLRecover = 5
end

function XBuffScript10262040:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end


function XBuffScript10262040:OnNpcAddBuffEvent(eventArgs)
    if eventArgs.BuffId ~= 1026102 then return end
    self._level:RequestInsertSkill(self._uuid,self.TargetSkill)
end

function XBuffScript10262040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._AngerController:CastStackBuff(self._angerRecover, self._npcUUID)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复5体力
end

return XBuffScript10262040

--无法获取到击飞事件