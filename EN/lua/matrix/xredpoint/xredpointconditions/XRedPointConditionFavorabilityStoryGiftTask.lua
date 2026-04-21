----------------------------------------------------------------
--好感剧情限时送角色任务红点检测
--遍历CharaceterStoryActivity表，检查TaskTimeLimitId对应的任务是否达成
local XRedPointConditionFavorabilityStoryGiftTask = {}

function XRedPointConditionFavorabilityStoryGiftTask.GetSubEvents()
    return
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
end

function XRedPointConditionFavorabilityStoryGiftTask.Check(checkArgs)
    -- 不需要任何传参，直接检查是否有任意角色的任务达成
    return XMVCA.XFavorability:CheckStoryGiftTaskRedPoint()
end

return XRedPointConditionFavorabilityStoryGiftTask
