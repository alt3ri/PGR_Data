-- 肉鸽6新剧情红点
local XRedPointTheatre6NewStory = {}

function XRedPointTheatre6NewStory.Check()
    local lastTime = XMVCA.XTheatre6:GetLastViewStoryTime()
    local newestTime = XMVCA.XTheatre6:GetLatestStoryUpdateTime()
    if lastTime <= newestTime then
        return 1
    else
        return 0
    end
end

return XRedPointTheatre6NewStory