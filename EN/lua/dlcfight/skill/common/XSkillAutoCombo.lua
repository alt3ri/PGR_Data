local Base = require("Skill/Common/XSkillBase")

---@class XSkillAutoCombo : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillAutoCombo = XDlcScriptManager.RegSkillScript(9, "XSkillAutoCombo", Base)

function XSkillAutoCombo:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillAutoCombo"
end


function XSkillAutoCombo:Update(dt)
    Base.Update(self, dt)
    local nextAction = self:GetComboActionId()
    if nextAction == nil then
        return
    end
    self:TryCastAction(nextAction)
end

---@desc 获取下一连段ActionId
---@desc 获取下一连段ActionId和TimingId
function XSkillAutoCombo:GetComboActionId()
    local ListLength = #self.Template.ActionList1
    if ListLength <= 1 then
        return nil
    end

    local hasCurAction,curActionId,_ = self._proxy:TryGetCurrentAction(self._uuid)
    --当前没有在释放的技能
    if not hasCurAction then
        return nil
    end

    --当前释放的技能并非连段中
    local curSkillId = self._proxy:TryGetCurrentActionSubscribeSkill(self._uuid);
    if not curSkillId == self.SkillId then
        return nil
    end

    --获取连段中下一技能
    for i = 1, ListLength - 1 do
        if self.Template.ActionList1[i] == curActionId then
            return self.Template.ActionList1[i+1] , 14
        end
    end
    return nil
end

---@desc尝试释放第一段Action
function XSkillAutoCombo:TryCastStartAction()
    local ListLength = #self.Template.ActionList1
    if ListLength == 0 then
        return false
    end
    return self:TryCastAction(self.Template.ActionList1[1], 0)
end

function XSkillAutoCombo:TryCastAction(actionId, timingId)
    if not self:CheckCastCondition(actionId, timingId) then
        return false
    end
    return self:CastActionBySearchEnemy(actionId)
end

return XSkillAutoCombo
