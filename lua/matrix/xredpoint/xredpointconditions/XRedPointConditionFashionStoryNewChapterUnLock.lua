local XRedPointConditionFashionStoryNewChapterUnLock={}

function XRedPointConditionFashionStoryNewChapterUnLock.Check(singlelineId)
    if XTool.IsNumberValid(singlelineId) then
        --解锁&未查看过
        return XMVCA.XFashionStory:CheckGroupIsCanOpen(singlelineId) and not XMVCA.XFashionStory:CheckGroupHadAccess(singlelineId)
    else
        return XMVCA.XFashionStory:CheckIfAnyGroupUnAccess()
    end
end

return XRedPointConditionFashionStoryNewChapterUnLock