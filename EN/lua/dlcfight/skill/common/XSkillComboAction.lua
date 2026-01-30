local Base = require("Skill/Common/XSkillBase")

---@class XSkillComboAction : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillComboAction = XDlcScriptManager.RegSkillScript(3, "XSkillComboAction", Base)

function XSkillComboAction:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillComboAction"
end


function XSkillComboAction:Update(dt)
    Base.Update(self, dt)
end

---@desc 获取下一连段ActionId和TimingId
function XSkillComboAction:GetComboActionId()
    local ListLength = #self.Template.ActionList1
    if ListLength == 0 then
        return 0 , 0
    end
    if ListLength == 1 then
        return self.Template.ActionList1[1] , 0
    end
    
    local hasCurAction,curActionId,_ = self._proxy:TryGetCurrentAction(self._uuid)
    --当前没有在释放的技能
    if not hasCurAction then
        return self.Template.ActionList1[1] , 0
    end

    --当前释放的技能并非连段中
    local _ , curSkillId = self._proxy:TryGetCurrentActionSubscribeSkill(self._uuid);
    if not curSkillId == self.SkillId then
        return self.Template.ActionList1[1] , 0
    end
    
    --获取连段中下一技能
    for i = 1, ListLength - 1 do
        if self.Template.ActionList1[i] == curActionId then
            return self.Template.ActionList1[i+1] , 14
        end
    end
    return self.Template.ActionList1[1] , 0
end


function XSkillComboAction:TryCastStartAction()
    local nextAction, timingId = self:GetComboActionId()
    if nextAction == 0 then
        return false
    end
    if not self:CheckCastCondition(nextAction, timingId) then
        return false
    end
    return self:CastActionBySearchEnemy(nextAction)
end

return XSkillComboAction
