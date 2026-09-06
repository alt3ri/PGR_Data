local XRedPointPunishaarTask = {}

function XRedPointPunishaarTask.GetSubEvents()
    return {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
end

function XRedPointPunishaarTask.Check(index)
    if not XMVCA.XPunishaar:GetIsActivityOpen(false) then
        return false
    end

    return XMVCA.XPunishaar:CheckTaskRedPoint(index)
end

return XRedPointPunishaarTask