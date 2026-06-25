local XRedPointDyeMergeNewChapter = {}

---@type XRedPointEventElement[]
local Events = nil
---@type table @XRedPointConditions.Types
local SubCondition = nil

function XRedPointDyeMergeNewChapter.GetSubEvents()
    return Events
end

function XRedPointDyeMergeNewChapter.GetSubConditions()
    return SubCondition
end

---@param arg any
function XRedPointDyeMergeNewChapter.Check(arg)
    if not XMVCA.XDyeMergeGame:GetIsActivityOpen() then
        return false
    end
    
    return XMVCA.XDyeMergeGame:CheckAnyChapterShowReddot()
end

return XRedPointDyeMergeNewChapter