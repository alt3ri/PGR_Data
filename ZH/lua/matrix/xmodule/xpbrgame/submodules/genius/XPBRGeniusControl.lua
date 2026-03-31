---@class XPBRGeniusControl : XControl
---@field private _Model XPBRGameModel
---@field _MainControl XPBRGameControl
local XPBRGeniusControl = XClass(XControl, "XPBRGeniusControl")

function XPBRGeniusControl:OnInit()

end

function XPBRGeniusControl:AddAgencyEvent()

end

function XPBRGeniusControl:RemoveAgencyEvent()

end

function XPBRGeniusControl:OnRelease()

end

--region Configs

---@return XTablePBRMetaProgression[]
function XPBRGeniusControl:GetTablePBRMetaProgressionCfgs()
    return self._Model:GetTablePBRMetaProgressionCfgs()
end

---@return XTablePBRMetaProgression
function XPBRGeniusControl:GetTablePBRMetaProgressionCfgById(id, notips)
    return self._Model:GetTablePBRMetaProgressionCfgById(id, notips)
end

--endregion

--- 判断指定天赋节点是否解锁
function XPBRGeniusControl:GetIsNodeUnlock(nodeId)
    return self._Model.GeniusModel:GetIsNodeUnlock(nodeId)
end

--- 单独判断该节点是否有足够的货币进行解锁
function XPBRGeniusControl:GetIsNodeHaveEnoughCurrencyToUnlock(nodeId)
    local nodeCfg = self._Model:GetTablePBRMetaProgressionCfgById(nodeId)
    if not nodeCfg then
        return false
    end
    local curItemCount = self._MainControl:GetGeniusCoinCount()
    return curItemCount >= nodeCfg.NodeCost
end

--- 获取默认选中的节点
--- 没有解锁的默认选第一个，有则选择最大id的
function XPBRGeniusControl:GetDefaultSelectNodeId()
    local cfgs = self:GetTablePBRMetaProgressionCfgs()
    local firstLockNodeId = nil
    local maxUnlockNodeId = nil

    for _, cfg in pairs(cfgs) do
        if self:GetIsNodeUnlock(cfg.NodeId) then
            if not maxUnlockNodeId or cfg.NodeId > maxUnlockNodeId then
                maxUnlockNodeId = cfg.NodeId
            end
        else
            if not firstLockNodeId or cfg.NodeId < firstLockNodeId then
                firstLockNodeId = cfg.NodeId
            end
        end
    end

    return maxUnlockNodeId or firstLockNodeId
end

--- 获取所有已解锁天赋节点的属性增量合计
---@return table<number, number> 属性增量字典，key为属性ID，value为增加的属性原始值
function XPBRGeniusControl:GetAllUnlockNodeStatsAddition()
    local unlockNodeIds = self._Model.GeniusModel:GetAllUnlockNodeIds()

    if XTool.IsTableEmpty(unlockNodeIds) then
        return nil
    end

    local result = {}

    for _, nodeId in ipairs(unlockNodeIds) do
        local nodeCfg = self._Model:GetTablePBRMetaProgressionCfgById(nodeId)

        if nodeCfg and not XTool.IsTableEmpty(nodeCfg.NodeStats) then
            for i, statsId in ipairs(nodeCfg.NodeStats) do
                local statsNum = nodeCfg.NodeStatsNum and nodeCfg.NodeStatsNum[i] or 0

                if XTool.IsNumberValidEx(statsId) then
                    result[statsId] = (result[statsId] or 0) + statsNum
                end
            end
        end
    end

    return result
end

return XPBRGeniusControl