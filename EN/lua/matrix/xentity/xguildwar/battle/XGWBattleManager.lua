--============
--工会战战场节点管理器
--============
local XTeam = require("XEntity/XTeam/XTeam")
local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
local XHomeGWNode = require("XEntity/XGuildWar/Battle/Node/XHomeGWNode")
local XBuffGWNode = require("XEntity/XGuildWar/Battle/Node/XBuffGWNode")
local XGuardGWNode = require("XEntity/XGuildWar/Battle/Node/XGuardGWNode")
local XInfectGWNode = require("XEntity/XGuildWar/Battle/Node/XInfectGWNode")
local XSentinelGWNode = require("XEntity/XGuildWar/Battle/Node/XSentinelGWNode")
local XGWEliteMonster = require("XEntity/XGuildWar/Battle/XGWEliteMonster")
local XGWReinforcements = require("XEntity/XGuildWar/Battle/XGWReinforcements")
--local XPandaRootGWNode = require("XEntity/XGuildWar/Battle/Node/XPandaRootGWNode")
--local XPandaChildGWNode = require("XEntity/XGuildWar/Battle/Node/XPandaChildGWNode")
--local XTwinsRootGWNode = require("XEntity/XGuildWar/Battle/Node/XTwinsRootGWNode")
--local XTwinsChildGWNode = require("XEntity/XGuildWar/Battle/Node/XTwinsChildGWNode")
--local XTerm3SecretRootGWNode = require("XEntity/XGuildWar/Battle/Node/XTerm3SecretRootGWNode")
--local XTerm3SecretChildGWNode = require("XEntity/XGuildWar/Battle/Node/XTerm3SecretChildGWNode")
local XSecondarySentinelGWNode = require("XEntity/XGuildWar/Battle/Node/XSecondarySentinelGWNode")
local XBlockadeGWNode = require("XEntity/XGuildWar/Battle/Node/XBlockadeGWNode")
local XTerm4BossGWNode = require("XEntity/XGuildWar/Battle/Node/XTerm4BossGWNode")
local XTerm4BossChildGWNode = require("XEntity/XGuildWar/Battle/Node/XTerm4BossChildGWNode")
local XResGWNode = require('XEntity/XGuildWar/Battle/Node/XResGWNode')
local XRelicGWNode = require('XModule/XGuildWar/Entity/Node/XRelicGWNode')
local XBoss7GWNode = require('XModule/XGuildWar/Entity/Node/XBoss7GWNode')

---@class XGWBattleManager
local XGWBattleManager = XClass(nil, "XGWBattleManager")
--节点类型和节点Entity映射表
local NodeType2Class = {
    [XGuildWarConfig.NodeType.Home] = XHomeGWNode,
    [XGuildWarConfig.NodeType.Normal] = XNormalGWNode,
    [XGuildWarConfig.NodeType.Buff] = XBuffGWNode,
    [XGuildWarConfig.NodeType.Sentinel] = XSentinelGWNode,
    [XGuildWarConfig.NodeType.Guard] = XGuardGWNode,
    [XGuildWarConfig.NodeType.Infect] = XInfectGWNode,
    --[XGuildWarConfig.NodeType.PandaRoot] = XPandaRootGWNode,
    --[XGuildWarConfig.NodeType.PandaChild] = XPandaChildGWNode,
    --[XGuildWarConfig.NodeType.TwinsRoot] = XTwinsRootGWNode,
    --[XGuildWarConfig.NodeType.TwinsChild] = XTwinsChildGWNode,
    --[XGuildWarConfig.NodeType.Term3SecretRoot] = XTerm3SecretRootGWNode,
    --[XGuildWarConfig.NodeType.Term3SecretChild] = XTerm3SecretChildGWNode,
    [XGuildWarConfig.NodeType.SecondarySentinel] = XSecondarySentinelGWNode,

    [XGuildWarConfig.NodeType.Term4BossRoot] = XTerm4BossGWNode,
    [XGuildWarConfig.NodeType.Term4BossChild] = XTerm4BossChildGWNode,
    [XGuildWarConfig.NodeType.Blockade] = XBlockadeGWNode,
    [XGuildWarConfig.NodeType.Resource] = XResGWNode,
    
    [XGuildWarConfig.NodeType.NodeBoss7] = XBoss7GWNode,
    [XGuildWarConfig.NodeType.NodeRelic] = XRelicGWNode,
}

--不显示在地图上的节点类型HashSet
local HashSetInvisibleMapNodeType = {
    [XGuildWarConfig.NodeType.PandaChild] = true,
    [XGuildWarConfig.NodeType.TwinsChild] = true,
    [XGuildWarConfig.NodeType.Term3SecretChild] = true,
    [XGuildWarConfig.NodeType.Term4BossChild] = true,
}

local CreateNode = function(id)
    local nodeConfig = XGuildWarConfig.GetNodeConfig(id)
    if nodeConfig == nil then
        XLog.Error(string.format( "找不到节点%s配置", id))
        return
    end
    local nodeType = nodeConfig.Type
    local classDefine = NodeType2Class[nodeType]
    if classDefine == nil then
        XLog.Error(string.format( "找不到节点%s类型%s配置", id, nodeType))
        return
    end
    local result = classDefine.New(id)
    return result
end

function XGWBattleManager:Ctor(difficultyId)
    self.DifficultyId = difficultyId
    -- 所有节点
    self.NodeDic = {}
    -- { [uid] = XGWEliteMonster }
    self.MonsterDic = {}
    -- { [uid] = XGWReinforcements }
    self.ReinforcementDic = {}
    -- 路线节点字典
    self.NodeId2PathIndex = {}
    -- 我自己的回合数据 XGuildWarRoundDataDb
    self.CurrentMyRoundData = nil
    -- 节点战斗记录数据 { GuildWarFightRecord }
    self.FightRecords = {}
    -- 旧周目节点战斗记录-龙怒玩法特供 { GuildWarFightRecord }
    self.LastRoundFightRecords = {}
    -- 当前轮次的数据
    self.CurrentRoundData = nil
    -- 行动动画队列
    self.ActionList = {}
    -- 行动动画队列Id映射字典
    self.ActionIdMap = {}
    -- 行动动画是否需要缩放字典
    self.ActionZoomDic = {}
    -- 已观看的行动ID
    self.ShowedActionIdDic = {}
    -- 行动正在展示中
    self.IsActionPlayingDic = {}
    -- 当前客户端缓存的战斗UID， 节点或怪物的
    self.CurrentClientBattleUID = nil
    -- 当前客户端缓存的节点状态
    self.CurrentClientBattleNodeStatus = nil
    -- 行动动画是否是历史动画
    self.IsHistoryAction = false
    -- 行动动画是否缩放
    self.IsActionInZoom = false
    -- 等待动画播放请求
    self.IsWaitingActionCallback = false
end

--region 数据
-- 更新档次轮次数据
-- data : GuildWarActivityData
function XGWBattleManager:UpdateCurrentRoundData(data, difficultyChanged, isRealTime, type, updateId)
    self.DifficultyId = data.DifficultyId
    self.CurrentRoundData = data
    local attackPlan = self:GetCurrentRoundData().AttackPlan
    if XTool.IsTableEmpty(attackPlan) then
        attackPlan = XGuildWarConfig.GetClientConfigValues("PlanPath" .. self.DifficultyId, "Int")
    end
    self:UpdateNodePathIndex(attackPlan)

    if difficultyChanged then
        -- 登录状态难度变更后，需要清空上个难度的节点实体数据
        self.NodeDic = {}
    else
        local wasteNodeEntities = nil
        
        for id, node in pairs(self.NodeDic) do
            -- 重置难度后, data可能不存在
            local nodeData = self:GetNodeServerData(id)
            if nodeData then
                if isRealTime then
                    node:UpdateWithServerDataRealTime(nodeData, type, updateId)
                else
                    node:UpdateWithServerData(nodeData)
                end
            else
                -- 不存在数据的节点，先锁住读写
                setmetatable(node, {
                    __index = function(tab, key)
                        local uid = rawget(tab, 'UID')
                        local id = 0
                        
                        local config = rawget(tab, 'Config')
                        
                        if config then 
                            id = config.Id
                        end
                        
                        XLog.Error('访问当前轮次不存在的节点，节点Uid：' .. tostring(uid) .. ' 节点Id: ' .. tostring(id) .. ' 读取的字段: ' .. tostring(key))
                    end,
                    
                    __newindex = function(tab, key, value)
                        local uid = rawget(tab, 'UID')
                        local id = 0

                        local config = rawget(tab, 'Config')

                        if config then
                            id = config.Id
                        end

                        XLog.Error('访问当前轮次不存在的节点，节点Uid：' .. tostring(uid) .. ' 节点Id: ' .. tostring(id) .. ' 写入的字段: ' .. tostring(key) .. '写入的值: ' .. tostring(value))
                    end
                })

                if wasteNodeEntities == nil then
                    wasteNodeEntities = {}
                end

                wasteNodeEntities[id] = node
            end
        end

        -- 未使用的节点直接移除，后面再需要访问指定node时根据服务端数据重新实例化实体对象
        if not XTool.IsTableEmpty(wasteNodeEntities) then
            for id, node in pairs(wasteNodeEntities) do
                if self.NodeDic[id] == node then
                    self.NodeDic[id] = nil
                end
            end
        end
    end
    
    
end

--更新我参与的轮次数据
-- data : XGuildWarRoundDataDb
function XGWBattleManager:UpdateMyRoundData(data)
    self.CurrentMyRoundData = data
    self.DifficultyId = data.DifficultyId
end

--更新战斗记录
-- data : List<GuildWarFightRecord>
function XGWBattleManager:UpdateFightRecords(data)
    self.FightRecords = {}
    self.LastRoundFightRecords = {}
    
    self:UpdateNewFightRecords(data)
end

--- 更新战斗记录- 增量更新 
---@param data @List<GuildWarFightRecord>
function XGWBattleManager:UpdateNewFightRecords(data)
    if not XTool.IsTableEmpty(data) then
        for i, v in pairs(data) do
            local isCurRound = v.GameThrough == self.CurrentRoundData.GameThrough

            if isCurRound then
                self.FightRecords[v.Uid] = v
                self.LastRoundFightRecords[v.Uid] = nil
            else
                self.FightRecords[v.Uid] = nil
                self.LastRoundFightRecords[v.Uid] = v
            end

        end
    end
end

-- 战斗记录内部刷新-用于登录状态周目变更
function XGWBattleManager:RefreshFightRecordsInner()
    if not XTool.IsTableEmpty(self.FightRecords) then
        for uid, data in pairs(self.FightRecords) do
            self.LastRoundFightRecords[uid] = data
        end

        for uid, data in pairs(self.LastRoundFightRecords) do
            self.FightRecords[uid] = nil
        end
    end
end

--获取当前我参与轮次的数据
function XGWBattleManager:GetCurrentMyRoundData()
    return self.CurrentMyRoundData
end

-- GuildWarRoundData
--获取当前轮次数据
function XGWBattleManager:GetCurrentRoundData()
    return self.CurrentRoundData
end

-- 当前轮次累计活跃度
function XGWBattleManager:GetTotalActivation()
    return self:GetCurrentRoundData().TotalActivation
end

-- 当前轮次累计积分
function XGWBattleManager:GetTotalPoint()
    return self:GetCurrentRoundData().TotalPoint
end

-- 获取难度ID
function XGWBattleManager:GetDifficultyId()
    return self.DifficultyId
end

-- 获取当前难度名称
function XGWBattleManager:GetDifficultyName()
    local difficultyCfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self.DifficultyId)
    return difficultyCfg and difficultyCfg.Name
end

-- 获取当前难度扫荡血量折损
function XGWBattleManager:GetSweepHpFactor()
    local difficultyCfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self.DifficultyId)
    return difficultyCfg and difficultyCfg.SweepHpFactor
end

-- 获取当前难度扫荡血量折损(带弱点的BOSS关卡)
function XGWBattleManager:GetBossSweepHpFactorWithoutWeakness()
    local difficultyCfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self.DifficultyId)
    return difficultyCfg and difficultyCfg.BossSweepHpFactor
end

-- 获取战斗日志
function XGWBattleManager:GetBattleLogs(count)
    local result = {}
    local roundData = self:GetCurrentRoundData()
    for i = #roundData.Battlelog, 1, -1 do
        local logData = roundData.Battlelog[i]
        local menberData = XDataCenter.GuildManager.GetMemberDataByPlayerId(logData.PlayerId)
        if menberData then
            local IsFightNode = logData.FightType == XGuildWarConfig.NodeFightType.FightNode
            local IsShowDeadNode = logData.IsDead > 0 and IsFightNode

            local textConfig = IsShowDeadNode and
                    XGuildWarConfig.BattleDeadNodeLogTextConfig or
                    XGuildWarConfig.BattleLogTextConfig[logData.LogType]

            local text = ""
            local fightName = ""

            if IsFightNode then
                local node = self:GetNode(logData.NodeId)
                fightName = node:GetName(false)
                text = textConfig[node:GetNodeType()] or ""
            else
                fightName = XGuildWarConfig.GetEliteMonsterConfig(logData.MonsterId).Name
                text = textConfig[XGuildWarConfig.NodeType.Normal] or ""
            end

            local logFullText = ""
            if IsShowDeadNode then
                logFullText = XUiHelper.GetText(text,(logData.Point or 0))
            else
                logFullText = XUiHelper.GetText(text,fightName,string.format("%s", (logData.DamagePercent or 0) / 10))
            end

            if logFullText == "" or not logFullText then
                print(logData)
            end

            local log = {
                Time = XTime.TimestampToGameDateTimeString(logData.CreateTime, "MM.dd HH:mm"),
                Name = menberData:GetName(),
                Text = logFullText
            }
            table.insert(result, log)
        end

        if count and #result >= count then
            return result
        end
    end
    return result
end

--更新当前客户端战斗数据
function XGWBattleManager:UpdateCurrentClientBattleInfo(uid, nodeStatus)
    self.CurrentClientBattleUID = uid
    self.CurrentClientBattleNodeStatus = nodeStatus
end

--获得当前客户端战斗UID
function XGWBattleManager:GetCurrentClientBattleUID()
    return self.CurrentClientBattleUID
end

--获得当前客户端战斗节点 状态
function XGWBattleManager:GetCurrentClientBattleNodeStatus()
    return self.CurrentClientBattleNodeStatus
end

--endregion

--region 行动动画

--region 内部接口
--更新行动动画数据
function XGWBattleManager:UpdateActionData(actionList)
    for _,action in pairs(actionList) do
        if self:CheckActionIsShowed(action.ActionId) then
            goto IGNORE_SHOWED_ACTION_UPDATE
        end
        
        if action.ActionType == XGuildWarConfig.GWActionType.MonsterDead then
            self:UpdateMonsterDead(action.MonsterUid, true)
        elseif action.ActionType == XGuildWarConfig.GWActionType.NodeDestroyed then
            self:UpdateNodeDataRealTime(action.NodeData, XGuildWarConfig.NodeDataUpdateSource.Action, action.ActionId)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
        elseif action.ActionType == XGuildWarConfig.GWActionType.AllGuardNodeDead then
            local pandaRootNode = self:GetNodePandaRoot()
            if pandaRootNode then
                pandaRootNode:UpdateNextBossAttackTime(action.NextBossAttackTime)
            end
        elseif action.ActionType == XGuildWarConfig.GWActionType.TransferWeakness then
            local fromNodeUid = action.FromNodeUid
            local fromNode = self:GetNodeByUid(fromNodeUid)
            if fromNode then
                fromNode:SetWeakness(false)
            end
            local toNodeUid = action.ToNodeUid
            local toNode = self:GetNodeByUid(toNodeUid)
            if toNode then
                toNode:SetWeakness(true)
            end
        elseif action.ActionType == XGuildWarConfig.GWActionType.BaseBeHitByBoss then
            local pandaRootNode = self:GetNodePandaRoot()
            if pandaRootNode then
                pandaRootNode:UpdateNextBossAttackTime(action.NextBossAttackTime)
            end
        elseif action.ActionType == XGuildWarConfig.GWActionType.BossMerge then
            self:UpdateNodeDatasRealTime(action.NodeDatas, XGuildWarConfig.NodeDataUpdateSource.Action, action.ActionId)
            --local node = self:GetNodeBossRoot()
            --if node then
            --    node.IsMerge = 1
            --end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
        elseif action.ActionType == XGuildWarConfig.GWActionType.BossTreatMonster then
            self:UpdateNodeData(action.NodeData)
            self:UpdateMonsterData(action.MonsterData)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
        elseif action.ActionType == XGuildWarConfig.GWActionType.MonsterBornTimeChange then
            self:UpdateNodeData(action.NodeData)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
        elseif action.ActionType == XGuildWarConfig.GWActionType.ReinforcementBorn then
            self:UpdateReinforcementsData(action.ReinforcementData)
        elseif action.ActionType == XGuildWarConfig.GWActionType.ReinforcementMove then
            self:UpdateReinforcementsData(action.ReinforcementData)
        elseif action.ActionType == XGuildWarConfig.GWActionType.ReinforcementDead then
            self:UpdateReinforcementDead(action.ReinforcementUid, true)
        elseif action.ActionType == XGuildWarConfig.GWActionType.ReinforcementAttack then
            self:UpdateReinforcementsData(action.ReinforcementData)
            self:UpdateNodeData(action.NodeData)
        end
        
        :: IGNORE_SHOWED_ACTION_UPDATE ::
    end
end

--检查是否正在播放动画
--todo 已迁移
function XGWBattleManager:CheckActionPlaying()
    return XMVCA.XGuildWar.ActionQueueAgency:CheckActionPlaying()
end

-- 检查某个动画是否已经播放
--todo 已迁移
function XGWBattleManager:CheckActionIsShowed(id)
    return XMVCA.XGuildWar.ActionQueueAgency:CheckActionIsShowed(id)
end

--endregion

-- 获取行动动画队列是否还有动画没有播放
--todo 已迁移
function XGWBattleManager:GetIsHasCanPlayAction(playTypeList)
    return XMVCA.XGuildWar.ActionQueueAgency:GetIsHasCanPlayAction(playTypeList)
end

-- 检查某UI的行动动画列表 并播放行动动画 动画播放队列根据XGuildWarConfig获取UI需要的动画和顺序
-- PlayTypeList:XGuildWarConfig.GWPlayType2Action[]
--todo 已迁移
function XGWBattleManager:CheckActionList(PlayTypeList)
    XMVCA.XGuildWar.ActionQueueAgency:CheckActionList(PlayTypeList)
end

-- 行动动画播放完毕时调用(UI调用)
-- PlayTypeList:XGuildWarConfig.GWActionType[]
--todo 已迁移
function XGWBattleManager:DoActionFinish(actionType,PlayTypeList)
    XMVCA.XGuildWar.ActionQueueAgency:DoActionFinish(actionType,PlayTypeList)
end

--endregion

--region 战场节点

--- 更新节点，除了登录等全量下推以外的实时更新
function XGWBattleManager:UpdateNodeDataRealTime(data, type, id)
    local node = self:GetNode(data.NodeId)
    node:UpdateWithServerDataRealTime(data, type, id)
end

--更新节点数据
-- data : XGuildWarNodeData
function XGWBattleManager:UpdateNodeData(data)
    local node = self:GetNode(data.NodeId)
    node:UpdateWithServerData(data)
end

--批量更新节点数据
-- datas : XGuildWarNodeData[]
function XGWBattleManager:UpdateNodeDatasRealTime(datas, type, id)
    for _, data in ipairs(datas) do
        self:UpdateNodeDataRealTime(data, type, id)
    end
end


--批量更新节点数据
-- datas : XGuildWarNodeData[]
function XGWBattleManager:UpdateNodeDatas(datas)
    for _, data in ipairs(datas) do
        self:UpdateNodeData(data)
    end
end

-- 获取节点服务器数据
function XGWBattleManager:GetNodeServerData(id)
    local currentRoundData = self:GetCurrentRoundData()
    if currentRoundData == nil then return nil end
    for _, nodeData in ipairs(currentRoundData.NodeData) do
        if nodeData.NodeId == id then
            return nodeData
        end
    end
end

--获取节点
---@return XGWNode
function XGWBattleManager:GetNode(id, notips)
    if not XTool.IsNumberValidEx(id) then
        if not notips then
            XLog.Error('错误的节点Id: ' .. tostring(id))
        end
        return
    end
    
    local result = self.NodeDic[id]
    if result == nil then
        result = CreateNode(id)
        local serverData = self:GetNodeServerData(id)
        if serverData then
            result:UpdateWithServerData(serverData)
        elseif not notips then
            XLog.Error(string.format( "找不到%s节点的服务器数据", id))
        end
        self.NodeDic[id] = result
    end
    return result
end

-- 获取当前节点id
function XGWBattleManager:GetCurrentNodeId()
    if self:GetCurrentMyRoundData() == nil then
        return 1
    end
    return self:GetCurrentMyRoundData().CurNodeId
end

-- 更新当前节点id
function XGWBattleManager:UpdateCurrentNodeId(value)
    self:GetCurrentMyRoundData().CurNodeId = value
end

-- 获取所有节点
---@return XGWNode[]
function XGWBattleManager:GetNodes()
    local result = {}
    local nodeIds = XGuildWarConfig.GetNodeIdsByDifficultyId(self.DifficultyId)
    for _, nodeId in ipairs(nodeIds) do
        local node = self:GetNode(nodeId)
        table.insert(result, node)
    end
    return result
end

-- 获取BOSS节点
function XGWBattleManager:GetBossNode()
    local nodeIds = XGuildWarConfig.GetNodeIdsByDifficultyId(self.DifficultyId)
    for _, nodeId in ipairs(nodeIds) do
        local node = self:GetNode(nodeId)
        if XGuildWarConfig.BossNodeType[node:GetNodeType()] then
            return node
        end
    end
    return nil
end

--- 获取基地节点
function XGWBattleManager:GetHomeNodeId()
    local nodeIds = XGuildWarConfig.GetNodeIdsByDifficultyId(self.DifficultyId)
    for _, nodeId in ipairs(nodeIds) do
        local node = self:GetNode(nodeId)
        if node:GetIsBaseNode() then
            return nodeId
        end
    end
    return nil
end

-- 获取所有在大地图上显示的节点数据
function XGWBattleManager:GetMainMapNodes()
    local result = {}
    local nodeIds = XGuildWarConfig.GetNodeIdsByDifficultyId(self.DifficultyId)
    for _, nodeId in ipairs(nodeIds) do
        local node = self:GetNode(nodeId)
        -- 隐藏不在大地图上显示的节点
        if not HashSetInvisibleMapNodeType[node:GetNodeType()] then
            table.insert(result, node)
        end
    end
    return result
end

-- 获取所有buff节点，默认是已经激活的
function XGWBattleManager:GetBuffNodes()
    local result = {}
    for _, node in ipairs(self:GetNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Buff or node:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            if node:GetIsActiveBuff() then
                table.insert(result, node)
            end
        end
    end
    return result
end

--region 伏兵、怪物相关
-- 获取所有怪物字典，key为UID
function XGWBattleManager:GetMonsterDic()
    local roundData = self:GetCurrentRoundData()
    local monster = nil
    local monsterUnRemoveDic = {}
    if roundData == nil then
        return {}
    end
    for _, monsterData in pairs(roundData.MonsterData) do
        monsterUnRemoveDic[monsterData.Uid] = true
        monster = self.MonsterDic[monsterData.Uid]
        if monster == nil then
            monster = XGWEliteMonster.New(monsterData.MonsterId)
        end
        monster:UpdateWithServerData(monsterData)
        self.MonsterDic[monsterData.Uid] = monster
    end
    -- 删除冗余的怪物数据
    for uid, _ in pairs(self.MonsterDic) do
        if not monsterUnRemoveDic[uid] then
            self.MonsterDic[uid] = nil
        end
    end
    return self.MonsterDic
end

-- 根据节点id获取怪物数据
function XGWBattleManager:GetMonstersByNodeId(id, checkIsDead)
    if checkIsDead == nil then checkIsDead = true end
    local result = {}
    for _, v in pairs(self:GetMonsterDic()) do
        if v:GetCurrentNodeId() == id then
            if not checkIsDead or not v:GetIsDead() then
                table.insert(result, v)
            end
        end
    end
    return result
end

-- 根据节点id获取怪物数据
function XGWBattleManager:GetMonsterById(uid)
    local monster = self:GetMonsterDic()[uid]
    if not monster then
        XLog.Error(string.format( "服务器下发不存在的怪物Uid : %s", uid))
        return
    end
    return monster
end

-- 更新节点路径(计划进攻路线)索引
function XGWBattleManager:UpdateNodePathIndex(pathNodeIds)
    self.NodeId2PathIndex = {}
    self.NodePlanPathList = {}
    for index, id in ipairs(pathNodeIds or {}) do
        self.NodeId2PathIndex[id] = index
        table.insert(self.NodePlanPathList,id)
    end
end

-- 获取节点路径(计划进攻路线)索引
function XGWBattleManager:GetNodePathIndex(nodeId)
    return self.NodeId2PathIndex[nodeId]
end

-- 获取计划进攻路线
function XGWBattleManager:GetNodePlanPathList()
    return self.NodePlanPathList
end

-- 根据节点UID或者精英怪UID获取最高伤害
function XGWBattleManager:GetMaxDamageByUID(uid, aliveType)
    if XTool.IsTableEmpty(self.FightRecords) then
        return 0
    end
    
    local data = self.FightRecords[uid]

    if data then
        if aliveType == nil then
            return data.MaxDamage
        elseif data.AliveType == aliveType then
            return data.MaxDamage
        end
    end

    return 0
end

-- 根据节点UID或者精英怪UID获取上次的最高伤害
function XGWBattleManager:GetLastRoundMaxDamageByUID(uid, aliveType)
    if XTool.IsTableEmpty(self.LastRoundFightRecords) then
        return 0
    end

    local data = self.LastRoundFightRecords[uid]

    if data then
        if aliveType == nil then
            return data.MaxDamage
        elseif data.AliveType == aliveType then
            return data.MaxDamage
        end
    end

    return 0
end

--战场 更新精英怪数据
function XGWBattleManager:UpdateMonsterData(data)
    local roundData = self:GetCurrentRoundData()
    local monsterData
    for i = #roundData.MonsterData, 1, -1 do
        monsterData = roundData.MonsterData[i]
        if monsterData.Uid == data.Uid then
            roundData.MonsterData[i] = data
            break
        end
    end
end

-- 更新精英怪死亡
function XGWBattleManager:UpdateMonsterDead(uid, IsDead)
    --更新回合数据
    local roundData = self:GetCurrentRoundData()
    local monsterData
    for i = #roundData.MonsterData, 1, -1 do
        monsterData = roundData.MonsterData[i]
        if monsterData.Uid == uid then
            local chp = roundData.MonsterData[i].CurHp
            roundData.MonsterData[i].CurHp = IsDead and 0 or (chp > 0 and chp or 1)
            break
        end
    end
    --更新entity数据
    local monster = self:GetMonsterDic()[uid]
    if not monster then
        XLog.Error(string.format( "服务器下发不存在的怪物Uid : %s", uid))
        return
    end
    monster:UpdateDead(IsDead)
end

-- 获取预创建精英怪列表
function XGWBattleManager:GetPreMonsterDataDic()--只需拿出第一回合所有需要预创建的怪物就好，后面回合用到的怪物要么是出生的，要么是前面回合遗留下来的。
    local preMonsterDataDic = {}

    for _,action in pairs(self.ActionList or {}) do
        if not self:CheckActionIsShowed(action.ActionId) then
            if action.ActionType == XGuildWarConfig.GWActionType.MonsterDead then
                if not preMonsterDataDic[action.MonsterUid] then
                    local data = {UID = action.MonsterUid, NodeIndex = action.CurNodeIdx}
                    preMonsterDataDic[action.MonsterUid] = data
                end
            elseif action.ActionType == XGuildWarConfig.GWActionType.MonsterMove then
                if not preMonsterDataDic[action.MonsterUid] then
                    local data = {UID = action.MonsterUid, NodeIndex = action.PreNodeIdx}
                    preMonsterDataDic[action.MonsterUid] = data
                end
            end
        end
    end

    for _,action in pairs(self.ActionList or {}) do
        if not self:CheckActionIsShowed(action.ActionId) then
            if action.ActionType == XGuildWarConfig.GWActionType.MonsterBorn then
                if preMonsterDataDic[action.MonsterUid] then
                    preMonsterDataDic[action.MonsterUid] = nil
                end
            end
        end
    end

    return preMonsterDataDic
end

--endregion

--region 援军相关
function XGWBattleManager:GetPreReinforcementDataDic()
    local preReinforcementDataDic = {}

    if not XTool.IsTableEmpty(self.ActionList) then
        -- 移动和死亡的需要先生成在指定位置，取最新
        for i = #self.ActionList, 1, -1 do
            local action = self.ActionList[i]

            if not self:CheckActionIsShowed(action.ActionId) then
                if action.ActionType == XGuildWarConfig.GWActionType.ReinforcementDead then
                    if not preReinforcementDataDic[action.ReinforcementUid] then
                        local data = {UID = action.ReinforcementUid, NodeId = action.NodeId}
                        preReinforcementDataDic[action.ReinforcementUid] = data
                    end
                elseif action.ActionType == XGuildWarConfig.GWActionType.ReinforcementMove then
                    if not preReinforcementDataDic[action.ReinforcementUid] then
                        local data = {UID = action.ReinforcementUid, NodeId = action.PreNodeId}
                        preReinforcementDataDic[action.ReinforcementUid] = data
                    end
                end
            end
        end
        
        -- 如果有出生动画，则出生动画控制它的初次位置显示，需要移除掉预加载
        for i = #self.ActionList, 1, -1 do
            local action = self.ActionList[i]
            if not self:CheckActionIsShowed(action.ActionId) then
                if action.ActionType == XGuildWarConfig.GWActionType.ReinforcementBorn then
                    if preReinforcementDataDic[action.ReinforcementUid] then
                        preReinforcementDataDic[action.ReinforcementUid] = nil
                    end
                end
            end
        end
    end

    return preReinforcementDataDic
end

-- 获取所有援军字典，key为UID
function XGWBattleManager:GetReinforcementsDic()
    local roundData = self:GetCurrentRoundData()
    local reinforcements = nil
    local reinforcementsUnRemoveDic = {}
    if roundData == nil then
        return {}
    end
    if not XTool.IsTableEmpty(roundData.ReinforcementData) then
        for _, reinforcementsData in pairs(roundData.ReinforcementData) do
            reinforcementsUnRemoveDic[reinforcementsData.Uid] = true
            reinforcements = self.ReinforcementDic[reinforcementsData.Uid]
            if reinforcements == nil then
                reinforcements = XGWReinforcements.New(reinforcementsData.ReinforcementId)
            end
            reinforcements:UpdateWithServerData(reinforcementsData)
            self.ReinforcementDic[reinforcementsData.Uid] = reinforcements
        end
    end
    -- 删除冗余的怪物数据
    for uid, _ in pairs(self.ReinforcementDic) do
        if not reinforcementsUnRemoveDic[uid] then
            self.ReinforcementDic[uid] = nil
        end
    end
    return self.ReinforcementDic
end

-- 根据节点id获取怪物数据
function XGWBattleManager:GetReinforcementById(uid)
    local reinforcement = self:GetReinforcementsDic()[uid]
    if not reinforcement then
        XLog.Error(string.format( "服务器下发不存在的援军Uid : %s", uid))
        return
    end
    return reinforcement
end

--战场 更新援军数据
function XGWBattleManager:UpdateReinforcementsData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    local isUpdate = false
    local roundData = self:GetCurrentRoundData()
    local reinforcements
    for i = #roundData.ReinforcementData, 1, -1 do
        reinforcements = roundData.ReinforcementData[i]
        if reinforcements.Uid == data.Uid then
            roundData.ReinforcementData[i] = data
            isUpdate = true
            break
        end
    end

    if not isUpdate then
        -- 新数据，直接插入
        table.insert(roundData.ReinforcementData, data)
    end
end

-- 更新援军死亡
function XGWBattleManager:UpdateReinforcementDead(uid, IsDead)
    --更新回合数据
    local roundData = self:GetCurrentRoundData()
    local reinforcementsData
    for i = #roundData.ReinforcementData, 1, -1 do
        reinforcementsData = roundData.ReinforcementData[i]
        if reinforcementsData.Uid == uid then
            local chp = roundData.ReinforcementData[i].CurHp
            roundData.ReinforcementData[i].CurHp = IsDead and 0 or (chp > 0 and chp or 1)
            break
        end
    end
    --更新entity数据
    local reinforcement = self:GetReinforcementsDic()[uid]
    if not reinforcement then
        XLog.Error(string.format( "服务器下发不存在的怪物Uid : %s", uid))
        return
    end
    reinforcement:UpdateDead(IsDead)
end

--endregion

--检查是否完成区域
function XGWBattleManager:CheckAllInfectIsDead()
    for _, node in ipairs(self:GetMainMapNodes()) do
        if node:GetIsLastNode() then
            if not node:GetIsDead() then
                return false
            end
        end
    end
    return true
end

--获取是否所有守卫节点都被歼灭
function XGWBattleManager:GetAllGuardIsDead()
    for _, node in pairs(self.NodeDic) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Guard
                and not node:GetIsDead() then
            return false
        end
    end
    return true
end

--获取黑白鲨根节点
function XGWBattleManager:GetNodePandaRoot()
    for _, node in pairs(self.NodeDic) do
        if node:GetIsPandaRootNode() then
            return node
        end
    end
    return false
end

--获取BOSS根节点
function XGWBattleManager:GetNodeBossRoot()
    for _, node in pairs(self.NodeDic) do
        if node:GetIsLastNode() then
            return node
        end
    end
    return false
end

--通过stageId寻找节点
function XGWBattleManager:FindNodeByStage(stageId)
    for _, node in pairs(self.NodeDic) do
        if node:GetStageId() == stageId then
            return node
        end
    end
    return false
end

--根据节点的UI获取节点
---@return XGWNode
function XGWBattleManager:GetNodeByUid(uid)
    for _, node in pairs(self.NodeDic) do
        if node:GetUID() == uid then
            return node
        end
    end
    return false
end
--endregion

--region 多区域挑战节点
--更新多区域节点数据
function XGWBattleManager:UpdateAreaTeamNodeInfos(areaTeamInfos, recordTeamInfos)
    for _,info in ipairs(areaTeamInfos) do
        local node = self:GetNode(info.NodeId)
        if node then node:UpdateAreaTeamNodeInfo(info) end
    end
    for _,info in ipairs(recordTeamInfos) do
        local node = self:GetNode(info.NodeId)
        if node then node:UpdateAreaTeamRecordInfo(info) end
    end
end

--重置区域分数(本地 只在请求服务器修改 服务器不更新时 才本地自己更新)
function XGWBattleManager:ResetAreaTeamNodeCurPoint(childNodeId)
    self:GetNode(childNodeId):ResetCurPoint()
end

--上传后更新区域分数记录(本地 只在请求服务器修改 服务器不更新时 才本地自己更新)
function XGWBattleManager:UploadAreaTeamNodeRecord(childNodeId)
    local node = self:GetNode(childNodeId)
    local record = node:GetScore()
    node:ResetCurPoint()
    node:UpdateRecord(record)
end
--endregion

--region 机器人Robot(系统已废弃)
--根据角色类型 获取当前难度配置的RobotId( 配置是空的 不知道是什么)
function XGWBattleManager:GetRobots(characterType)
    local robotIds = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self:GetDifficultyId()).RobotId
    local result = {}
    local characterId = nil
    local robotCharacterType
    for _, id in ipairs(robotIds) do
        robotCharacterType = XEntityHelper.GetRobotCharacterType(id)
        if characterType == nil then
            table.insert(result, XRobotManager.GetRobotById(id))
        elseif characterType == robotCharacterType then
            table.insert(result, XRobotManager.GetRobotById(id))
        end
    end
    return result
end
--endregion

---@return XGuildWarTeam
--获取当前难度战斗队伍
function XGWBattleManager:GetTeam()
    if self.__Team == nil then
        local id = "XGWBattleManager" .. self:GetDifficultyId() 
        self.__Team = require("XUi/XUiGuildWar/Assistant/XGuildWarTeam").New(id)
        XDataCenter.TeamManager.SetXTeam(self.__Team)
    end

    return self.__Team
end

--打开战斗房间UI(打开前会请求助战列表)
function XGWBattleManager:OpenBattleRoomUi(stageId)
    XDataCenter.GuildWarManager.RequestAssistCharacterList(function()
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, self:GetTeam(), require("XUi/XUiGuildWar/XUiGuildWarBattleRoleRoom"))
    end)
end

--获取当前我参与轮次的数据
function XGWBattleManager:GetCurrentMyRoundRewardReceived()
    return self.CurrentMyRoundData.GetBossRewards
end

function XGWBattleManager:IsRewardReceived(id)
    if not self.CurrentMyRoundData then
        return false
    end
    local getRewards = self.CurrentMyRoundData.GetBossRewards
    for i = 1, #getRewards do
        if getRewards[i] == id then
            return true
        end
    end
    return false
end

function XGWBattleManager:AddRewardReceived(id)
    if not self.CurrentMyRoundData then
        return false
    end
    local getRewards = self.CurrentMyRoundData.GetBossRewards
    getRewards[#getRewards + 1] = id
end

return XGWBattleManager

