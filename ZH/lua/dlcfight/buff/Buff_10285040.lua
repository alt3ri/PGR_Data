local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10285040 : XTheatre6SkillBase
local XBuffScript10285040 = XDlcScriptManager.RegBuffScript(10285040, "XBuffScript10285040", XTheatre6SkillBase)

--效果说明：
--· 获得1点【魅惑】。

function XBuffScript10285040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self._hypnoController = self:GetNpc():GetHypnoController()
end

function XBuffScript10285040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hypnoController:CastStackBuff(1,self._npcUUID)
end


return XBuffScript10285040
