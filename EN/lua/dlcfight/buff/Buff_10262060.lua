local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262060 : XTheatre6SkillBase
local XBuffScript10262060 = XDlcScriptManager.RegBuffScript(10262060, "XBuffScript10262060", XTheatre6SkillBase)

--效果说明：自身处于【狂暴】期间，每使用3个任意技能触发：
--· 造成150%攻击伤害；
--· 消耗30点【怒火】；
--· 自身每有1点【拼刀】属性，恢复1点【体力值】；

function XBuffScript10262060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._damageMagicId = 10250044 --注册超算成功技1伤害id，目前是临时的
    self.attackCount = 0
    self.targetCount = 3
    self._angerCost = 30
    self.StackBuffAnger = 1025107
    self.StackBuffAngry = 1025108
end

function XBuffScript10262060:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end

function XBuffScript10262060:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,self.StackBuffAngry)
    if self.originAttrib1 >= 1 then
        self.attackCount = self.attackCount + 1
        if self.attackCount >= self.targetCount then
            self.attackCount = 0
            self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
        end
    end
    if eventArgs._skillId ~= self._skillId then return end
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuffAnger, self._angerCost)
    self.TLRecover = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复5体力
end

return XBuffScript10262060

--无法获取到击飞事件