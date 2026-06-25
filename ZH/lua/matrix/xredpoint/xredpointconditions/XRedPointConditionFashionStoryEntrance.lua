local XRedPointConditionFashionStoryEntrance={}

function XRedPointConditionFashionStoryEntrance.GetSubConditions()
    return {
        XRedPointConditions.Types.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK,
        XRedPointConditions.Types.CONDITION_FASHION_STORY_TASK,
        XRedPointConditions.Types.CONDITION_FASHION_STORY_REWARD,
    }
end

function XRedPointConditionFashionStoryEntrance.Check()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FashionStory, false, true) then
        return false
    end

    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FASHION_STORY_TASK)
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK)
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FASHION_STORY_REWARD)
end

return XRedPointConditionFashionStoryEntrance