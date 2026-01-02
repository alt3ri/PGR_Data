--region 服务端数据结构定义

---@class XGuildWarMyStationedData
---@field NodeId number
---@field CharacterId number

---@class XGuildWarGuildStationedData
---@field NodeId number
---@field Count number

--endregion

--- 公会战- 负责角色驻扎玩法的子model
---@class XRoleStationModel : XModel
local XRoleStationModel = XClass(XModel, "XRoleStationModel")

function XRoleStationModel:OnInit()
    ---@type XGuildWarMyStationedData[]
    self._MyStationedData = nil     -- 我的驻扎角色列表
    ---@type XGuildWarGuildStationedData[]
    self._GuildStationedData = nil  --  公会驻扎角色列表
    
    self._BeStationedFightRecord = nil -- 战斗记录，含历史周目信息
end

function XRoleStationModel:ClearPrivate()

end

function XRoleStationModel:ResetAll()
    self._MyStationedData = nil
    self._GuildStationedData = nil
end

--- 全量更新
function XRoleStationModel:UpdateRoleStationedData(data)
    if data then
        self._MyStationedData = data.MyStationedData
        self._GuildStationedData = data.GuildStationedData
    end
end

function XRoleStationModel:UpdateBeStationedFightRecord(record)
    self._BeStationedFightRecord = record
end

function XRoleStationModel:UpdateMyAndAllRoleStationedData(myStationedData, guildStationedData)
    if myStationedData then
        self._MyStationedData = myStationedData
    end

    if guildStationedData then
        self._GuildStationedData = guildStationedData
    end
end

---@return XGuildWarMyStationedData
function XRoleStationModel:GetMyStationedDataByNodeId(nodeId)
    if self._MyStationedData then
        for i, v in pairs(self._MyStationedData) do
            if v.NodeId == nodeId then
                return v
            end
        end
    end
end

--- 查找角色是否驻守在某个关卡，如果有，返回关卡节点Id
function XRoleStationModel:GetStationedNodeIdByCharacterId(characterId)
    if self._MyStationedData then
        for i, v in pairs(self._MyStationedData) do
            if v.CharacterId == characterId then
                return v.NodeId
            end
        end
    end
end

---@return XGuildWarGuildStationedData
function XRoleStationModel:GetGuildStationedDataByNodeId(nodeId)
    if self._GuildStationedData then
        for i, v in pairs(self._GuildStationedData) do
            if v.NodeId == nodeId then
                return v
            end
        end
    end
end

--- 判断指定节点是否有自己的角色驻扎
--- 需针对龙怒同位置节点切换处理
---@param nodeId @实际点击的节点ID，需要转换为根节点进行查找
function XRoleStationModel:GetMyRoleStationCharacterIdByNodeId(nodeId)
    local realNodeId = nodeId
    ---@type XGWNode
    local nodeEntity = XDataCenter.GuildWarManager.GetNode(nodeId)

    if nodeEntity then
        local rootId = nodeEntity:GetRootId()

        -- 如果有父Id，则以父Id为准进行查找
        if XTool.IsNumberValidEx(rootId) then
            realNodeId = rootId
        end

        local stationData = self:GetMyStationedDataByNodeId(realNodeId)

        if stationData then
            return stationData.CharacterId
        end
    end
end

--- 判断指定节点是否有战斗记录
function XRoleStationModel:CheckNodeHasFightRecordByNodeId(nodeId)
    if not XTool.IsTableEmpty(self._BeStationedFightRecord) then
        return table.contains(self._BeStationedFightRecord, nodeId)
    end
    
    return false
end

return XRoleStationModel