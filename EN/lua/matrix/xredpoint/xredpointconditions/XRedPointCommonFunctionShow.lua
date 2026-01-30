local XRedPointCommonFunctionShow = {}

function XRedPointCommonFunctionShow.Check(arg)
    local functionShowId = nil
    local type = nil

    if XTool.GetTableCount(arg) < 2 then
        XLog.Error('通用功能开启蓝点参数错误')
        return false
    end
    
    functionShowId = arg[1]
    type = arg[2]

    if not XTool.IsNumberValidEx(functionShowId) then
        XLog.Error('通用功能开启蓝点，Id参数错误:' .. tostring(functionShowId))
        return false
    end

    if not XTool.IsNumberValidEx(type) then
        XLog.Error('通用功能开启蓝点，红点类型参数错误:' .. tostring(type))
        return false
    end

    if XFunctionManager.CheckUiNodeIsShowByFunctionShowId(functionShowId) and XFunctionManager.CheckUiNodeIsUnlockByFunctionShowId(functionShowId) then
        return XPlayer.CheckIsReddotShow(functionShowId, type)
    end
end


return XRedPointCommonFunctionShow