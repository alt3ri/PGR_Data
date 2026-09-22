local XRedPointTransfiniteTowerTask = {}

local Events = nil
function XRedPointTransfiniteTowerTask.GetSubEvents()
    Events = Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
        }
    return Events
end

---超限启航有任务奖励待领取
function XRedPointTransfiniteTowerTask.Check()
    return XMVCA.XTransfiniteTower:HasTaskRewardCanGet()
end

return XRedPointTransfiniteTowerTask
