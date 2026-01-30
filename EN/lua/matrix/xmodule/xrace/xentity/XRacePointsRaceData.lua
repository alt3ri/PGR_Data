---@class XRacePointsRaceData : XEntity 积分赛
---@field _OwnControl XRaceControl
---@field _Model XRaceModel
local XRacePointsRaceData = XClass(XEntity, "XRacePointsRaceData")

local PointsRaceRoleCount = 6

function XRacePointsRaceData:OnInit()
    ---@type table<number,RaceRoundResult>
    self._BaseDatas = {}
end

function XRacePointsRaceData:InitData(pointGroupId)
    self._PointGroupId = pointGroupId
    self._RoundIds = self._Model:GetRaceRoundPointGroupAutoById(pointGroupId).RoundIds --有序的
    self._PromotionNum = self._OwnControl:GetEtcdRoundConfig(self._RoundIds[#self._RoundIds]).PromotionNum

    local serverDatas = self._Model:GetRoundDict()
    if not XTool.IsTableEmpty(serverDatas) then
        for _, roundId in ipairs(self._RoundIds) do
            self:UpdateRoundData(roundId, serverDatas[roundId])
        end
    end

    self:UpdateRole()
end

function XRacePointsRaceData:UpdateRoundData(roundId, baseData)
    self._BaseDatas[roundId] = baseData
    self:UpdateRole()
end

function XRacePointsRaceData:UpdateRole()
    self._RoleIds = {} --展示及进入比赛用
    self._RankRoleIds = {} --排行榜用
    self._UpRoleIds = {} --晋升名单
    self._DownRoleIds = {} --淘汰名单
    ---@type table<number,PointsRaceRankData>
    self._RoleRankDataDict = {}

    local serverDatas = self._Model:GetRoundDict()
    local serverData = serverDatas[self._RoundIds[1]]
    if XTool.IsTableEmpty(serverData) then
        ---- 没有服务端数据 读表
        local characterGroupId = self._OwnControl:GetEtcdRoundConfig(self._RoundIds[1]).CharacterGroupId
        local characterIds = self._OwnControl:GetRaceCharacterGroupById(characterGroupId).CharacterId
        self._RoleIds = XTool.Clone(characterIds)
        -- 与服务端逻辑保持一致 按Id从小到大排序
        table.sort(self._RoleIds)
        return
    end
    
    local ids = serverData.EnterRaceCharacterIds
    table.sort(ids, function(a, b)
        return a.RaceId < b.RaceId
    end)
    for _, v in ipairs(ids) do
        table.insert(self._RoleIds, v.CharacterId)
    end

    for i, roundId in ipairs(self._RoundIds) do
        local serverData = serverDatas[roundId]
        local data = serverData and serverData.RankResult
        if not XTool.IsTableEmpty(data) then
            self._UpRoleIds = serverData.PromotionCharacterIds
            self._DownRoleIds = serverData.LoseCharacterIds

            for _, result in pairs(data) do
                local inRankIndex = result[1] --单场比赛局内排名（只看比赛时间）
                local roleId = result[2]
                local time = result[3]
                local point = result[4]
                local outRankIndex = result[5] --单场比赛局外排名（根据所有轮次比赛的积分进行排名）
                self._RankRoleIds[outRankIndex] = roleId --本组积分赛排名

                local tb = self._RoleRankDataDict[roleId]
                if not tb then
                    tb = {}
                    tb.InRankList = {}
                    tb.OutRankList = {}
                    tb.TimeList = {}
                    tb.Point = 0
                    tb.PointList = {}
                    self._RoleRankDataDict[roleId] = tb
                end
                local lastPoint = tb.PointList[#tb.PointList] or 0
                local lastTime = tb.TimeList[#tb.TimeList] or 0
                table.insert(tb.InRankList, inRankIndex)
                table.insert(tb.OutRankList, outRankIndex)
                table.insert(tb.TimeList, time - lastTime)
                table.insert(tb.PointList, point - lastPoint)
                tb.Point = point
            end
        end
    end
end

function XRacePointsRaceData:GetRounds()
    return self._RoundIds
end

function XRacePointsRaceData:GetRoundId()
    return self._RoundIds[1]
end

---组内所有轮次是否都已结束
function XRacePointsRaceData:IsGroupEnd()
    local lastRoundId = self._RoundIds[#self._RoundIds]
    return self:IsMatchEnd(lastRoundId)
end

function XRacePointsRaceData:IsMatchEnd(roundId)
    return not XTool.IsTableEmpty(self._BaseDatas[roundId])
end

---积分赛每组6人
function XRacePointsRaceData:GetRoleCount()
    return PointsRaceRoleCount
end

function XRacePointsRaceData:GetShowRoleIds()
    return self._RoleIds
end

function XRacePointsRaceData:GetShowRoleId(index)
    return self._RoleIds[index]
end

function XRacePointsRaceData:GetRankRoleIds()
    return self._RankRoleIds
end

function XRacePointsRaceData:GetUpRoleIds()
    return self._UpRoleIds
end

function XRacePointsRaceData:GetRoleRankData(roleId)
    return self._RoleRankDataDict[roleId]
end

function XRacePointsRaceData:GetInRoleRank(roleId, index)
    local data = self:GetRoleRankData(roleId)
    return data and data.InRankList[index]
end

function XRacePointsRaceData:GetOutRoleRank(roleId, index)
    local data = self:GetRoleRankData(roleId)
    return data and data.OutRankList[index]
end

function XRacePointsRaceData:GetRoleTime(roleId, index)
    local data = self:GetRoleRankData(roleId)
    return data and data.TimeList[index]
end

function XRacePointsRaceData:GetSinglePoint(roleId, index)
    local data = self:GetRoleRankData(roleId)
    return data and data.PointList[index]
end

function XRacePointsRaceData:GetRoleTotalPoint(roleId)
    local data = self:GetRoleRankData(roleId)
    return data and data.Point
end

---@return table<number,PointsRaceRankData>
function XRacePointsRaceData:GetRoleRankDatas()
    return self._RoleRankDataDict
end

---角色是否晋升
function XRacePointsRaceData:IsRoleUp(roleId)
    if self:IsGroupEnd() then
        return table.contains(self._UpRoleIds, roleId)
    end
    return false
end

---角色是否淘汰
function XRacePointsRaceData:IsRoleDown(roleId)
    if self:IsGroupEnd() then
        return table.contains(self._DownRoleIds, roleId)
    end
    return false
end

return XRacePointsRaceData

---@class PointsRaceRankData
---@field InRankList number[]
---@field OutRankList number[]
---@field TimeList number[] 单场比赛用时
---@field Point number 总积分
---@field PointList number[] 单场比赛积分