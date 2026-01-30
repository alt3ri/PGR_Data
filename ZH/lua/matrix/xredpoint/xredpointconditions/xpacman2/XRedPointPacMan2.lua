local XRedPointPacMan2 = {}

function XRedPointPacMan2.Check()
    --“蓝点规则 当关卡中存在未首通的关卡时,入口处出现蓝点,进入玩法主界面后消失,直到次日判断依然有未通关的关卡时出现”

    -- 判断是否有未通关的关卡
    if not XMVCA.XPacMan2:HasStageNotPassedAndCanChallenge() then
        --XLog.Warning("没有未通关的可挑战关卡")
        return false
    end

    local isRed = false
    local nextTime = XTime.GetSeverTomorrowFreshTime()
    local time = XSaveTool.GetData("PacMan2" .. XPlayer.Id)
    -- 第一次, 总是显示红点
    if not time then
        --XLog.Warning("第一次, 总是显示红点")
        isRed = true

        -- 这一天已经用过了
    elseif time == nextTime then
        --XLog.Warning("这一天已经用过了")
        isRed = false

        -- 这一天还没显示过
    else
        --XLog.Warning("这一天还没显示过")
        isRed = true
    end

    return isRed
end

function XRedPointPacMan2.ClearTodayRed()
    local nextTime = XTime.GetSeverTomorrowFreshTime()
    XSaveTool.SaveData("PacMan2" .. XPlayer.Id, nextTime)
end

return XRedPointPacMan2