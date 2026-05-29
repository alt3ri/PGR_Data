local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10255100 : XTheatre6SkillBase
local XBuffScript10255100 = XDlcScriptManager.RegBuffScript(10255100, "XBuffScript10255100", XTheatre6SkillBase)

--效果说明：
--· 扣除对手10点【体力值】。

function XBuffScript10255100:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.TLCost = 10
end

function XBuffScript10255100:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.TLCost, 0) --扣除对手10体力
end


return XBuffScript10255100
