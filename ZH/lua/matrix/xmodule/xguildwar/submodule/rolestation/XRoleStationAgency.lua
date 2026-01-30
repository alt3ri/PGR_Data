--- 公会战角色驻扎玩法子agency
---@class XRoleStationAgency : XAgency
---@field private _Model XGuildWarModel
local XRoleStationAgency = XClass(XAgency, "XRoleStationAgency")

function XRoleStationAgency:OnInit()

end

function XRoleStationAgency:OnRelease()

end

--- 从登录下推数据中找出需要的数据进行缓存
function XRoleStationAgency:UpdateDataFromLoginNotify(data)
    self.HaveMyRoundData = false
    if not XTool.IsTableEmpty(data.ActivityData.RoundData) then
        for i, myRoundData in pairs(data.ActivityData.RoundData) do
            -- 只更新查找当前轮次的数据
            if myRoundData.RoundId == XDataCenter.GuildWarManager.GetCurrentRoundId() then
                -- 3.0改版后 以服务器数据标记为主
                if XDataCenter.GuildManager.GetGuildId() == myRoundData.GuildId
                        and myRoundData.DifficultyId == 0 then
                    return
                end

                self._Model.RoleStationModel:UpdateRoleStationedData(myRoundData)

                self.HaveMyRoundData = true
            end
        end
    end
    
    self._Model.RoleStationModel:UpdateBeStationedFightRecord(data.BeStationedFightRecord)
end

--- 活动请求数据刷新
function XRoleStationAgency:RefreshDataFromActivityData(activityData)
    if XTool.IsTableEmpty(activityData) then
        return
    end

    if not XTool.IsTableEmpty(activityData.RoundData) then
        for i, myRoundData in pairs(activityData.RoundData) do
            -- 只更新查找当前轮次的数据
            if myRoundData.RoundId == XDataCenter.GuildWarManager.GetCurrentRoundId() then
                if XDataCenter.GuildManager.GetGuildId() == myRoundData.GuildId
                        and myRoundData.DifficultyId == 0 then
                    return
                end

                self._Model.RoleStationModel:UpdateRoleStationedData(myRoundData)
            end
        end
    end
end

--region Network

--- 关卡节点角色驻扎请求
---@param characterId @传0表示撤除
function XRoleStationAgency:RequestXGuildWarBeStationed(nodeId, characterId, cb)
    ---@type XGWNode
    local nodeEntity = XDataCenter.GuildWarManager.GetNode(nodeId)
    local nodeUid = nil

    if nodeEntity then
        nodeUid = nodeEntity:GetUID()
    end

    if not XTool.IsNumberValidEx(nodeUid) then
        XLog.Error('找不到关卡节点对应的数据，nodeId:' .. tostring(nodeId))
        return
    end
    
    XNetwork.Call("XGuildWarBeStationedRequest", { NodeUid = nodeUid, CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end
            
            return
        end
        
        self._Model.RoleStationModel:UpdateRoleStationedData(res)

        if cb then
            cb(true)
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PLAYER_STATION_CHANGE)
    end)
end

--endregion

--region Config 

--- 编队将驻扎角色加入时的提示
function XRoleStationAgency:GetClientConfigCharacterJoinTeamWithStationedTips(...)
    local format = XGuildWarConfig.GetClientConfigValue('CharacterJoinTeamWithStationedTips')
    return XUiHelper.FormatText(format, ...)
end

--endregion

--region Condition

function XRoleStationAgency:GetStationedNodeIdByCharacterId(characterId)
    return self._Model.RoleStationModel:GetStationedNodeIdByCharacterId(characterId)
end

function XRoleStationAgency:CheckCharacterIsStationedAnyNode(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end

    if not XTool.IsNumberValidEx(characterId) then
        return false
    end
    
    local nodeId = self._Model.RoleStationModel:GetStationedNodeIdByCharacterId(characterId)

    return XTool.IsNumberValidEx(nodeId)
end

function XRoleStationAgency:CheckNodeIsAnyCharacterStationed(nodeId)
    local stationedCharacterId = self._Model.RoleStationModel:GetMyRoleStationCharacterIdByNodeId(nodeId)

    return XTool.IsNumberValidEx(stationedCharacterId)
end
--endregion

return XRoleStationAgency