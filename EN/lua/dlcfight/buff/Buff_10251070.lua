local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251070 : XTheatre6SkillBase
local XBuffScript10251070 = XDlcScriptManager.RegBuffScript(10251070, "XBuffScript10251070", XTheatre6SkillBase)

--效果说明：【超算】属性>500点时，额外扣除对手15点【体力值】。

function XBuffScript10251070:ScriptInit(isGainControl) --初始化
    --self:LogError(".....初始化完成")
end

function XBuffScript10251070:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.OverClock)
    --self:LogError(".....抓到超算属性"..self.originAttrib1)
    if self.originAttrib1 > 500 then
        self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -15, 0)
    end
end

return XBuffScript10251070

--调试打印不要提交到线上    ：已注释
--TargetSkill和ChanceCheck是冗余的    ：已删