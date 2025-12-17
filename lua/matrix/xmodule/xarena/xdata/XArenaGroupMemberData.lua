local XArenaGroupDataBase = require("XModule/XArena/XData/XArenaGroupDataBase")
local XArenaGroupPlayerData = require("XModule/XArena/XData/XArenaGroupPlayerData")

---@class XArenaGroupMemberData : XArenaGroupDataBase
local XArenaGroupMemberData = XClass(XArenaGroupDataBase, "XArenaGroupMemberData")

function XArenaGroupMemberData:_InitData(data)
    local groupPlayerList = data.GroupPlayerList

    self._WaveRate = data.WaveRate
    ---@type XArenaGroupPlayerData[]
    self._GroupPlayerList = {}
    ---@type table<number, XArenaGroupPlayerData>
    self._GroupPlayerMap = {}

    if not XTool.IsTableEmpty(groupPlayerList) then
        for i, groupPlayer in pairs(groupPlayerList) do
            ---@type XArenaGroupPlayerData
            local playerData = XArenaGroupPlayerData.New(groupPlayer)

            self._GroupPlayerList[i] = playerData
            self._GroupPlayerMap[playerData:GetId()] = playerData
        end
    end
end

function XArenaGroupMemberData:_ClearData()
    self._WaveRate = nil
    self._GroupPlayerList = nil
    self._GroupPlayerMap = nil
end

function XArenaGroupMemberData:GetWaveRate()
    return self._WaveRate
end

---@return XArenaGroupPlayerData[]
function XArenaGroupMemberData:GetGroupPlayerList()
    return self._GroupPlayerList
end

---@return XArenaGroupPlayerData
function XArenaGroupMemberData:GetGroupPlayerDataByPlayerId(playerId)
    return self._GroupPlayerMap[playerId]
end

function XArenaGroupMemberData:FindGroupPlayerDataByPlayerId(playerId)
    local groupList = self:GetGroupPlayerList()
    
    if not XTool.IsTableEmpty(groupList) then
        for i, playerData in pairs(groupList) do
            if playerData:GetId() == playerId then
                return i
            end
        end
    end
    
    return 0
end

return XArenaGroupMemberData
