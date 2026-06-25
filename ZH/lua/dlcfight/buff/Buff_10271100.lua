local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271100 : XTheatre6SkillBase
local XBuffScript10271100 = XDlcScriptManager.RegBuffScript(10271100, "XBuffScript10271100", XTheatre6SkillBase)

--效果说明：· 每有50点【拼刀】属性，获得1点【耀斑值】 。
--· 获得1层<心眼>。

function XBuffScript10271100:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.StackBuff = 1027101 --耀斑buffid
    self.SunPerWrestle = 50 --每x点拼刀转1点耀斑
    self.StackBuffCount = 1
    self._stackCount = 1
    self._critController = self:GetNpc():GetCritController()
    self._sunController = self:GetNpc():GetSunController()
end

function XBuffScript10271100:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local SunRecover = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) // self.SunPerWrestle
    --self:LogError(".....播报下sun值恢复"..SunRecover)
    self._sunController:CastStackBuff(SunRecover, self._npcUUID) --我草，居然只能输入整数，如果不用整除的话这里会直接报错
end

function XBuffScript10271100:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript10271100