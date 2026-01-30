local XRedPointConditionKoroCharActivity2 = {}
local SubCondition = nil
function XRedPointConditionKoroCharActivity2.GetSubConditions()
    SubCondition = SubCondition or
    {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
        XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK,
    }
    return SubCondition
end

function XRedPointConditionKoroCharActivity2.Check()
    local ids = CS.XGame.ClientConfig:GetString("TeachActIds")
    local id
    if ids then
        ids = string.Split(ids, "-")
        if ids[2] then
            id = tonumber(ids[2])
        end
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NewCharAct) then
        return false
    end

    if not XDataCenter.FubenNewCharActivityManager.IsOpen() then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,id) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,id) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK,id) then
        return true
    end

    return false
end

return XRedPointConditionKoroCharActivity2