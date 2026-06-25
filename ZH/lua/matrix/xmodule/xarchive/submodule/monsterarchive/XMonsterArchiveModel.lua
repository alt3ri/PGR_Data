---@class XMonsterArchiveModel: XModel
---@field _MainModel XArchiveModel
local XMonsterArchiveModel = XClass(XModel, 'XMonsterArchiveModel')

local MonsterClientTableKey = {
    MonsterNpcData     = {DirPath = XConfigUtil.DirectoryType.Client}, -- 冷路径，但被XUiFubenMaverickPopup等外部系统引用，暂不改Private
    MonsterEffect      = {DirPath = XConfigUtil.DirectoryType.Client}, -- 冷路径，但被XFightNpcLogic等外部系统引用，暂不改Private
    MonsterInfoInner   = {DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    MonsterSettingInner = {DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    ArchiveMonsterInner = {DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
}

local MonsterShareTableKey = {
    MonsterSetting = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll },
    SameNpcGroup   = {DirPath = XConfigUtil.DirectoryType.Share},
}

local MonsterTablePath = {
    TABLE_MONSTER      = "Share/Archive/Monster.tab",
    TABLE_MONSTERINFO  = "Share/Archive/MonsterInfo.tab",
    TABLE_MONSTERSKILL = "Share/Archive/MonsterSkill.tab",
}

--region 内部方法

-- 热路径：仅建立 NpcId → MonsterId 映射，不创建 Entity
---@param model XMonsterArchiveModel
local InitNpcToMonster = function(model)
    local monsterList = model:GetMonster()
    if not XTool.IsTableEmpty(monsterList) then
        for _, monster in pairs(monsterList) do
            if not XTool.IsTableEmpty(monster.NpcId) then
                for _, id in pairs(monster.NpcId) do
                    model._ArchiveNpcToMonster[id] = monster.Id
                end
            end
        end
    end
end

-- 冷路径：创建 XArchiveMonsterEntity，填充 _ArchiveMonsterList / _ArchiveMonsterData
-- 并将热路径已累计的 Kill/IsLockMain 同步写入 Entity
---@param model XMonsterArchiveModel
local InitMonsterEntities = function(model)
    local XArchiveMonsterEntity = require("XEntity/XArchive/XArchiveMonsterEntity")
    local monsterList = model:GetMonster()
    if not XTool.IsTableEmpty(monsterList) then
        for _, monster in pairs(monsterList) do
            if not model._ArchiveMonsterList[monster.Type] then
                model._ArchiveMonsterList[monster.Type] = {}
            end
            local tmp = XArchiveMonsterEntity.New(monster.Id)
            table.insert(model._ArchiveMonsterList[monster.Type], tmp)
        end
    end
    for _, list in pairs(model._ArchiveMonsterList) do
        model._MainModel:SortByOrder(list)
        for _, monster in pairs(list) do
            model._ArchiveMonsterData[monster:GetId()] = monster
        end
    end
    -- 将热路径已有的击杀数和解锁状态同步到 Entity
    local killCountDic = model._MonsterKillCount
    if not XTool.IsTableEmpty(killCountDic) then
        if XTool.IsTableEmpty(model._ArchiveNpcToMonster) then
            InitNpcToMonster(model)
        end
        local npcToMonster = model._ArchiveNpcToMonster
        -- 先按 monsterId 聚合所有 sameNpcId 的击杀数，避免多次 UpdateData 覆盖 Kill 字段
        local monsterKillMap = {}
        for sameNpcId, count in pairs(killCountDic) do
            local monsterId = npcToMonster[sameNpcId]
            if monsterId and model._ArchiveMonsterData[monsterId] then
                if not monsterKillMap[monsterId] then
                    monsterKillMap[monsterId] = {}
                end
                monsterKillMap[monsterId][sameNpcId] = count
            end
        end
        for monsterId, killMap in pairs(monsterKillMap) do
            model._ArchiveMonsterData[monsterId]:UpdateData({ IsLockMain = false, Kill = killMap })
        end
    end
end

-- 建立 Detail 配置索引：GroupId(npcId) → [type →] [cfg, ...]
-- isHaveType: Info/Setting 有 Type 子分类；Skill 没有
local BuildDetailCfgIndex = function(detailCfg, indexTable, isHaveType)
    if XTool.IsTableEmpty(detailCfg) then return end
    for _, cfg in pairs(detailCfg) do
        local groupId = cfg.GroupId
        if not indexTable[groupId] then
            indexTable[groupId] = {}
        end
        if isHaveType then
            if not indexTable[groupId][cfg.Type] then
                indexTable[groupId][cfg.Type] = {}
            end
            table.insert(indexTable[groupId][cfg.Type], cfg)
        else
            table.insert(indexTable[groupId], cfg)
        end
    end
end

-- 冷路径：创建 XArchiveMonsterDetailEntity，应用热路径已计算的 IsLock/LockDesc 缓存
---@param model XMonsterArchiveModel
local InitArchiveMonsterDetail = function(model, entityType, detailCfg, allList, lockStateTable, entityDataTable, isHaveType)
    local XArchiveMonsterDetailEntity = require("XEntity/XArchive/XArchiveMonsterDetailEntity")

    if not XTool.IsTableEmpty(detailCfg) then
        for _, detail in pairs(detailCfg) do
            if not allList[detail.GroupId] then
                allList[detail.GroupId] = {}
            end
            if isHaveType and not allList[detail.GroupId][detail.Type] then
                allList[detail.GroupId][detail.Type] = {}
            end
            local tmp = XArchiveMonsterDetailEntity.New(entityType, detail.Id)
            -- 应用热路径已计算的 IsLock；LockDesc 就地重算（条件不变，结果幂等）
            local isLock = lockStateTable[detail.Id]
            if isLock ~= nil then
                tmp.IsLock = isLock
                if isLock and detail.Condition ~= 0 then
                    _, tmp.LockDesc = XConditionManager.CheckCondition(detail.Condition, detail.GroupId)
                end
            end
            entityDataTable[detail.Id] = tmp
            if isHaveType then
                table.insert(allList[detail.GroupId][detail.Type], tmp)
            else
                table.insert(allList[detail.GroupId], tmp)
            end
        end
    end

    for _, group in pairs(allList) do
        if isHaveType then
            for _, type in pairs(group) do
                model._MainModel:SortByOrder(type)
            end
        else
            model._MainModel:SortByOrder(group)
        end
    end
end
--endregion

function XMonsterArchiveModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey('Archive', MonsterClientTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('Archive', MonsterShareTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfig({
        [MonsterTablePath.TABLE_MONSTER]      = {XConfigUtil.ReadType.IntAll, XTable.XTableArchiveMonster,      "Id", XConfigUtil.CacheType.Normal},
        [MonsterTablePath.TABLE_MONSTERINFO]  = {XConfigUtil.ReadType.IntAll, XTable.XTableArchiveMonsterInfo,  "Id", XConfigUtil.CacheType.Normal},
        [MonsterTablePath.TABLE_MONSTERSKILL] = {XConfigUtil.ReadType.Int, XTable.XTableArchiveMonsterSkill, "Id", XConfigUtil.CacheType.Normal},
    })
    self:ResetData()
end

function XMonsterArchiveModel:ClearPrivate()

end

function XMonsterArchiveModel:ResetAll()
    self:ResetData()
    self:ResetMonsterData()
end

function XMonsterArchiveModel:ResetData()
    -- 服务端原始数据列表转字典
    self._ArchiveShowedMonsterList = {}

    -- 服务端原始数据列表转集合
    self._ArchiveMonsterUnlockIdsList = {}
    self._ArchiveMonsterInfoUnlockIdsList = {}
    self._ArchiveMonsterSkillUnlockIdsList = {}
    self._ArchiveMonsterSettingUnlockIdsList = {}

    -- 红点数据
    self._MonsterRedPointDic = {}

    -- 配置表二次数据
    self._ArchiveMonsterList = {}
    self._ArchiveMonsterData = {}
    self._ArchiveNpcToMonster = {}
    self._ArchiveSameNpc = {}
    self._ArchiveMonsterInfoList = {}
    self._ArchiveMonsterSkillList = {}
    self._ArchiveMonsterSettingList = {}
    self._ArchiveMonsterEffectDatasDic = {}

    -- 热路径：击杀数（sameNpcId → killCount），不依赖 Entity
    self._MonsterKillCount = {}

    -- 热路径：Detail 配置索引，GroupId(npcId) → [Type →] {cfg, ...}（不创建 Entity）
    self._MonsterInfoCfgIndex    = {}
    self._MonsterSkillCfgIndex   = {}
    self._MonsterSettingCfgIndex = {}

    -- 热路径：Detail 解锁状态缓存，id → { IsLock, LockDesc }（供冷路径 Entity 创建时同步）
    self._MonsterInfoLockState    = {}
    self._MonsterSkillLockState   = {}
    self._MonsterSettingLockState = {}

    -- 冷路径：Detail Entity 字典，id → entity（供热路径杀推后同步 Entity.IsLock）
    self._MonsterInfoEntityData    = {}
    self._MonsterSkillEntityData   = {}
    self._MonsterSettingEntityData = {}

    -- 封装数据
    self._ArchiveMonsterMySelfEvaluateList = {}
    self._ArchiveMonsterEvaluateList = {}
    self._LastSyncMonsterEvaluateTimes = {}
end

--region 服务端数据更新

function XMonsterArchiveModel:SetArchiveShowedMonsterList(list)
    if not XTool.IsTableEmpty(list) then
        for _,monster in pairs(list) do
            self._ArchiveShowedMonsterList[monster.Id] = monster
        end
    end
end

function XMonsterArchiveModel:AddArchiveShowedMonsterList(list)
    if not XTool.IsTableEmpty(list) then
        for _,monster in pairs(list) do
            if not self._ArchiveShowedMonsterList[monster] then
                self._ArchiveShowedMonsterList[monster.Id] = monster
            else
                self._ArchiveShowedMonsterList[monster.Id].Killed = monster.Killed
            end
        end
    end
end

function XMonsterArchiveModel:SetArchiveMonsterUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterUnlockIdsList[id] = true
    end
end

function XMonsterArchiveModel:SetArchiveMonsterInfoUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterInfoUnlockIdsList[id] = true
    end
end

function XMonsterArchiveModel:SetArchiveMonsterSkillUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterSkillUnlockIdsList[id] = true
    end
end

function XMonsterArchiveModel:SetArchiveMonsterSettingUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterSettingUnlockIdsList[id] = true
    end
end

--endregion

--region 封装数据

--region setter
function XMonsterArchiveModel:ResetMonsterData()
    self._MonsterKillCount = {}
    -- 直接访问内部字段，不触发懒加载冷路径
    if not XTool.IsTableEmpty(self._ArchiveMonsterData) then
        for _, v in pairs(self._ArchiveMonsterData) do
            v:Reset()
        end
    end
end

function XMonsterArchiveModel:SetMonsterKillCount(sameNpcId, count)
    self._MonsterKillCount[sameNpcId] = count
end

function XMonsterArchiveModel:GetMonsterKillCount(sameNpcId)
    return self._MonsterKillCount[sameNpcId] or 0
end

function XMonsterArchiveModel:GetMonsterKillCountDic()
    return self._MonsterKillCount
end

-- 热路径：按 GroupId(npcId) 获取 Info 配置列表，按 Type 分组
-- 返回 table[type][i] = cfg
function XMonsterArchiveModel:GetMonsterInfoCfgsByNpcId(npcId)
    if XTool.IsTableEmpty(self._MonsterInfoCfgIndex) then
        BuildDetailCfgIndex(self:GetMonsterInfo(), self._MonsterInfoCfgIndex, true)
    end
    return self._MonsterInfoCfgIndex[npcId]
end

-- 热路径：按 GroupId(npcId) 获取 Skill 配置列表
-- 返回 table[i] = cfg
function XMonsterArchiveModel:GetMonsterSkillCfgsByNpcId(npcId)
    if XTool.IsTableEmpty(self._MonsterSkillCfgIndex) then
        BuildDetailCfgIndex(self:GetMonsterSkill(), self._MonsterSkillCfgIndex, false)
    end
    return self._MonsterSkillCfgIndex[npcId]
end

-- 热路径：按 GroupId(npcId) 获取 Setting 配置列表，按 Type 分组
-- 返回 table[type][i] = cfg
function XMonsterArchiveModel:GetMonsterSettingCfgsByNpcId(npcId)
    if XTool.IsTableEmpty(self._MonsterSettingCfgIndex) then
        BuildDetailCfgIndex(self:GetMonsterSetting(), self._MonsterSettingCfgIndex, true)
    end
    return self._MonsterSettingCfgIndex[npcId]
end

-- 写入 Detail IsLock 状态缓存；若 Entity 已创建则同步写入
function XMonsterArchiveModel:SetMonsterInfoLockState(id, isLock, lockDesc)
    self._MonsterInfoLockState[id] = isLock
    local entity = self._MonsterInfoEntityData[id]
    if entity then
        entity.IsLock   = isLock
        entity.LockDesc = lockDesc
    end
end

function XMonsterArchiveModel:SetMonsterSkillLockState(id, isLock, lockDesc)
    self._MonsterSkillLockState[id] = isLock
    local entity = self._MonsterSkillEntityData[id]
    if entity then
        entity.IsLock   = isLock
        entity.LockDesc = lockDesc
    end
end

function XMonsterArchiveModel:SetMonsterSettingLockState(id, isLock, lockDesc)
    self._MonsterSettingLockState[id] = isLock
    local entity = self._MonsterSettingEntityData[id]
    if entity then
        entity.IsLock   = isLock
        entity.LockDesc = lockDesc
    end
end

function XMonsterArchiveModel:SetArchiveMonsterMySelfEvaluateLikeStatus(npcId,likeState)
    if not self._ArchiveMonsterMySelfEvaluateList[npcId] then
        self._ArchiveMonsterMySelfEvaluateList[npcId] ={}
    end
    self._ArchiveMonsterMySelfEvaluateList[npcId].LikeStatus = likeState
end

function XMonsterArchiveModel:SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
    if not self._ArchiveMonsterMySelfEvaluateList[npcId] then
        self._ArchiveMonsterMySelfEvaluateList[npcId] ={}
    end
    self._ArchiveMonsterMySelfEvaluateList[npcId].Score = score
    self._ArchiveMonsterMySelfEvaluateList[npcId].Difficulty = difficulty
    self._ArchiveMonsterMySelfEvaluateList[npcId].Tags = tags
end

function XMonsterArchiveModel:SetMonsterEvaluateInListById(id,entity)
    self._ArchiveMonsterEvaluateList[id] = entity
end

function XMonsterArchiveModel:SetMonsterMySelfEvaluateInListById(id,entity)
    self._ArchiveMonsterMySelfEvaluateList[id] = entity
end

function XMonsterArchiveModel:SetLastSyncMonsterEvaluateTimeById(monsterId,timestamp)
    self._LastSyncMonsterEvaluateTimes[monsterId] = timestamp
end
--endregion

--region getter
function XMonsterArchiveModel:GetArchiveMonsterEvaluate(npcId)
    return self._ArchiveMonsterEvaluateList[npcId]
end

function XMonsterArchiveModel:GetArchiveMonsterMySelfEvaluate(npcId)
    return self._ArchiveMonsterMySelfEvaluateList[npcId]
end

function XMonsterArchiveModel:GetArchiveMonsterEvaluateList()
    return self._ArchiveMonsterEvaluateList
end

function XMonsterArchiveModel:GetArchiveMonsterMySelfEvaluateList()
    return self._ArchiveMonsterMySelfEvaluateList
end

--批量未解锁怪物id数据获取整体逻辑在Model，减少方法调用次数
function XMonsterArchiveModel:GetLockMonsterIdsFromIdList(ids)
    local list={}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterUnlockIdsList[id] then
                table.insert(list,id)
            end
        end
    end
    return list
end

--批量未解锁怪物信息id数据获取整体逻辑在Model，减少方法调用次数
function XMonsterArchiveModel:GetLockMonsterInfoIdsFromIdList(ids)
    local list={}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterInfoUnlockIdsList[id] then
                table.insert(list,id)
            end
        end
    end
    return list
end

function XMonsterArchiveModel:GetLockMonsterSkillIdsFromIdList(ids)
    local list = {}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterSkillUnlockIdsList[id] then
                table.insert(list,id)
            end
        end
    end
    return list
end

function XMonsterArchiveModel:GetLockMonsterSettingIdsFromIdList(ids)
    local list = {}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterSettingUnlockIdsList[id] then
                table.insert(list,id)
            end
        end
    end
    return list
end

function XMonsterArchiveModel:GetShowedMonsterList()
    return self._ArchiveShowedMonsterList
end

function XMonsterArchiveModel:GetMonsterUnlockById(id)
    return self._ArchiveMonsterUnlockIdsList[id]
end

--- 热路径：不触发 Entity 懒加载，直接用配置表 + 热数据统计怪物完成度
--- @param monsterType number|nil  nil = 所有类型
--- @return number unlockCount, number totalCount
function XMonsterArchiveModel:GetMonsterCompletionCount(monsterType)
    local monsterCfgs = self:GetMonster()
    local total, unlocked = 0, 0
    for _, cfg in pairs(monsterCfgs) do
        if not monsterType or cfg.Type == monsterType then
            total = total + 1
        end
    end
    local npcToMonster = self:GetArchiveNpcToMonster()
    local unlockedIds = {}
    for _, showedMonster in pairs(self._ArchiveShowedMonsterList) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = npcToMonster[sameNpcId]
        if monsterId and not unlockedIds[monsterId] then
            local monsterCfg = monsterCfgs[monsterId]
            if monsterCfg and (not monsterType or monsterCfg.Type == monsterType) then
                unlockedIds[monsterId] = true
                unlocked = unlocked + 1
            end
        end
    end
    return unlocked, total
end

function XMonsterArchiveModel:GetLastSyncMonsterEvaluateTimeById(monsterId)
    return self._LastSyncMonsterEvaluateTimes[monsterId]
end
--endregion

--endregion

--region 二次配置数据

function XMonsterArchiveModel:GetArchiveMonsterData()
    if XTool.IsTableEmpty(self._ArchiveMonsterData) then
        InitMonsterEntities(self)
    end
    return self._ArchiveMonsterData
end

-- 不触发懒加载，直接返回内部字段（供热路径判断 Entity 是否已创建）
function XMonsterArchiveModel:GetRawMonsterData()
    return self._ArchiveMonsterData
end

function XMonsterArchiveModel:GetArchiveNpcToMonster()
    if XTool.IsTableEmpty(self._ArchiveNpcToMonster) then
        InitNpcToMonster(self)
    end
    return self._ArchiveNpcToMonster
end

function XMonsterArchiveModel:GetArchiveMonsterList()
    if XTool.IsTableEmpty(self._ArchiveMonsterList) then
        InitMonsterEntities(self)
    end
    return self._ArchiveMonsterList
end

function XMonsterArchiveModel:GetSameNpcId(npcId)
    local data = self:GetSameNpc()
    return data[npcId] and data[npcId] or npcId
end

function XMonsterArchiveModel:GetSameNpc()
    if XTool.IsTableEmpty(self._ArchiveSameNpc) then
        local sameNpcGroup = self:GetSameNpcGroup()
        if not XTool.IsTableEmpty(sameNpcGroup) then
            for _, group in pairs(sameNpcGroup) do
                for _, npcId in pairs(group.NpcId) do
                    self._ArchiveSameNpc[npcId] = group.Id
                end
            end
        end
    end
    return self._ArchiveSameNpc
end

--- 怪物在图鉴主界面是否解锁
function XMonsterArchiveModel:GetMonsterUnlockMainById(id)
    local typeToMonsters = self:GetArchiveMonsterList()
    if not XTool.IsTableEmpty(typeToMonsters) then
        for _, monsters in pairs(typeToMonsters) do
            for _, v in pairs(monsters) do
                if v.Id == id and not v.IsLockMain then
                    return true
                end
            end
        end
    end
    return false
end

function XMonsterArchiveModel:GetArchiveMonsterInfoList()
    if XTool.IsTableEmpty(self._ArchiveMonsterInfoList) then
        InitArchiveMonsterDetail(self, XEnumConst.Archive.EntityType.Info, self:GetMonsterInfo(), self._ArchiveMonsterInfoList, self._MonsterInfoLockState, self._MonsterInfoEntityData, true)
    end
    return self._ArchiveMonsterInfoList
end

function XMonsterArchiveModel:GetArchiveMonsterSkillList()
    if XTool.IsTableEmpty(self._ArchiveMonsterSkillList) then
        InitArchiveMonsterDetail(self, XEnumConst.Archive.EntityType.Skill, self:GetMonsterSkill(), self._ArchiveMonsterSkillList, self._MonsterSkillLockState, self._MonsterSkillEntityData, false)
    end
    return self._ArchiveMonsterSkillList
end

function XMonsterArchiveModel:GetArchiveMonsterSettingList()
    if XTool.IsTableEmpty(self._ArchiveMonsterSettingList) then
        InitArchiveMonsterDetail(self, XEnumConst.Archive.EntityType.Setting, self:GetMonsterSetting(), self._ArchiveMonsterSettingList, self._MonsterSettingLockState, self._MonsterSettingEntityData, true)
    end
    return self._ArchiveMonsterSettingList
end

--endregion

--region 红点数据

function XMonsterArchiveModel:GetMonsterRedPointDic()
    return self._MonsterRedPointDic
end

function XMonsterArchiveModel:GetMonsterRedPointDicByType(type)
    if self._MonsterRedPointDic[type] then
        return self._MonsterRedPointDic[type]
    end
end

function XMonsterArchiveModel:SetMonsterRedPointDic(monsterId, type, id)
    local monsterCfg = self:GetMonster()[monsterId]
    local monsterType = monsterCfg and monsterCfg.Type or nil

    if not monsterType then
        return
    end

    if not self._MonsterRedPointDic[monsterType] then
        self._MonsterRedPointDic[monsterType] = {}
    end

    if not self._MonsterRedPointDic[monsterType][monsterId] then
        self._MonsterRedPointDic[monsterType][monsterId] = {}
    end

    --todo 考虑位运算
    if type == XEnumConst.Archive.MonsterRedPointType.Monster then
        if not self._ArchiveMonsterUnlockIdsList[monsterId] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewMonster = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterInfo then
        if not self._ArchiveMonsterInfoUnlockIdsList[id] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewInfo = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSkill then
        if not self._ArchiveMonsterSkillUnlockIdsList[id] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewSkill = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSetting then
        if not self._ArchiveMonsterSettingUnlockIdsList[id] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewSetting = true
        end
    end
end

function XMonsterArchiveModel:ClearMonsterRedPointDic(monsterType,monsterId,type)
    if not self._MonsterRedPointDic[monsterType] then
        return
    end

    if not self._MonsterRedPointDic[monsterType][monsterId] then
        return
    end

    --todo：考虑位运算
    if type == XEnumConst.Archive.MonsterRedPointType.Monster then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewMonster = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterInfo then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewInfo = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSkill then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewSkill = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSetting then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewSetting = false
    end

    if not self._MonsterRedPointDic[monsterType][monsterId].IsNewMonster and
            not self._MonsterRedPointDic[monsterType][monsterId].IsNewInfo and
            not self._MonsterRedPointDic[monsterType][monsterId].IsNewSkill and
            not self._MonsterRedPointDic[monsterType][monsterId].IsNewSetting then
        self._MonsterRedPointDic[monsterType][monsterId] = nil
    end
end

function XMonsterArchiveModel:ResetMonsterRedPointDic()
    self._MonsterRedPointDic = {}
end

--endregion

--region 配置表

function XMonsterArchiveModel:GetMonster()
    return self._ConfigUtil:Get(MonsterTablePath.TABLE_MONSTER)
end

function XMonsterArchiveModel:GetMonsterInfo()
    return self._ConfigUtil:Get(MonsterTablePath.TABLE_MONSTERINFO)
end

function XMonsterArchiveModel:GetMonsterSkill()
    return self._ConfigUtil:Get(MonsterTablePath.TABLE_MONSTERSKILL)
end

function XMonsterArchiveModel:GetMonsterSetting()
    return self._ConfigUtil:GetByTableKey(MonsterShareTableKey.MonsterSetting)
end

function XMonsterArchiveModel:GetSameNpcGroup()
    return self._ConfigUtil:GetByTableKey(MonsterShareTableKey.SameNpcGroup)
end

function XMonsterArchiveModel:GetMonsterNpcData()
    return self._ConfigUtil:GetByTableKey(MonsterClientTableKey.MonsterNpcData)
end

function XMonsterArchiveModel:GetMonsterEffect()
    return self._ConfigUtil:GetByTableKey(MonsterClientTableKey.MonsterEffect)
end

function XMonsterArchiveModel:GetCfgMonsterInfoInnerById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MonsterClientTableKey.MonsterInfoInner, id, notips)
end

function XMonsterArchiveModel:GetCfgMonsterSettingInnerById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MonsterClientTableKey.MonsterSettingInner, id, notips)
end

function XMonsterArchiveModel:GetCfgMonsterInnerById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MonsterClientTableKey.ArchiveMonsterInner, id, notips)
end

function XMonsterArchiveModel:GetArchiveMonsterEffectDatasDic()
    if XTool.IsTableEmpty(self._ArchiveMonsterEffectDatasDic) then
        local monsterEffects = self:GetMonsterEffect()
        if not XTool.IsTableEmpty(monsterEffects) then
            for _, transData in pairs(monsterEffects) do
                local archiveMonsterEffectData = self._ArchiveMonsterEffectDatasDic[transData.NpcId]
                if not archiveMonsterEffectData then
                    archiveMonsterEffectData = {}
                    self._ArchiveMonsterEffectDatasDic[transData.NpcId] = archiveMonsterEffectData
                end
                local archiveMonsterEffect = archiveMonsterEffectData[transData.NpcState]
                if not archiveMonsterEffect then
                    archiveMonsterEffect = {}
                    archiveMonsterEffectData[transData.NpcState] = archiveMonsterEffect
                end
                archiveMonsterEffect[transData.EffectNodeName] = transData.EffectPath
            end
        end
    end
    return self._ArchiveMonsterEffectDatasDic
end

--endregion

return XMonsterArchiveModel
