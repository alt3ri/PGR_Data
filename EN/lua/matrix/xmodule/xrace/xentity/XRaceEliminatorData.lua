---@class XRaceEliminatorData : XEntity 淘汰赛
---@field _OwnControl XRaceControl
---@field _Model XRaceModel
local XRaceEliminatorData = XClass(XEntity, "XRaceEliminatorData")

local EliminatorRoleCount = 8

function XRaceEliminatorData:OnInit()

end

function XRaceEliminatorData:InitData(roundId)
    local serverDatas = self._Model:GetRoundDict()
    local cfg = self._Model:GetRaceRoundById(roundId)
    self._RoundId = roundId
    self._IsFinal = cfg.EndShowType == XEnumConst.Race.RankTag.Champion
    self._BaseData = serverDatas and serverDatas[roundId]
    self._PromotionNum = self._OwnControl:GetEtcdRoundConfig(roundId).PromotionNum
    self:UpdateRole()
end

function XRaceEliminatorData:UpdateRoundData(baseData)
    self._BaseData = baseData
    self:UpdateRole()
end

function XRaceEliminatorData:UpdateRole()
    self._RoleIds = {}
    self._RankRoleIds = {} --排行榜用
    self._UpRoleIds = {} --晋升名单
    self._DownRoleIds = {} --淘汰名单
    self._RoleTimeDict = {}

    if XTool.IsTableEmpty(self._BaseData) then
        -- 没有服务端数据 读上一把晋升数据
        local serverDatas = self._Model:GetRoundDict()
        local roundCfg = self._OwnControl:GetEtcdRoundConfig(self._RoundId)
        for i, id in ipairs(roundCfg.FromRoundIds) do
            local etcd = self._OwnControl:GetEtcdRoundConfig(id)
            if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
                -- 积分赛 → 淘汰赛
                local pointsRace = self._OwnControl:GetPointsRaceData(etcd.PointGroupId)
                if pointsRace:IsGroupEnd() then
                    for _, id in pairs(pointsRace:GetUpRoleIds()) do
                        table.insert(self._RoleIds, id)
                    end
                end
            else
                -- 淘汰赛 → 总决赛
                local eliminator = self._OwnControl:GetEliminatorData(id)
                if eliminator:IsMatchEnd() then
                    for _, id in pairs(eliminator:GetUpRoleIds()) do
                        table.insert(self._RoleIds, id)
                    end
                end
            end
        end
        table.sort(self._RoleIds)
        return
    end
    
    local ids = self._BaseData.EnterRaceCharacterIds
    table.sort(ids, function(a, b)
        return a.RaceId < b.RaceId
    end)
    for _, v in pairs(ids) do
        table.insert(self._RoleIds, v.CharacterId)
    end
    self._UpRoleIds = self._BaseData.PromotionCharacterIds
    self._DownRoleIds = self._BaseData.LoseCharacterIds
    
    for _, v in ipairs(self._BaseData.RankResult) do
        local rankIndex = v[1]
        local roleId = v[2]
        local time = v[3]
        self._RankRoleIds[rankIndex] = roleId
        self._RoleTimeDict[roleId] = time
    end
end

function XRaceEliminatorData:GetRoundId()
    return self._RoundId
end

---淘汰赛每组8人
function XRaceEliminatorData:GetRoleCount()
    return EliminatorRoleCount
end

function XRaceEliminatorData:GetShowRoleIds()
    return self._RoleIds
end

function XRaceEliminatorData:GetShowRoleId(index)
    return self._RoleIds[index]
end

function XRaceEliminatorData:GetRankRoleIds()
    return self._RankRoleIds
end

function XRaceEliminatorData:GetRankRoleId(index)
    return self._RankRoleIds[index]
end

function XRaceEliminatorData:GetUpRoleIds()
    return self._UpRoleIds
end

function XRaceEliminatorData:GetRolePassTime(roleId)
    return self._RoleTimeDict[roleId]
end

function XRaceEliminatorData:HasRoleData()
    return not XTool.IsTableEmpty(self._RoleIds)
end

---比赛是否已结束
function XRaceEliminatorData:IsMatchEnd()
    return not XTool.IsTableEmpty(self._BaseData)
end

---角色是否晋升
function XRaceEliminatorData:IsRoleUp(roleId)
    if self:IsMatchEnd() then
        return table.contains(self._UpRoleIds, roleId)
    end
    return false
end

---角色是否淘汰
function XRaceEliminatorData:IsRoleDown(roleId)
    if self:IsMatchEnd() then
        return table.contains(self._DownRoleIds, roleId)
    end
    return false
end

---是否总决赛
function XRaceEliminatorData:IsFinal()
    return self._IsFinal
end

function XRaceEliminatorData:IsTimeOpen()
    local etcd = self._OwnControl:GetEtcdRoundConfig(self._RoundId)
    if etcd then
        return XTime.GetServerNowTimestamp() >= etcd.StartTimeLong
    end
    return false
end

--可能开启时间比上一把比赛结束时间要晚
function XRaceEliminatorData:IsOpen()
    return self:IsTimeOpen() and self:HasRoleData()
end

return XRaceEliminatorData