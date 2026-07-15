local XRedPointDyeMergeTask = {}

---@type XRedPointEventElement[]
local Events = nil
---@type table @XRedPointConditions.Types
local SubCondition = nil

function XRedPointDyeMergeTask.GetSubEvents()
    return Events
end

function XRedPointDyeMergeTask.GetSubConditions()
    return SubCondition
end

---@param arg any
function XRedPointDyeMergeTask.Check(arg)
    if not XMVCA.XDyeMergeGame:GetIsActivityOpen() then
        return false
    end
    
    return XMVCA.XDyeMergeGame:GetHasAnyTaskAchieved()
end

return XRedPointDyeMergeTask