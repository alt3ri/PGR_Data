local Base = require("Skill/Common/XSkillBase")

---@class XSkillSingleAction : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillSingleAction = XDlcScriptManager.RegSkillScript(2, "XSkillSingleAction", Base)

function XSkillSingleAction:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillSingleAction"
end


function XSkillSingleAction:Update(dt)
    Base.Update(self, dt)
end


function XSkillSingleAction:TryCastStartAction()
    local nextAction = self.Template.ActionList1[1]
    if (nextAction == nil) then
        return false
    end
    if not self:CheckCastCondition(nextAction) then
        return false
    end
    return self:CastActionBySearchEnemy(nextAction)
end




return XSkillSingleAction
