
local XRedPointConditionPassportComb = {}
local SubConditions = nil

local Events = nil

function XRedPointConditionPassportComb.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST),
    }
    return Events
end

function XRedPointConditionPassportComb.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_PASSPORT_COMB_PANEL_REWARD_RED,
        XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_DAILY_RED,
        XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_WEEKLY_RED,
        XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_ACTIVITY_RED,
    }
    return SubConditions
end

function XRedPointConditionPassportComb.Check()
    if XMVCA.XPassportComb:IsActivityClose() then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_PASSPORT_COMB_PANEL_REWARD_RED) then
        return true
    end

    --满级时入口不检查任务的红点
    local baseInfo = XMVCA.XPassportComb:GetPassportBaseInfo()
    local level = baseInfo:GetLevel()
    local maxLevel = XMVCA.XPassportComb:GetPassportMaxLevel()
    if level < maxLevel then
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_DAILY_RED) then
            return true
        end

        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_WEEKLY_RED) then
            return true
        end

        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_PASSPORT_COMB_TASK_ACTIVITY_RED) then
            return true
        end
    end

    return false
end

return XRedPointConditionPassportComb