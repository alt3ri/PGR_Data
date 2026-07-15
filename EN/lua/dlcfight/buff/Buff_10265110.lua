local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265110 : XTheatre6SkillBase
local XBuffScript10265110 = XDlcScriptManager.RegBuffScript(10265110, "XBuffScript10265110", XTheatre6SkillBase)

--效果说明：
--· 获得10点【超算值】。

function XBuffScript10265110:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.CSRecover = 10
end

function XBuffScript10265110:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6AddNpcRuntimeOverClock(self._npcUUID,self.CSRecover)
end


return XBuffScript10265110
