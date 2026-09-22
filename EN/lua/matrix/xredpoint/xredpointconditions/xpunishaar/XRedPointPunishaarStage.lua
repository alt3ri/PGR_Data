local XRedPointPunishaarStage = {}

function XRedPointPunishaarStage.Check(stageId)
    if not XMVCA.XPunishaar:GetIsActivityOpen(false) then
        return false
    end

    -- 选关页面：检查指定关卡
    if XTool.IsNumberValid(stageId) then
        return XMVCA.XPunishaar:CheckStageShowRedPoint(stageId)
    end

    -- 主界面、外层入口：检查任意关卡
    return XMVCA.XPunishaar:CheckAnyStageShowRedPoint()
end

return XRedPointPunishaarStage