local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271090 : XTheatre6SkillBase
local XBuffScript10271090 = XDlcScriptManager.RegBuffScript(10271090, "XBuffScript10271090", XTheatre6SkillBase)

--效果说明：· 扣除双方20点【体力值】。
--· 每有100点【拼刀】或【超算】属性，获得200点【护盾】。

function XBuffScript10271090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.staminaChange = -20                           --体力扣除量
    self.StackBuff = 1027109 --给护盾Buff，现在这条效果有点太耗性能了
    self.BuffPerAttrib = 100
    self.Protector = self:GetNpc():GetProtectorController()
end

function XBuffScript10271090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, self.staminaChange, 0)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.staminaChange, 0)
    local originAttrib1 = ( self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) + self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock) ) / self.BuffPerAttrib--取一下玩家的拼刀和超算属性
    --self:LogError(".....播报下属性"..originAttrib1)
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.StackBuff,0,0,originAttrib1) --发对应层数的护盾buff
end

return XBuffScript10271090