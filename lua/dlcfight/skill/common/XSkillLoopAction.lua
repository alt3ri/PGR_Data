local Base = require("Skill/Common/XSkillBase")

---@class XSkillLoopAction : XSkillBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillLoopAction = XDlcScriptManager.RegSkillScript(8, "XSkillLoopAction", Base)

local LoopActionState = 
{
    None = 0,
    Start = 1,
    Looping = 2,
}

function XSkillLoopAction:Init() --初始化
    Base.Init(self)
    self.ScriptName = "XSkillLoopAction"
    self.CurrntState = LoopActionState.None; --当前循环状态
end


function XSkillLoopAction:Update(dt)
    Base.Update(self, dt)
    --检查当前状态释放的Action有没有被打断
    if self.CurrntState == LoopActionState.Start or self.CurrntState == LoopActionState.Looping then
        --当前释放的动作并非该技能释放的
        local curSkillId = self._proxy:TryGetCurrentActionSubscribeSkill(self._uuid);
        if not curSkillId == self.SkillId then
            self.CurrntState = LoopActionState.None;
        end
    end
end

function XSkillLoopAction:TryCastStartAction(CastContext)
    local nextAction = self:GetStartAction()
    if (nextAction == nil) then
        return false
    end
    if not self:CheckCastCondition(nextAction) then
        return false
    end
    local result = self:CastActionBySearchEnemy(nextAction)
    if (result == true) then
        self.CurrntState = LoopActionState.Start; --当前循环状态
    end
    return result
end

function XSkillLoopAction:TryLoopEndAction(CastContext)
    local nextAction, timingId = self:GetLoopAction()
    if (nextAction == nil) then
        return false
    end
    if not self:CheckCastCondition(nextAction, timingId) then
        return false
    end
    local result = self:CastActionBySearchEnemy(nextAction)
    if (result == true) then
        self.CurrntState = LoopActionState.Looping; --当前循环状态
    end
    return result
end

function XSkillLoopAction:TryCastEndAction(CastContext)
    local nextAction = self:GetEndAction()
    if (nextAction == nil) then
        return false
    end
    if not self:CheckCastCondition(nextAction) then
        return false
    end
    local result = self:CastActionBySearchEnemy(nextAction)
    if (result == true) then
        self.CurrntState = LoopActionState.None; --当前循环状态
    end
    return result
end


function XSkillLoopAction:GetStartAction()
    local ListLength = #self.Template.ActionList1
    if ListLength == 0 then
        return nil
    end
    if not self.CurrntState == LoopActionState.None then
        return nil
    end
    return self.Template.ActionList1[1]
end

function XSkillLoopAction:GetLoopAction()
    local ListLength = #self.Template.ActionList2
    if ListLength == 0 then
        return nil
    end
    if self.CurrntState == LoopActionState.Start then
        return self.Template.ActionList2[1], 14
    elseif self.CurrntState == LoopActionState.Looping then
        return self.Template.ActionList2[1], 14
    end
    return nil
end

function XSkillLoopAction:GetEndAction()
    local ListLength = #self.Template.ActionList3
    if ListLength == 0 then
        return nil
    end
    if self.CurrntState == LoopActionState.None then
        return nil
    end
    return self.Template.ActionList3[1], 14
end


return XSkillLoopAction
