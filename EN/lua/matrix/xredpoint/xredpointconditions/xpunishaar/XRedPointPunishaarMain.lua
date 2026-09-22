local XRedPointPunishaarMain = {}

local SubConditions = {
    XRedPointConditions.Types.CONDITION_PUNISHAAR_STAGE,
    XRedPointConditions.Types.CONDITION_PUNISHAAR_TASK,
    XRedPointConditions.Types.CONDITION_PUNISHAAR_COLLECTION,
}

function XRedPointPunishaarMain.GetSubConditions()
    return SubConditions
end

function XRedPointPunishaarMain.Check()
    if not XMVCA.XPunishaar:GetIsActivityOpen(false) then
        return false
    end

    return XRedPointManager.CheckConditions(SubConditions)
end

return XRedPointPunishaarMain