--- 肉鸽6 总蓝点，用于外部入口显示
local XRedPointTheatre6Main = {}

local SubCondition = nil

function XRedPointTheatre6Main.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_THEATRE6_REWARD,
    }
    return SubCondition
end

function XRedPointTheatre6Main.Check()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre6, true, true) then
        return false
    end

    local conditions = XRedPointTheatre6Main.GetSubConditions()
    if not XTool.IsTableEmpty(conditions) then
        if XRedPointManager.CheckConditions(conditions) then
            return true
        end
    end
    return false
end

return XRedPointTheatre6Main
