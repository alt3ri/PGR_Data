XLoadingConfig = XLoadingConfig or {}

local CustomLoadingCfg = {}
local LoadingAllowType = {}
local CGBlockGroup = {}
local TypeDic = {}
local LoadingCfgs = {}
---@type XTableLoadingTypeMap[]
local LoadingTypeMapCfgs = {}

local TABLE_LOADING_PATH = "Client/Loading/Loading.tab"
local TABLE_LOADING_TYPE_MAP_PATH = "Client/Loading/LoadingTypeMap.tab"
local TABLE_CUSTOM_LOADING_PATH = "Client/Loading/CustomLoading.tab"

XLoadingConfig.DEFAULT_TYPE = "0"

function XLoadingConfig.Init()
    LoadingCfgs = XTableManager.ReadByIntKey(TABLE_LOADING_PATH, XTable.XTableLoading, "Id")
    LoadingTypeMapCfgs = XTableManager.ReadByStringKey(TABLE_LOADING_TYPE_MAP_PATH, XTable.XTableLoadingTypeMap, "Type")
    CustomLoadingCfg = XTableManager.ReadByIntKey(TABLE_CUSTOM_LOADING_PATH, XTable.XTableCustomLoading, "Id")[1]
    TypeDic = {}

    
    LoadingAllowType = {}
    for _, v in pairs(CustomLoadingCfg.AllowType) do
        LoadingAllowType[v] = true
    end

    CGBlockGroup = {}
    for _, v in pairs(CustomLoadingCfg.BlockGroup) do
        CGBlockGroup[v] = true
    end
end

function XLoadingConfig.GetCfgByType(type)
    local cfgs =  TypeDic[type]

    if not cfgs then
        local typeMapCfg = LoadingTypeMapCfgs[type]

        if typeMapCfg and not XTool.IsTableEmpty(typeMapCfg.LoadingIds) then
            cfgs = {}

            for i, id in ipairs(typeMapCfg.LoadingIds) do
                table.insert(cfgs, LoadingCfgs[id])
            end

            TypeDic[type] = cfgs
        end
    end

    return cfgs
end

-- 范围：0-10000
function XLoadingConfig.GetCustomRate()
    return CustomLoadingCfg.Rate
end

function XLoadingConfig.GetCustomMaxSize()
    return CS.XGame.Config:GetInt("CustomLoadingMaxSize")
end

function XLoadingConfig.GetCustomUseSpine()
    return CustomLoadingCfg.UseSpine
end

function XLoadingConfig.CheckCustomAllowType(stageLoadingType)
    return LoadingAllowType[stageLoadingType]
end

function XLoadingConfig.CheckCustomBlockGroup(groupId)
    return CGBlockGroup[groupId]
end