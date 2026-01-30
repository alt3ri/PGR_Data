--- 3.5 鬼泣联动角色试玩活动总蓝点
local XRedPointConditionDMCCharActivity = {}

local ActivityIds = nil

function XRedPointConditionDMCCharActivity.Check()
    if ActivityIds == nil or XMain.IsEditorDebug then
        ActivityIds = {}
        ActivityIds[1] = XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 1)
        ActivityIds[2] = XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 2)
    end

    if not XTool.IsTableEmpty(ActivityIds) then
        for i, v in pairs(ActivityIds) do
            --- 教学关蓝点
            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED, v) then
                return true
            end

            --- 任务蓝点
            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK, v) then
                return true
            end
        end
        

    end

    return false
end


return XRedPointConditionDMCCharActivity
