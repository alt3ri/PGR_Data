local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262060 : XTheatre6SkillBase
local XBuffScript10262060 = XDlcScriptManager.RegBuffScript(10262060, "XBuffScript10262060", XTheatre6SkillBase)

--效果说明：自身处于【狂暴】期间，每使用4个任意技能触发：
--· 造成150%攻击伤害；
--· 消耗50点【怒火】；
--· 自身每有X点【拼刀】属性，恢复1点【体力值】；

function XBuffScript10262060:ScriptInit(isGainControl) --初始化
    self.attackCount = 0
    self.targetCount = 4
    self._angerCost = 50
    self.StackBuffAnger = 1025107
    self.StackBuffAngry = 1025108
    self.dictTLRecoverRate = {
        [1] = 40,
        [2] = 30,
        [3] = 20
    }
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
    self.TLRecover = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) // self.dictTLRecoverRate[self._lv]
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复5体力
end

return XBuffScript10262060

--无法获取到击飞事件