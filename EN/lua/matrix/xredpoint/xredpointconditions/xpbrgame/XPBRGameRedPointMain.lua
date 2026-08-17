local XPBRGameRedPointMain = {}

---@type XRedPointEventElement[]
local Events = nil
---@type table @XRedPointConditions.Types
local SubCondition = nil

function XPBRGameRedPointMain.GetSubEvents()
    return Events
end

function XPBRGameRedPointMain.GetSubConditions()
    return SubCondition
end

---@param arg any
function XPBRGameRedPointMain.Check(arg)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PBRGame, true, true) then
        return false
    end

    if not XMVCA.XPBRGame:GetIsActivityOpen(false) then
        return false
    end
    
    -- 新解锁关卡
    if XMVCA.XPBRGame:ReddotIsAnyStageNewUnlock() then
        return true
    end
    
    -- 天赋节点可解锁
    if XMVCA.XPBRGame:ReddotIsAnyGeniusNodeCanUnlock() then
        return true
    end
    
    -- 任务达成
    if XMVCA.XPBRGame:ReddotIsAnyTaskAchieved() then
        return true
    end
    
    -- 涂装未领取
    if XMVCA.XPBRGame:ReddotIsSkinRewardNotGet() then
        return true
    end
end

return XPBRGameRedPointMain