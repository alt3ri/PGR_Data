--- 肉鸽5总蓝点，用于外部入口显示
local XRedPointTheatre5Main = {}

local SubCondition = nil

function XRedPointTheatre5Main.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_THEATRE5_NEW_ACTIVITY,
        XRedPointConditions.Types.CONDITION_THEATRE5_PVP_NEW_ACTIVITY,
        XRedPointConditions.Types.CONDITION_THEATRE5_LIMIT_SHOP,
        XRedPointConditions.Types.CONDITION_THEATRE5_TASK,
    }

    return SubCondition
end

function XRedPointTheatre5Main.Check()
    -- 先判断活动是否开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end
    
    local conditions = XRedPointTheatre5Main.GetSubConditions()

    if not XTool.IsTableEmpty(conditions) then
        if XRedPointManager.CheckConditions(conditions) then
            return true
        end
    end
    return false
end

return XRedPointTheatre5Main