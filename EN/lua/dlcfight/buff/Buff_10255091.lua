local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript10255091 : XTheatre6BuffBase
local XBuffScript10255091 = XDlcScriptManager.RegBuffScript(10255091, "XBuffScript10255091", XTheatre6BuffBase)

--效果说明：使用技能后，返还消耗体力的20%。技能结束时销毁此buff

function XBuffScript10255091:ScriptInit(isGainControl) --初始化
    --self.TargetSkill = self._skillId
    self.BuffId = 10255091        --25%加伤buff
end

function XBuffScript10255091:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local cfg = self._proxy:Theatre6GetSkillConfig(eventArgs._skillId)
    --self:LogError("体力恢复"..eventArgs._skillId)
    local tlCost = cfg.CostTL
    self.TLRecover = tlCost // 5 --体力恢复=体力消耗的1/5
    --self:LogError("体力恢复"..self.TLRecover)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复5体力
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 1)
end

return XBuffScript10255091
