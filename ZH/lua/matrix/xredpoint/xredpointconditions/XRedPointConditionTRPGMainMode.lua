local XRedPointConditionTRPGMainMode = {}
local SubCondition = nil

function XRedPointConditionTRPGMainMode.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_TRPG_TRUTH_ROAD_REWARD,
        XRedPointConditions.Types.CONDITION_TRPG_COLLECTION_MEMOIR,
        XRedPointConditions.Types.CONDITION_TRPG_AREA_REWARD,
        XRedPointConditions.CONDITION_TRPG_WORLD_BOSS_REWARD,
    }
    return SubCondition
end

function XRedPointConditionTRPGMainMode.Check(isFromMain)
    -- 求真之路相关不穿透到外面
    if not isFromMain then
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_TRUTH_ROAD_REWARD) then
            return true
        end
    end
    
    -- 珍藏不穿透到外面
    if not isFromMain then
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_COLLECTION_MEMOIR) then
            return true
        end
    end
    
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_AREA_REWARD) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_WORLD_BOSS_REWARD) then
        return true
    end
    return false
end

return XRedPointConditionTRPGMainMode