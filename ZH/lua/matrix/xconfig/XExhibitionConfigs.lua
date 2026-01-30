XExhibitionConfigs = XExhibitionConfigs or {}

local TABLE_CHARACTER_EXHIBITION = "Client/Exhibition/Exhibition.tab"
local TABLE_CHARACTER_EXHIBITION_CHARACTER_MAP = "Client/Exhibition/ExhibitionCharacterMap.tab"
local TABLE_CHARACTER_EXHIBITION_TYPE_MAP = "Client/Exhibition/ExhibitionTypeMap.tab"

local TABLE_CHARACTER_EXHIBITION_LEVEL = "Client/Exhibition/ExhibitionLevel.tab"
local TABLE_CHARACTER_GROW_TASK_INFO = "Share/Exhibition/ExhibitionReward.tab"
local TABLE_EXHIBITIONLIMIT = "Share/Exhibition/ExhibitionLimit.tab"

local DefaultPortraitImagePath = CS.XGame.ClientConfig:GetString("DefaultPortraitImagePath")
local ExhibitionLevelPoint = {}
---@type XTableCharacterExhibition[]
local ExhibitionConfig = {}
---@type XTableExhibitionCharacterMap[]
local ExhibitionCharacterMapConfig = {}
---@type XTableExhibitionTypeMap[]
local ExhibitionTypeMapConfig = {}

local CharacterExhibitionLevelConfig = {}
local GrowUpTasksConfig = {}
local CharacterGrowUpTasksConfig = {}
local CharacterGrowUpTasksConfigByType = {}
local ExhibitionConfigByTypeAndPort = {} -- 展示厅、收集界面用到
local ExhibitionConfigByTypeAndGroup = {} -- 展示厅用到
local InVisibleGroupTable = {} -- 展示厅用到
local ExhibitionlimitTable = {}

function XExhibitionConfigs.Init()
    CharacterExhibitionLevelConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_EXHIBITION_LEVEL, XTable.XTableExhibitionLevel, "LevelId")
    ExhibitionlimitTable = XTableManager.ReadByIntKey(TABLE_EXHIBITIONLIMIT, XTable.XTableExhibitionLimit, "CharacterId")
    ExhibitionConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_EXHIBITION, XTable.XTableCharacterExhibition, "Id")
    ExhibitionCharacterMapConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_EXHIBITION_CHARACTER_MAP, XTable.XTableExhibitionCharacterMap, "CharacterId")
    ExhibitionTypeMapConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_EXHIBITION_TYPE_MAP, XTable.XTableExhibitionTypeMap, "Type")
    
    GrowUpTasksConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_GROW_TASK_INFO, XTable.XTableExhibitionReward, "Id")
    for task, v in pairs(GrowUpTasksConfig) do
        if CharacterGrowUpTasksConfig[v.CharacterId] == nil then
            CharacterGrowUpTasksConfig[v.CharacterId] = {}
        end
        CharacterGrowUpTasksConfig[v.CharacterId][task] = v
        local type = XExhibitionConfigs.GetExhibitionTypeByCharacterId(v.CharacterId) or 1
        if not CharacterGrowUpTasksConfigByType[type] then CharacterGrowUpTasksConfigByType[type] = {} end
        if not CharacterGrowUpTasksConfigByType[type][v.Id] then
            CharacterGrowUpTasksConfigByType[type][v.Id] = v
        end
    end
    ExhibitionLevelPoint[1] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_01")
    ExhibitionLevelPoint[2] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_02")
    ExhibitionLevelPoint[3] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_03")
    ExhibitionLevelPoint[4] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_04")
    -- ExhibitionLevelPoint[5] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_05")
end

function XExhibitionConfigs.GetDefaultPortraitImagePath()
    return DefaultPortraitImagePath
end

function XExhibitionConfigs.GetExhibitionLevelPoints()
    return ExhibitionLevelPoint
end

function XExhibitionConfigs.GetGrowUpLevelMax()
    local maxPoint = 0
    for _, value in pairs(ExhibitionLevelPoint) do
        maxPoint = maxPoint + value
    end
    return maxPoint
end

function XExhibitionConfigs.GetExhibitionConfig()
    return ExhibitionConfig
end

function XExhibitionConfigs.GetExhibitionConfigById(teamId)
    local config=ExhibitionConfig[teamId]
    if config then
        return config
    else
        XLog.ErrorTableDataNotFound("XExhibitionConfigs.GetExhibitionConfigById","",TABLE_CHARACTER_EXHIBITION,"teamId",teamId)
    end
end

function XExhibitionConfigs.GetExhibitionPortConfigByType(showType)
    if not showType then return ExhibitionConfig end
    XExhibitionConfigs.CheckTypeMapInitByType(showType)
    return ExhibitionConfigByTypeAndPort[showType] or {}
end

function XExhibitionConfigs.GetExhibitionGroupConfigByType(showType)
    if not showType then return ExhibitionConfig end
    XExhibitionConfigs.CheckTypeMapInitByType(showType)
    return ExhibitionConfigByTypeAndGroup[showType] or {}
end

function XExhibitionConfigs.GetExhibitionConfigByTypeAndGroup(showType, groupId)
    XExhibitionConfigs.CheckTypeMapInitByType(showType)
    return ExhibitionConfigByTypeAndGroup[showType][groupId]
end

function XExhibitionConfigs.GetExhibitionTypeByCharacterId(characterId)
    local cfg = XExhibitionConfigs.GetExhibitionCfgByCharacterId(characterId)

    if cfg then
        return cfg.Type
    end
end

function XExhibitionConfigs.GetExhibitionGroupLogoConfig(characterId)
    local cfg = XExhibitionConfigs.GetExhibitionCfgByCharacterId(characterId)

    if cfg then
        return cfg.GroupLogo
    end
    
    return ''
end

function XExhibitionConfigs.GetExhibitionInVisbleGroupTable(exhibitionType)
    XExhibitionConfigs.CheckTypeMapInitByType(exhibitionType)
    return InVisibleGroupTable[exhibitionType] or {}
end

function XExhibitionConfigs.GetIsExhibitionInVisbleGroup(exhibitionType, groupId)
    XExhibitionConfigs.CheckTypeMapInitByType(exhibitionType)
    return InVisibleGroupTable[exhibitionType] and InVisibleGroupTable[exhibitionType][groupId] or false
end

function XExhibitionConfigs.GetExhibitionLevelConfig()
    return CharacterExhibitionLevelConfig
end

function XExhibitionConfigs.GetCharacterGrowUpTasks(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        return
    end
    
    local config = CharacterGrowUpTasksConfig[characterId]
    if not config then
        XLog.Error("XExhibitionConfigs.GetCharacterGrowUpTasks error: 角色解放配置错误：characterId: " .. characterId .. " ,path: " .. TABLE_CHARACTER_GROW_TASK_INFO)
        return
    end
    return config
end

function XExhibitionConfigs.GetCharacterGrowUpTask(characterId, level)
    local levelTasks = XExhibitionConfigs.GetCharacterGrowUpTasks(characterId)
    if XTool.IsTableEmpty(levelTasks) then
        return
    end
    
    for _, config in pairs(levelTasks) do
        if config.LevelId == level then
            return config
        end
    end
end

function XExhibitionConfigs.GetCharacterGrowUpTasksConfig()
    return CharacterGrowUpTasksConfig
end

function XExhibitionConfigs.GetExhibitionGrowUpLevelConfig(level)
    return CharacterExhibitionLevelConfig[level]
end

function XExhibitionConfigs.GetExhibitionLevelNameByLevel(level)
    return CharacterExhibitionLevelConfig[level].Name or ""
end

function XExhibitionConfigs.GetExhibitionLevelDescByLevel(level)
    return CharacterExhibitionLevelConfig[level].Desc or ""
end

function XExhibitionConfigs.GetExhibitionLevelIconByLevel(level)
    return CharacterExhibitionLevelConfig[level].LevelIcon or ""
end

function XExhibitionConfigs.GetExhibitionGroupByCharId(charId)
    return XExhibitionConfigs.GetExhibitionCfgByCharacterId(charId)
end

function XExhibitionConfigs.GetCharacterHeadPortrait(characterId)
    local cfg = XExhibitionConfigs.GetExhibitionCfgByCharacterId(characterId)

    if cfg then
        return cfg.HeadPortrait
    end
    
    return ''
end

function XExhibitionConfigs.GetCharacterGraduationPortrait(characterId)
    local cfg = XExhibitionConfigs.GetExhibitionCfgByCharacterId(characterId)

    if cfg then
        return cfg.GraduationPortrait
    end
    
    return ''
end

function XExhibitionConfigs.GetGrowUpTasksConfig()
    return GrowUpTasksConfig
end

function XExhibitionConfigs.GetCharacterExhibitonLimitCfgByCharacterId(id)
    return ExhibitionlimitTable[id]
end

function XExhibitionConfigs.GetAureoleListByCharacterId(id)
    local res = {}
    local idList = ExhibitionlimitTable[id].AureoleIds
    for k, id in pairs(idList) do
        local aureoleCfg = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.FashionAureole)[id]
        res[k] = aureoleCfg
    end
    return res
end

function XExhibitionConfigs.GetGrowUpTasksConfigByType(exhibitionType)
    if not exhibitionType then return GrowUpTasksConfig end
    return CharacterGrowUpTasksConfigByType[exhibitionType] or {}
end

function XExhibitionConfigs.GetExhibitionCfgByCharacterId(characterId)
    local cfg = ExhibitionCharacterMapConfig[characterId]

    if cfg then
        return ExhibitionConfig[cfg.ExhibitionId]
    --else
        --XLog.Error('找不到角色Id：' .. tostring(characterId) .. ' 对应的Exhibition配置Id')
        -- 从4.0开始，新做了军团系统，旧的剧情系统配置不再维护，所以新的角色找不到，这里会报错
        -- 但是由于策划的要求，旧系统暂时不予移除，保留恢复的可能性
    end
end

function XExhibitionConfigs.GetExhibitionIdsByType(Type)
    local cfg = ExhibitionTypeMapConfig[Type]

    if cfg then
        return cfg.ExhibitionIds
    else
        XLog.Error('找不到Type：' .. tostring(Type) .. ' 对应的Exhibition配置Id')
    end
end

function XExhibitionConfigs.CheckTypeMapInitByType(type)
    if XTool.IsTableEmpty(ExhibitionConfigByTypeAndPort[type]) then
        local ids = XExhibitionConfigs.GetExhibitionIdsByType(type)

        if not XTool.IsTableEmpty(ids) then
            if ExhibitionConfigByTypeAndPort[type] == nil then
                ExhibitionConfigByTypeAndPort[type] = {}
                ExhibitionConfigByTypeAndGroup[type] = {}
                InVisibleGroupTable[type] = {}
            end
            
            for i, exhibitionId in ipairs(ids) do
                local cfg = ExhibitionConfig[exhibitionId]

                if cfg and cfg.Port ~= nil then
                    ExhibitionConfigByTypeAndPort[type][cfg.Port] = cfg
                    ExhibitionConfigByTypeAndGroup[type][cfg.GroupId] = cfg
                    
                    if InVisibleGroupTable[type][cfg.GroupId] == nil then
                        InVisibleGroupTable[type][cfg.GroupId] = true 
                    end
                    
                    if cfg.InVisible == 1 then
                        InVisibleGroupTable[type][cfg.GroupId] = false 
                    end
                end
            end
        end
    end
end 