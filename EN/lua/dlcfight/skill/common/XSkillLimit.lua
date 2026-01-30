local Base = require("Skill/Common/XSkillBase")

---@class XSkillLimit : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillLimit = XDlcScriptManager.RegSkillScript(7, "XSkillLimit", Base)

function XSkillLimit:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillLimit"
    self.LimitCast = self.Template.CustomParamList[1] or 1 --消耗极限值 默认1
    self._proxy:RegisterEvent(EWorldEvent.NpcTeamWorkSkillCast)
end

function XSkillLimit:TryCastStartAction()
    self._proxy:CastTeamWorkEnergy(self.LimitCast)--消耗能量
end

function XSkillLimit:OnNpcTeamWorkSkillCast(sourceUUID, camp, skillId, chainCount)
    Base.OnNpcTeamWorkSkillCast(sourceUUID, camp, skillId, chainCount)
    if skillId == self.SkillId then
        return
    end
    local limitAction = self.Template.ActionList1[1]
    if (limitAction == nil) then
        return false
    end
    if not self:CheckCastCondition(limitAction) then
        return false
    end
    return self:CastActionBySearchEnemy(limitAction)
end

return XSkillLimit
