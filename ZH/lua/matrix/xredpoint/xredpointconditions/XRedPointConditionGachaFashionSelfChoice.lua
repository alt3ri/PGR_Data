local XRedPointConditionGachaFashionSelfChoice = {}

function XRedPointConditionGachaFashionSelfChoice.Check(groupId)
    local activityId = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityId()
    if not XTool.IsNumberValid(activityId) then
        return false
    end

    if not XTool.IsNumberValid(groupId) then
        return false
    end

    local curGachaId = XDataCenter.GachaManager.GetCurSelfChoiceSelectGachId(groupId)
    if XTool.IsNumberValid(curGachaId) then -- 该Group已经选择了就不需要蓝点了
        return false
    end

    local saveKey = "OpenUiGachaFashionSelfChoiceEntrance_" .. tostring(groupId)
    local data = XSaveTool.GetData(saveKey)
    if not data then
        return true
    end

    if data.NextCanShowTimeStamp and XTime.GetServerNowTimestamp() > data.NextCanShowTimeStamp then
        return true
    end

    return false
end

return XRedPointConditionGachaFashionSelfChoice
