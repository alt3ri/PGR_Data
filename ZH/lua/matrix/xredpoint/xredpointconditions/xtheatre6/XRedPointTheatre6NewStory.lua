-- 肉鸽6新剧情红点
local XRedPointTheatre6NewStory = {}

function XRedPointTheatre6NewStory.Check()
    --新剧情开始时间小于等于当前时间，并且没有看过
    local lastTime = XMVCA.XTheatre6:GetLastViewStoryTime()
    local newestTime = XMVCA.XTheatre6:GetLatestStoryUpdateTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if newestTime and nowTime >= newestTime and lastTime < newestTime then
        return 1
    else
        return 0
    end
end

return XRedPointTheatre6NewStory