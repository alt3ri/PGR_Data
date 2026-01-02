--- 公会战-角色驻守玩法子控制器
---@class XRoleStationControl: XControl
---@field private _Model XGuildWarModel
---@field _MainControl XGuildWarControl
local XRoleStationControl = XClass(XControl, 'XRoleStationControl')

function XRoleStationControl:OnInit()

end

function XRoleStationControl:OnRelease()

end

--region Get

--- 判断指定节点是否有自己的角色驻扎
--- 需针对龙怒同位置节点切换处理
---@param nodeId @实际点击的节点ID，需要转换为根节点进行查找
function XRoleStationControl:GetMyRoleStationCharacterIdByNodeId(nodeId)
    return self._Model.RoleStationModel:GetMyRoleStationCharacterIdByNodeId(nodeId)
end

--- 针对驻扎角色列表显示规则进行排序的角色列表
---@param curNodeId @实际选中的节点
function XRoleStationControl:GetOwnCharacterListWithStationSort(curNodeId)
    local ownCharList = XMVCA.XCharacter:GetOwnCharacterListWithNoSort()
    
    table.sort(ownCharList, function(a, b) 
        -- 驻扎在当前节点的角色最前
        local isAStationedInThisNode = self:CheckCharacterIsStationedInTargetNode(a.Id, curNodeId)
        local isBStationedInThisNode = self:CheckCharacterIsStationedInTargetNode(b.Id, curNodeId)

        if isAStationedInThisNode ~= isBStationedInThisNode then
            return isAStationedInThisNode
        end
        
        -- 未驻扎的角色排驻扎别的节点的前面
        local isAStationedAny = self:CheckCharacterIsStationedAnyNode(a.Id)
        local isBStationedAny = self:CheckCharacterIsStationedAnyNode(b.Id)

        if isAStationedAny ~= isBStationedAny then
            return isBStationedAny
        end
        
        -- 剩下的按等级升序排序
        if a.Level ~= b.Level then
            return a.Level < b.Level
        end
        
        return a.Id < b.Id
    end)
    
    return ownCharList
end

--- 获取指定节点驻扎角色数量
function XRoleStationControl:GetCurNodeStationedRoleCount(nodeId)
    local nodeCfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if nodeCfg and XTool.IsNumberValidEx(nodeCfg.RootId) then
        nodeId = nodeCfg.RootId
    end
    
    local stationedData = self._Model.RoleStationModel:GetGuildStationedDataByNodeId(nodeId)

    if stationedData then
        return stationedData.Count or 0
    end
    
    return 0
end

--- 获取节点指定驻扎角色数削减的血量百分比
function XRoleStationControl:GetCurNodeDeployPercentNumByStationedCount(nodeId, count)
    local buffNum = self:GetCurNodeDeployBuffNumByStationedCount(nodeId, count)
    local nodeMaxHp = 1

    ---@type XTableGuildWarNode
    local nodeCfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if nodeCfg then
        nodeMaxHp = nodeCfg.HpMax
    end
    
    return buffNum / nodeMaxHp
end

--endregion

--region Config

function XRoleStationControl:GetCurNodeStationedMaxCount(nodeId)
    ---@type XTableGuildWarNode
    local nodeCfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if nodeCfg then
        return nodeCfg.DeployCharacterMax or 0
    end
    
    return 0
end

function XRoleStationControl:GetCurNodeDeployBuffNumByStationedCount(nodeId, count)
    ---@type XTableGuildWarNode
    local nodeCfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if nodeCfg then
        return nodeCfg.DeployBuff[count] or 0
    end

    return 0
end

function XRoleStationControl:GetGuildWarSpecialRoleTeamCfgs()
    return self._Model:GetGuildWarSpecialRoleTeamCfgs()
end

--- 选择角色驻扎的驻扎文本，1是正常驻扎，2是角色在其他关卡驻扎中
function XRoleStationControl:GetClientConfigRoleStationBtnName(canBeStationed)
    return XGuildWarConfig.GetClientConfigValue('RoleStationBtnName', 'string', canBeStationed and 1 or 2)
end

--- 确认驻扎时未选择角色的提示
function XRoleStationControl:GetClientConfigNoRoleSelectForStation()
    return XGuildWarConfig.GetClientConfigValue('NoRoleSelectForStation')
end

--- 选择已驻扎其他节点的角色，点击按钮时提示
function XRoleStationControl:GetClientConfigRoleStationedOtherNodeTips()
    return XGuildWarConfig.GetClientConfigValue('RoleStationedOtherNodeTips')
end

--- 选择角色驻扎成功的飘窗
function XRoleStationControl:GetClientConfigRoleStationedSuccessTips()
    return XGuildWarConfig.GetClientConfigValue('RoleStationedSuccessTips')
end

--- 关卡详情面板里，驻扎UI标题文本，1是可驻扎，2是已驻扎，3是满了不能驻扎
function XRoleStationControl:GetClientConfigPanelRoleStationStateShow(hasStationed, canStationed)
    local index = hasStationed and 2 or 1

    if not canStationed then
        index = 3
    end
    
    return XGuildWarConfig.GetClientConfigValue('PanelRoleStationStateShow', 'string', index)
end

--- 关卡详情面板，驻扎进度及效果描述文本
function XRoleStationControl:GetClientConfigPanelRoleStationProgressShow(curNum, maxNum, percentStr)
    local format = XGuildWarConfig.GetClientConfigValue('PanelRoleStationProgressShow')
    
    format = XUiHelper.ReplaceTextNewLine(format)
    
    return XUiHelper.FormatText(format, curNum, maxNum, percentStr)
end

--- 移除驻扎角色成功的飘窗
function XRoleStationControl:GetClientConfigRoleStationedRemoveTips()
    return XGuildWarConfig.GetClientConfigValue('RoleStationedRemoveTips')
end

--- 驻扎已达上限时的点击提示
function XRoleStationControl:GetClientConfigCannotStationedWithMaxTips()
    return XGuildWarConfig.GetClientConfigValue('CannotStationedWithMaxTips')
end

--endregion

--region Condition

--- 判断指定节点是否可以驻守
---@param nodeId @实际点击的节点ID
function XRoleStationControl:CheckNodeCanBeStationed(nodeId)
    -- 休战期无法驻守
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        return false
    end
    
    ---@type XTableGuildWarNode
    local nodeCfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if nodeCfg then
        if nodeCfg.Type == XGuildWarConfig.NodeType.NodeRelic then
            -- 废墟不可驻守
            return false
        elseif nodeCfg.Type == XGuildWarConfig.NodeType.NodeBoss7 or nodeCfg.Type == XGuildWarConfig.NodeType.Term4BossChild or nodeCfg.Type == XGuildWarConfig.NodeType.Term4BossRoot then
            -- Boss相关节点不可驻守
            return false
        elseif nodeCfg.Type == XGuildWarConfig.NodeType.Home then
            -- 基地不可驻守
            return false    
        end

        -- 否则当期周目下该位置节点至少打过一次
        if self:CheckSamePosNodeHasFight(nodeId) then
            return true
        end
    end
    
    return false
end

--- 判断指定角色是否驻扎在指定关卡节点
function XRoleStationControl:CheckCharacterIsStationedInTargetNode(characterId, nodeId)
    local stationedCharacterId = self:GetMyRoleStationCharacterIdByNodeId(nodeId)
    
    return characterId == stationedCharacterId
end

function XRoleStationControl:CheckCharacterIsStationedAnyNode(characterId)
    local nodeId = self._Model.RoleStationModel:GetStationedNodeIdByCharacterId(characterId)
    
    return XTool.IsNumberValidEx(nodeId)
end

function XRoleStationControl:CheckNodeIsAnyCharacterStationed(nodeId)
    local stationedCharacterId = self:GetMyRoleStationCharacterIdByNodeId(nodeId)
    
    return XTool.IsNumberValidEx(stationedCharacterId)
end

function XRoleStationControl:CheckNodeStationedIsMax(nodeId)
    local guildStationedData = self._Model.RoleStationModel:GetGuildStationedDataByNodeId(nodeId)
    local hasStationedCount = guildStationedData and guildStationedData.Count or 0
    
    local limitCount = 0
    
    ---@type XTableGuildWarNode
    local nodeCfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if nodeCfg then
        limitCount = nodeCfg.DeployCharacterMax
    end
    
    return hasStationedCount == limitCount
end

--- 判断指定节点及同位置的父/子节点是否至少打过一次
function XRoleStationControl:CheckSamePosNodeHasFight(nodeId)
    local isSelfFight = false

    ---@type XGWNode
    local nodeEntity = XDataCenter.GuildWarManager.GetNode(nodeId)

    if nodeEntity and self._Model.RoleStationModel:CheckNodeHasFightRecordByNodeId(nodeId) then
        isSelfFight = true
    end

    -- 判断是否有父节点，及父节点是否打过一次
    if not isSelfFight then
        local rootId = nodeEntity:GetRootId()

        if XTool.IsNumberValidEx(nodeEntity:GetRootId()) then
            if self:CheckSamePosNodeHasFight(rootId) then
                isSelfFight = true
            end
        end
    end

    -- 判断是否有子节点，及任意子节点是否打过一次
    if not isSelfFight then
        local childrenNodes = nodeEntity:GetChildrenNodes()

        -- 针对子节点就不递归了
        if not XTool.IsTableEmpty(childrenNodes) then
            for i, v in pairs(childrenNodes) do
                if self._Model.RoleStationModel:CheckNodeHasFightRecordByNodeId(v:GetId()) then
                    isSelfFight = true
                    break
                end
            end
        end
    end

    return isSelfFight
end
--endregion

return XRoleStationControl