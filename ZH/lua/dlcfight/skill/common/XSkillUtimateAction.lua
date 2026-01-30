local Base = require("Skill/Common/XSkillBase")

---@class XSkillUtimateAction : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillUtimateAction = XDlcScriptManager.RegSkillScript(5, "XSkillUtimateAction", Base)

function XSkillUtimateAction:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillUtimateAction"
end


function XSkillUtimateAction:Update(dt)
    Base.Update(self, dt)
end


function XSkillUtimateAction:TryCastStartAction()
    local nextAction = self.Template.ActionList1[1]
    if (nextAction == nil) then
        return false
    end
    if not self:CheckCastCondition(nextAction) then
        return false
    end
    return self:CastActionBySearchEnemy(nextAction)
end


return XSkillUtimateAction
