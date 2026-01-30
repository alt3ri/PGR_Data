local Base = require("Skill/Common/XSkillBase")

---@class XSkillDodge : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillDodge = XDlcScriptManager.RegSkillScript(6, "XSkillDodge", Base)

function XSkillDodge:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillDodge"
end

function XSkillDodge:Update(dt)
    Base.Update(self, dt)
end

---@desc 获取下一连段ActionId
function XSkillDodge:GetDodgeActionId()
    local joystickValue = self._proxy:GetMoveNormalizedDist()
    if (joystickValue > 0) then
        return self.Template.ActionList1[1]
    elseif #self.Template.ActionList1 > 1 then
        return self.Template.ActionList1[2]
    end
    return 0
end

function XSkillDodge:TryCastStartAction(eventArgs)
    local nextAction = self:GetDodgeActionId()
    if nextAction == 0 then
        return
    end
    if not self:CheckCastCondition(nextAction) then
        return false
    end
    return self:CastActionBySearchEnemy(nextAction)
end

function XSkillDodge:Exec()
    for _, actionId in ipairs(self.Template.ActionList1) do
        if self:CheckCastCondition(actionId) then
            self:CastActionToOldTarget(actionId)
        end
    end
end

return XSkillDodge
