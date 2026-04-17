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

--- 断线重连失败后针对战斗的处理
function XFightUtil.DoOnReconnectFailed()
    if XFightUtil.IsFighting() then
        if not XFightUtil.IsDlcFighting() then
            if not XFightUtil._TryCustomOnReconnectFailExit() then
                XLuaUiManager.Open("UiSettleLose")
            end
        end
        XFightUtil.ClearFight()
    end
end

function XFightUtil._TryCustomOnReconnectFailExit()
    if CS.XFight.Instance.FightData then
        -- 获取当前关卡
        local stageId = CS.XFight.Instance.FightData.StageId

        if XTool.IsNumberValidEx(stageId) then
            local stageType = XMVCA.XFuben:GetStageType(stageId)

            -- 尝试执行玩法自定义的断线退出逻辑
            if stageType then
                local ok, result = XMVCA.XFuben:CallCustomFunc(stageType, XEnumConst.FuBen.ProcessFunc.OnReconnectFailExit)

                return ok, result
            end
        end
    end
    
    return false
end

return XFightUtil