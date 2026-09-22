-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey =
{
    TeamRecommendBaseCharacter = { CacheType = XConfigUtil.CacheType.Normal },
    TeamRecommendBaseFormation = { CacheType = XConfigUtil.CacheType.Normal },
    TeamRecommendCharacterTarget = { Identifier = "CharacterId", CacheType = XConfigUtil.CacheType.Normal },
    TeamRecommendConfig = { ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", CacheType = XConfigUtil.CacheType.Normal },
    TeamRecommendFormation = { CacheType = XConfigUtil.CacheType.Normal },
    TeamRecommendProgressWeight = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", CacheType = XConfigUtil.CacheType.Normal },
}

---@class XTeamRecommendModel : XModel
local XTeamRecommendModel = XClass(XModel, "XTeamRecommendModel")

function XTeamRecommendModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ServerCharacterTargets = {}
    self._ServerFormationDataByCharacterId = {}
    self._ServerFormationRequestedTeamCfgIdsByCharacterId = {}

    --config相关
    self:InitConfig()
end

function XTeamRecommendModel:ClearPrivate()
    --这里执行内部数据清理
    self._BaseFormationByCharacterId = nil
    self._FormationByFilter = nil
    self._ServerCharacterTargets = {}
    self._ServerFormationDataByCharacterId = {}
    self._ServerFormationRequestedTeamCfgIdsByCharacterId = {}
end

function XTeamRecommendModel:ResetAll()
    --这里执行重登数据清理
    self:ClearPrivate()
end

--region ----------public start----------

--============================================================== #region 配置表查询 ==============================================================

---------------------------------------- #region TeamRecommendBaseCharacter ----------------------------------------
--- 获取角色推荐方案配置（单条/全部）
function XTeamRecommendModel:GetTeamRecommendBaseCharacter(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendBaseCharacter)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/TeamRecommend/TeamRecommendBaseCharacter.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

---------------------------------------- #region TeamRecommendBaseFormation ----------------------------------------
--- 获取阵容基础信息配置（单条/全部）
function XTeamRecommendModel:GetTeamRecommendBaseFormation(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendBaseFormation)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/TeamRecommend/TeamRecommendBaseFormation.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 根据FormationId+CharacterId锁定BaseFormation配置行
function XTeamRecommendModel:GetTeamRecommendBaseFormationByFormationIdAndCharacterId(formationId, characterId)
    self:InitBaseFormationByCharacterId()
    local characterFormations = self._BaseFormationByCharacterId[characterId]
    if characterFormations then
        return characterFormations[formationId]
    end
    return nil
end

---------------------------------------- #region TeamRecommendCharacterTarget ----------------------------------------
--- 获取角色目标设定配置
function XTeamRecommendModel:GetTeamRecommendCharacterTarget(characterId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendCharacterTarget)
    if characterId then
        if cfgs[characterId] then
            return cfgs[characterId]
        else
            XLog.Error("请检查配置表Share/TeamRecommend/TeamRecommendCharacterTarget.tab，未配置行CharacterId = " .. tostring(characterId))
        end
    else
        return cfgs
    end
end

--- 获取角色的目标方案ID列表
function XTeamRecommendModel:GetCharacterTargetBaseCharacterIds(characterId)
    local cfg = self:GetTeamRecommendCharacterTarget(characterId)
    return cfg and cfg.BaseCharacterIds or {}
end

--- 获取角色目标名称列表
function XTeamRecommendModel:GetCharacterTargetNames(characterId)
    local cfg = self:GetTeamRecommendCharacterTarget(characterId)
    return cfg and cfg.TargetName or {}
end

---------------------------------------- #region TeamRecommendConfig ----------------------------------------
--- 获取通用配置（Key-Value），单条或全部
function XTeamRecommendModel:GetTeamRecommendConfig(key)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendConfig)
    if key then
        if cfgs[key] then
            return cfgs[key]
        else
            XLog.Error("请检查配置表Share/TeamRecommend/TeamRecommendConfig.tab，未配置行Key = " .. tostring(key))
        end
    else
        return cfgs
    end
end

--- 获取通用配置的Values
function XTeamRecommendModel:GetTeamRecommendConfigValues(key)
    local cfg = self:GetTeamRecommendConfig(key)
    return cfg and cfg.Values
end

--- 角色目标设定上限
function XTeamRecommendModel:GetCharacterTargetLimit()
    local values = self:GetTeamRecommendConfigValues("CharacterTargetLimit")
    return values and tonumber(values[1]) or 6
end

--- 任务要求的目标完成度上报阈值（百分比）
function XTeamRecommendModel:GetTargetFinishPercentage()
    local values = self:GetTeamRecommendConfigValues("TargetFinishPercentage")
    return values and tonumber(values[1]) or 100
end

---------------------------------------- #region TeamRecommendProgressWeight ----------------------------------------
--- 获取目标完成度权重配置
function XTeamRecommendModel:GetTeamRecommendProgressWeight()
    return self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendProgressWeight)
end

---------------------------------------- #region TeamRecommendFormation ----------------------------------------
--- 获取阵容筛选/展示配置（单条/全部）
function XTeamRecommendModel:GetTeamRecommendFormation(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendFormation)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/TeamRecommend/TeamRecommendFormation.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 根据StageType+FormationType筛选Formation配置列表
function XTeamRecommendModel:GetFormationListByFilter(stageType, formationType)
    self:InitFormationByFilter()
    local stageFormations = self._FormationByFilter[stageType]
    if stageFormations then
        return stageFormations[formationType] or {}
    end
    return {}
end

--============================================================== #endregion 配置表查询 ==============================================================

---------------------------------------- #region 业务查询 ----------------------------------------
--- Tab1: 根据CharacterId获取该角色的所有推荐方案（BaseCharacter列表）
function XTeamRecommendModel:GetBaseCharacterListByCharacterId(characterId)
    local baseCharacterIds = self:GetCharacterTargetBaseCharacterIds(characterId)
    local result = {}
    for _, bcId in ipairs(baseCharacterIds) do
        local cfg = self:GetTeamRecommendBaseCharacter(bcId)
        if cfg then
            table.insert(result, cfg)
        end
    end
    return result
end

---------------------------------------- #region 服务端目标数据 ----------------------------------------
--- 更新服务端当前目标数据；注意Notify的CharacterTargets是整个Db，内层才是同名的进行中字典
function XTeamRecommendModel:UpdateServerCharacterTargets(targetDataDb)
    self._ServerCharacterTargets = {}
    if not targetDataDb then
        return
    end

    for characterId, target in pairs(targetDataDb.CharacterTargets or {}) do
        local key = tonumber(characterId) or characterId
        self._ServerCharacterTargets[key] = target
    end
end

--- 更新单个角色目标缓存
function XTeamRecommendModel:UpdateServerCharacterTarget(characterId, target)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    self._ServerCharacterTargets = self._ServerCharacterTargets or {}
    if target then
        self._ServerCharacterTargets[characterId] = target
    else
        self._ServerCharacterTargets[characterId] = nil
    end
end

--- 删除单个角色目标缓存
function XTeamRecommendModel:DeleteServerCharacterTarget(characterId)
    self:UpdateServerCharacterTarget(characterId, nil)
end

--- 获取角色当前服务端目标
function XTeamRecommendModel:GetServerCharacterTarget(characterId)
    if not XTool.IsNumberValid(characterId) then
        return nil
    end
    return self._ServerCharacterTargets and self._ServerCharacterTargets[characterId]
end

--- 获取所有已设角色目标（单人+阵容）
function XTeamRecommendModel:GetServerCharacterTargetList()
    local result = {}

    for characterId, target in pairs(self._ServerCharacterTargets or {}) do
        local targetCharacterId = tonumber(characterId)
        if XTool.IsNumberValid(targetCharacterId) then
            table.insert(result, {
                CharacterId = targetCharacterId,
                Target = target,
            })
        end
    end

    table.sort(result, function(a, b)
        return a.CharacterId < b.CharacterId
    end)

    return result
end

---------------------------------------- #region 服务端阵容详情数据 ----------------------------------------
--- 更新服务端阵容详情缓存；本次请求但未返回的teamCfgId会被清掉，展示回退配表
function XTeamRecommendModel:UpdateServerFormationDatas(characterId, formations, requestTeamCfgIds)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    self._ServerFormationDataByCharacterId = self._ServerFormationDataByCharacterId or {}
    self._ServerFormationRequestedTeamCfgIdsByCharacterId = self._ServerFormationRequestedTeamCfgIdsByCharacterId or {}
    local characterFormations = self._ServerFormationDataByCharacterId[characterId]
    if not characterFormations then
        characterFormations = {}
        self._ServerFormationDataByCharacterId[characterId] = characterFormations
    end
    local requestedMap = self._ServerFormationRequestedTeamCfgIdsByCharacterId[characterId]
    if not requestedMap then
        requestedMap = {}
        self._ServerFormationRequestedTeamCfgIdsByCharacterId[characterId] = requestedMap
    end

    for _, teamCfgId in ipairs(requestTeamCfgIds or {}) do
        if XTool.IsNumberValid(teamCfgId) then
            requestedMap[teamCfgId] = true
            characterFormations[teamCfgId] = nil
        end
    end

    for teamCfgId, formationData in pairs(formations or {}) do
        local key = tonumber(teamCfgId) or teamCfgId
        characterFormations[key] = formationData
    end
end

--- 判断指定阵容详情是否已向服务端请求过
function XTeamRecommendModel:AreServerFormationDatasRequested(characterId, teamCfgIds)
    if not XTool.IsNumberValid(characterId) or not teamCfgIds then
        return false
    end

    local requestedTeamCfgIds = self._ServerFormationRequestedTeamCfgIdsByCharacterId and self._ServerFormationRequestedTeamCfgIdsByCharacterId[characterId]
    if not requestedTeamCfgIds then
        return false
    end

    for _, teamCfgId in ipairs(teamCfgIds) do
        if XTool.IsNumberValid(teamCfgId) and not requestedTeamCfgIds[teamCfgId] then
            return false
        end
    end
    return true
end

--- 获取服务端阵容详情
function XTeamRecommendModel:GetServerFormationData(characterId, teamCfgId)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(teamCfgId) then
        return nil
    end

    local characterFormations = self._ServerFormationDataByCharacterId and self._ServerFormationDataByCharacterId[characterId]
    return characterFormations and characterFormations[teamCfgId] or nil
end

--endregion ----------public end----------

--region ----------private start----------

--- 延迟初始化：BaseFormation按CharacterId建索引
--- _BaseFormationByCharacterId = { [characterId] = { [formationId] = config } }
function XTeamRecommendModel:InitBaseFormationByCharacterId()
    if self._BaseFormationByCharacterId then
        return
    end
    self._BaseFormationByCharacterId = {}
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendBaseFormation)
    for _, config in pairs(cfgs) do
        if not self._BaseFormationByCharacterId[config.CharacterId] then
            self._BaseFormationByCharacterId[config.CharacterId] = {}
        end
        self._BaseFormationByCharacterId[config.CharacterId][config.FormationId] = config
    end
end

--- 延迟初始化：Formation按StageType+FormationType建索引
--- _FormationByFilter = { [stageType] = { [formationType] = { configs } } }
function XTeamRecommendModel:InitFormationByFilter()
    if self._FormationByFilter then
        return
    end
    self._FormationByFilter = {}
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.TeamRecommendFormation)
    for _, config in pairs(cfgs) do
        if not self._FormationByFilter[config.StageType] then
            self._FormationByFilter[config.StageType] = {}
        end
        if not self._FormationByFilter[config.StageType][config.FormationType] then
            self._FormationByFilter[config.StageType][config.FormationType] = {}
        end
        table.insert(self._FormationByFilter[config.StageType][config.FormationType], config)
    end
end

--endregion ----------private end----------

--============================================================== #region 配置表 ==============================================================

function XTeamRecommendModel:InitConfig()
    self._ConfigUtil:InitConfigByTableKey("TeamRecommend", TableKey)
end

--============================================================== #endregion 配置表 ==============================================================

return XTeamRecommendModel
