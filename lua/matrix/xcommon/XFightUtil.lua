XFightUtil = {}
local XFightUtil = XFightUtil

function XFightUtil.ClearFight()
    if CS.XFight.Instance ~= nil then
        CS.XFight.ClearFight()
    end
    if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
        CS.StatusSyncFight.XFightClient.ExitFight(true, true)
        --XMVCA.XBigWorldGamePlay:OnExitFight()
    end
end

function XFightUtil.IsFighting()
    return CS.XFight.Instance ~= nil or XFightUtil.IsDlcFighting()
end

function XFightUtil.IsDlcFighting()
    return CS.StatusSyncFight.XFightClient.FightInstance ~= nil
end

function XFightUtil.IsDlcOnline()
    if not CS.StatusSyncFight.XFightClient.FightInstance then
        return false
    end
    return CS.StatusSyncFight.XFightClient.FightInstance.IsOnline
end

function XFightUtil.GetDlcWorldId()
    if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
        return CS.StatusSyncFight.XFightClient.FightInstance:GetWorldId()
    end
    return 0
end

function XFightUtil.SetCameraOpEnabled(isEnabled)
    if CS.StatusSyncFight.XFightClient.FightInstance ~= nil and CS.StatusSyncFight.XFightClient.FightInstance.InputManager ~= nil then
        CS.StatusSyncFight.XFightClient.FightInstance.InputManager:SetCameraOpEnabled(isEnabled)
    end
end

return XFightUtil