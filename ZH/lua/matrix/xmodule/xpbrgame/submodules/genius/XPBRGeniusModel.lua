---@class XPBRGeniusModel: XModel
---@field _MainModel XPBRGameModel
local XPBRGeniusModel = XClass(XModel, 'XPBRGeniusModel')

function XPBRGeniusModel:OnInit()

end

function XPBRGeniusModel:ClearPrivate()

end

function XPBRGeniusModel:ResetAll()

end

--- 判断指定天赋节点是否解锁
function XPBRGeniusModel:GetIsNodeUnlock(nodeId)
    local activityDb = self._MainModel.ActivityDb

    if activityDb and activityDb.MetaProgression and activityDb.MetaProgression.UnlockNodes then
        local unlockedNodes = activityDb.MetaProgression.UnlockNodes


        return table.contains(unlockedNodes, nodeId)
    end

    return false
end

--- 获取所有已解锁的天赋节点ID列表
---@return number[] 解锁的节点ID列表
function XPBRGeniusModel:GetAllUnlockNodeIds()
    local activityDb = self._MainModel.ActivityDb

    if activityDb and activityDb.MetaProgression and activityDb.MetaProgression.UnlockNodes then
        return activityDb.MetaProgression.UnlockNodes
    end
end

return XPBRGeniusModel