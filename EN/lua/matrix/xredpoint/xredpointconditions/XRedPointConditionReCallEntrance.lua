-- 拉人活动入口红点检测
local XRedPointConditionReCallEntrance = {}

---@type XRedPointEventElement[]
local Events = nil
---@type table @XRedPointConditions.Types
local SubCondition = nil

function XRedPointConditionReCallEntrance.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_RECALL_TASK_UPDATE),
    }
    return Events
end

function XRedPointConditionReCallEntrance.GetSubConditions()
    return SubCondition
end

function XRedPointConditionReCallEntrance.Check()
    local result = 0
    if XMVCA.XReCallActivity:CheckIsFirstOpen() then
        result = result + 1
    end
    if XMVCA.XReCallActivity:CheckHasReward() then
        result = result + 1
    end
    if XMVCA.XReCallActivity:CheckCanInvite() then
        result = result + 1
    end
    
    -- 如果是回归玩家，需要检查回归专属页签
    if XMVCA.XReCallActivity:CheckIsRegressionPlayer() then
        if not XMVCA.XReCallActivity:GetBackOnlyTagIsMark() then
            result = result + 1
        end
    end
    
    return result
end

return XRedPointConditionReCallEntrance