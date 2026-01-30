-- 援军
---@class XGWReinforcements
---@field Config XTableGuildWarReinforcements
local XGWReinforcements = XClass(nil, "XGWReinforcements")

function XGWReinforcements:Ctor(id)
    self.Config = XGuildWarConfig.GetReinforcementConfig(id)
    self.UID = 0
    self.CurrentHP = self.Config.HpMax
    self.MaxHP = self.Config.HpMax
    -- 当前路径索引
    self.CurrentRouteIndex = 0
    self.FightCount = 0
    self.DeadTime = 0
    -- 下一路径索引
    self.NextRouteIndex = 0
end

-- data : XGuildWarReinforcementData
function XGWReinforcements:UpdateWithServerData(data)
    self.UID = data.Uid
    self.ReinforcementId = data.ReinforcementId
    self.CurrentHP = data.CurHp
    self.MaxHP = data.HpMax
    self.CurNodeId = data.CurNodeId
    self.DeadTime = data.DeadTime
    self.NextMoveTime = data.NextMoveTime or 0
    self.SupportedPlayerIds = data.SupportedPlayerIds
    self.ReadyDoneTime = data.ReadyDoneTime
end

--region ---------------------------- 获取实时数据 ----------------------->>>
function XGWReinforcements:GetIsDead()
    return self.CurrentHP <= 0
end

function XGWReinforcements:GetUID()
    return self.UID
end

-- 获取百分比血量
function XGWReinforcements:GetPercentageHP()
    return getRoundingValue((self:GetHP() / self:GetMaxHP()) * 100, 2)
end

function XGWReinforcements:GetHP()
    return self.CurrentHP
end

function XGWReinforcements:GetMaxHP()
    return self.MaxHP
end

function XGWReinforcements:GetCurrentNodeId()
    return self.CurNodeId
end

function XGWReinforcements:GetNextNodeId()
    return self.NextNodeId or 0
end

function XGWReinforcements:GetNextMoveTime()
    return self.NextMoveTime
end

function XGWReinforcements:GetReadyTime()
    return self.ReadyDoneTime
end

function XGWReinforcements:UpdateCurrentNodeId(nodeId)
    self.CurNodeId = nodeId
end

function XGWReinforcements:UpdateNextNodeId(nodeId)
    self.NextNodeId = nodeId
end

function XGWReinforcements:UpdateDead(IsDead)--如果为true视为：死的复活，活的保持
    self.CurrentHP = IsDead and 0 or (self.CurrentHP > 0 and self.CurrentHP or 1)
end

function XGWReinforcements:GetCurrentSupportCost()
    if not XTool.IsTableEmpty(self.SupportedPlayerIds) then
        return self.Config.SupportCost * XTool.GetTableCount(self.SupportedPlayerIds)
    else
        return 0
    end
end

function XGWReinforcements:CheckPlayerIsSupported(playerId)
    if not XTool.IsTableEmpty(self.SupportedPlayerIds) then
        return table.contains(self.SupportedPlayerIds, playerId)
    end
    return false
end

function XGWReinforcements:GetSupportPlayerCount()
    return XTool.GetTableCount(self.SupportedPlayerIds)
end

function XGWReinforcements:AddPlayerSupportedCache(playerId)
    if XTool.IsTableEmpty(self.SupportedPlayerIds) or not table.contains(self.SupportedPlayerIds, playerId) then
        table.insert(self.SupportedPlayerIds, playerId)
    end
end

function XGWReinforcements:RemovePlayerSupportedCache(playerId)
    if not XTool.IsTableEmpty(self.SupportedPlayerIds) then
        local isContain, pos = table.contains(self.SupportedPlayerIds, playerId)

        if isContain then
            table.remove(self.SupportedPlayerIds, pos)
        end
    end
end
--endregion <<<---------------------------------------------------------------

--region ------------------------------ 获取配置字段 -------------------------->>>

function XGWReinforcements:GetReinforcementName()
    return self.Config.Name
end

function XGWReinforcements:GetIcon()
    return self.Config.Icon
end

function XGWReinforcements:GetShowFightEvents()
    return self.Config.ShowFightEventIds
end

--endregion <<<----------------------------------------------------------------

return XGWReinforcements