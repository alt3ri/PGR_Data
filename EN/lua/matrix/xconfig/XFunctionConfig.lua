XFunctionConfig = XFunctionConfig or {}

local tableInsert = table.insert
--XFunctionManager.OpenCondition = {
--    Default = 0, -- 默认
--    TeamLevel = 1, -- 战队等级
--    FinishSection = 2, -- 通关副本
--    FinishTask = 3, -- 完成任务
--    FinishNoob = 4, -- 完成新手
--    Main = 5, -- 掉线返回主界面
--}
-- XFunctionManager.OpenHint = {
--     TeamLevelToOpen,
--     CopyToOpen,
--     FinishToOpen
-- }

--功能类型
local FunctionType = {
    --基础屏蔽类型
    Basic = 1,
    --大世界屏蔽类型
    BigWorld = 2,
}

--- 功能显示Id，有些地方不方便用通用组件，又无法有效关联UI和Id，因此只能将Id作为常量定义在lua里了
XFunctionConfig.FunctionalShowId = {
    --- 主界面-折叠展开按钮
    UiMainBtnOpen = 1022,
    --- 主界面-商店
    UiMainBtnStore = 1015,
    --- 主界面-终端好友
    UiMainTerminalSocial = 1021,
    --- 成员界面-装备推荐
    UiCharacterEquipRecommand = 2008,
}

--- 通用功能红点类型
XFunctionConfig.RedPointType = {
    --- 新手首次开启未点击
    NewbieFirstShow = 1,
}

---@type table<number, XTableFunctionalOpen>
local FunctionalOpenTemplates = {}  --功能开启表
local SecondaryFunctionalTemplates = {}  --二级功能配置
local SkipFunctionalTemplates = {}  --跳转功能表
-- local MainAdTemplates = {}          --广告栏
local MainActivitySkipTemplates = {} --活动便捷入口
local ShieldFuncTemplates = {}      -- 功能对应的界面名称
---@type XTableFunctionalShow[]
local FunctionalShowTemplates = {}

local OpenFunctionList = {
    [FunctionType.Basic] = false,
    [FunctionType.BigWorld] = false,
}

local SHARE_FUNCTIONAL_OPEN = "Share/Functional/FunctionalOpen.tab"
local TABLE_SECONDARY_FUNCTIONAL_PATH = "Client/Functional/SecondaryFunctional.tab"
local TABLE_SKIP_FUNCTIONAL_PATH = "Client/Functional/SkipFunctional.tab"
--local TABLE_MAIN_AD = "Client/Functional/MainAd.tab"
local TABLE_MAIN_ACTIVITY_SKIP_PATH = "Client/Functional/MainActivitySkip.tab"
local TABLE_SHIELD_FUNC_PATH = "Client/Functional/ShieldFuncList.tab"
local TABLE_FUNCTIONAL_SHOW = "Share/Functional/FunctionalShow.tab"

function XFunctionConfig.Init()
    XFunctionConfig.FunctionType = FunctionType
    
    SecondaryFunctionalTemplates = XTableManager.ReadByIntKey(TABLE_SECONDARY_FUNCTIONAL_PATH, XTable.XTableSecondaryFunctional, "Id")
    SkipFunctionalTemplates = XTableManager.ReadByIntKey(TABLE_SKIP_FUNCTIONAL_PATH, XTable.XTableSkipFunctional, "SkipId")
    MainActivitySkipTemplates = XTableManager.ReadByIntKey(TABLE_MAIN_ACTIVITY_SKIP_PATH, XTable.XTableMainActivitySkip, "Id")
    ShieldFuncTemplates = XTableManager.ReadByIntKey(TABLE_SHIELD_FUNC_PATH, XTable.XTableShieldFunc, "Id")
    ---@type table<number, XTableFunctionalOpen>
    local listOpenFunctional = XTableManager.ReadAllByIntKey(SHARE_FUNCTIONAL_OPEN, XTable.XTableFunctionalOpen, "Id")
    FunctionalShowTemplates = XTableManager.ReadByIntKey(TABLE_FUNCTIONAL_SHOW, XTable.XTableFunctionalShow, "Id")

    --eg. 后面有逻辑判断-根据是否有有效的配置来判断功能是否开启，这里暂时不优化
    for k, v in pairs(listOpenFunctional) do
        if not XTool.IsTableEmpty(v.Condition) then
            for _, id in pairs(v.Condition) do
                if id and id ~= 0 then
                    FunctionalOpenTemplates[k] = v
                    break
                end
            end
        end
    end
end

function XFunctionConfig.GetFuncOpenCfg(id)
    return FunctionalOpenTemplates[id]
end

function XFunctionConfig.GetSkipFuncCfg(id)
    return SkipFunctionalTemplates[id]
end

function XFunctionConfig.TryGetSkipFuncCfg(id)
    local cfg = SkipFunctionalTemplates[id]

    if not cfg then
        XLog.Error('尝试查找不存在的跳转配置，skipId：'..tostring(id))
    end
    
    return cfg
end

function XFunctionConfig.GetMainActSkipCfg(id)
    return MainActivitySkipTemplates[id]
end

function XFunctionConfig.GetShieldFuncUiName(id)
    if ShieldFuncTemplates[id] then
        return ShieldFuncTemplates[id].UiName
    else
        return {}
    end
end

function XFunctionConfig.GetOpenList(functionType)
    functionType = functionType and functionType or FunctionType.Basic
    local openList = OpenFunctionList[functionType]
    if openList then
        return openList
    end
    XFunctionConfig.InitFuncOpenList()
    
    return OpenFunctionList[functionType]
end

function XFunctionConfig.InitFuncOpenList()
    --还未初始化
    for _, type in pairs(FunctionType) do
        OpenFunctionList[type] = {}
    end
    for id, t in pairs(FunctionalOpenTemplates) do
        --只记录还未开放的功能
        if not XFunctionManager.JudgeOpen(id) then
            tableInsert(OpenFunctionList[t.FunctionType], id)
        end
    end
    for _, list in pairs(OpenFunctionList) do
        table.sort(list, function(a, b)
            if FunctionalOpenTemplates[a].Priority ~= FunctionalOpenTemplates[b].Priority then
                return FunctionalOpenTemplates[a].Priority < FunctionalOpenTemplates[b].Priority
            end
        end)
    end
end

function XFunctionConfig.GetSecondaryFunctionalList()
    local list = {}
    for _, v in pairs(SecondaryFunctionalTemplates) do
        tableInsert(list, v)
    end
    --排序优先级
    tableSort(list, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
    end)
    return list
end

function XFunctionConfig.GetSkipList(id)
    return SkipFunctionalTemplates[id]
end

function XFunctionConfig.GetExplain(id)
    local cfg = XFunctionConfig.TryGetSkipFuncCfg(id)

    if cfg then
        local explain = cfg.Explain
        if explain == nil then
            XLog.Error("XFunctionConfig.GetExplain error: can not found Explain, id = " .. id)
        end
        return explain
    end
    
    return ''
end

function XFunctionConfig.GetUiName(id)
    local cfg = XFunctionConfig.TryGetSkipFuncCfg(id)
    return cfg and cfg.UiName or ""
end

function XFunctionConfig.GetParamId(id)
    local cfg = XFunctionConfig.TryGetSkipFuncCfg(id)

    if cfg then
        local paramId = cfg.ParamId
        if paramId == nil then
            XLog.Error("XFunctionConfig.GetParamId error: can not found ParamId, id = " .. id)
        end
        return paramId
    end
end

function XFunctionConfig.GetIsShowExplain(id)
    local cfg = XFunctionConfig.TryGetSkipFuncCfg(id)

    if cfg then
        local isShowExplain = cfg.IsShowExplain
        if isShowExplain == nil then
            XLog.Error("XFunctionConfig.GetIsShowExplain error: can not found isShowExplain, id = " .. id)
        end
        return isShowExplain
    end
end

--获取功能开启提醒方式
function XFunctionConfig.GetOpenHint(id)
    local cfg = FunctionalOpenTemplates[id]

    if cfg then
        return cfg.Hint
    end
end

--获取功能名字
function XFunctionConfig.GetFunctionalName(id)
    local cfg = FunctionalOpenTemplates[id]

    if cfg then
        return cfg.Name
    end
    
    return ''
end

--获取功能类型
function XFunctionConfig.GetFunctionalType(id)
    local cfg = FunctionalOpenTemplates[id]

    if cfg then
        return cfg.Type
    end
end

---@return XTableFunctionalShow
function XFunctionConfig.GetFunctionalShowCfg(id)
    local cfg = FunctionalShowTemplates[id]

    if not cfg then
        XLog.ErrorTableDataNotFound(XFunctionConfig.GetFunctionalShowCfg, "FunctionalShow", TABLE_FUNCTIONAL_SHOW, "Id", id)
    end
    
    return cfg
end 