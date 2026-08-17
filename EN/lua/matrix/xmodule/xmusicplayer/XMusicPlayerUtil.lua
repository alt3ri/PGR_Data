---@class XMusicPlayerUtil 静态工具类  
local XMusicPlayerUtil =  {}


---@param musicId number
function XMusicPlayerUtil.GetMusicUseStatus(musicId)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum 

    local co = XMVCA.XMusicPlayer:COGetMusicPlayerAlbumCOByid(musicId)
    if not co then
        return XMusicPlayerEnum.MusicUseStatus.unlock
    end

    if not co.ConditionId or co.ConditionId == 0 then
        return XMusicPlayerEnum.MusicUseStatus.gain
    end

    if  XConditionManager.CheckCondition(co.ConditionId) then
        return XMusicPlayerEnum.MusicUseStatus.gain
    else
        if XTool.IsNumberValid(co.ExperienceTimeId) 
        and XFunctionManager.CheckInTimeByTimeId(co.ExperienceTimeId) then
            return XMusicPlayerEnum.MusicUseStatus.limitedFree
        end
    end
    return XMusicPlayerEnum.MusicUseStatus.unlock
end

function XMusicPlayerUtil.ShowUIByStatus(goDict,targetStatus)
    for _, goList in pairs(goDict) do
        for _, go in ipairs(goList) do
            go.gameObject:SetActive(false)
        end
    end

    local targetList = goDict[targetStatus]
    if targetList then
        for _, go in ipairs(targetList) do
            go.gameObject:SetActive(true)
        end
    end
end

function XMusicPlayerUtil.SetBtnStatusPro(btnInstance,status)
    btnInstance:SetButtonState(status)
    btnInstance.TempState = status
end


---@param list any[]
---@return any[]|nil
function XMusicPlayerUtil.Shuffle(list)
    if not list or #list <= 1 then
        return list
    end
    XTool.Shuffle(list)
    return list
end
 

return XMusicPlayerUtil
