local XRedPointDyeMergeMain = {}

---@type XRedPointEventElement[]
local Events = nil
---@type table @XRedPointConditions.Types
local SubCondition = nil

function XRedPointDyeMergeMain.GetSubEvents()
    return Events
end

function XRedPointDyeMergeMain.GetSubConditions()
    if SubCondition == nil then
        SubCondition = {
            XRedPointConditions.Types.CONDITION_DYEMERGE_TASK,
            XRedPointConditions.Types.CONDITION_DYEMERGE_NEW_CHAPTER,
        }
    end
    
    return SubCondition
end

---@param arg any
function XRedPointDyeMergeMain.Check(arg)
    if not XMVCA.XDyeMergeGame:GetIsActivityOpen() then
        return false
    end
    
    local conditions = XRedPointDyeMergeMain.GetSubConditions()

    if not XTool.IsTableEmpty(conditions) then
        if XRedPointManager.CheckConditions(conditions) then
            return true
        end
    end
end

return XRedPointDyeMergeMain