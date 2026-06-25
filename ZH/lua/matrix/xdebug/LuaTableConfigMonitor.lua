---@class LuaTableConfigMonitor Lua表格监视器
local LuaTableConfigMonitor = {}

local CacheTypeStr = {
    [XConfigUtil.CacheType.Temp] = "Temp",
    [XConfigUtil.CacheType.Normal] = "Normal",
    [XConfigUtil.CacheType.Preload] = "Preload",
    [XConfigUtil.CacheType.Private] = "Private",
}
local Path2TabScope = {}
---@type table<int, boolean>用于记录已经访问过的列表
local Visited = {}

local tableScopeTab = {}
local TableScopeAgencyStr = "Agency"
local TableScopeControlStr = "Control"
local TableScopeTempStr = "Temp"

---@class LuaMemUtil
---@field GetTotalSize fun(obj, visited):number
---@field GetSelfSize fun(obj):number
local LuaMemUtil = require("LuaMemUtil")

local function GetTotalSize(obj)
    if not obj then
        return 0
    end
    local size = LuaMemUtil.GetTotalSize(obj, Visited)
    return size
end

local function GetSelfSize(obj)
    if not obj then
        return 0
    end

    local size = LuaMemUtil.GetSelfSize(obj)
    return size
end

local function ContainScope(targetScope, tabScope)
    return (targetScope & tabScope) ~= 0
end

local function GetTabScopeStr(tabScope)
    for i = #tableScopeTab, 1, -1 do
        tabScope[i] = nil
    end

    if ContainScope(XConfigUtil.TabScope.Agency, tabScope) then
        tabScope[#tabScope + 1] = TableScopeAgencyStr
    end
    if ContainScope(XConfigUtil.TabScope.Control, tabScope) then
        tabScope[#tabScope + 1] = TableScopeControlStr
    end
    if ContainScope(XConfigUtil.TabScope.Temp, tabScope) then
        tabScope[#tabScope + 1] = TableScopeTempStr
    end

    return table.concat(tableScopeTab, "|")
end

---@type HaruPerformance.Runtime.Agent.HaruPerformanceMonitor
local CsHaruPerformanceMonitor = CS.HaruPerformance.Runtime.Agent.HaruPerformanceMonitor
local CsBinaryConfigSourceLuaType = CsHaruPerformanceMonitor.BinaryConfigSourceLuaType

function LuaTableConfigMonitor.ClearAll()
    Visited = {}
    Path2TabScope = {}
end

function LuaTableConfigMonitor.OnOpenBinaryTable(tablePath)
    CsHaruPerformanceMonitor.OnOpenBinaryTable(CsBinaryConfigSourceLuaType, tablePath)
end

function LuaTableConfigMonitor.OnCloseBinaryTable(tablePath)
    CsHaruPerformanceMonitor.OnCloseBinaryTable(CsBinaryConfigSourceLuaType, tablePath)
end

function LuaTableConfigMonitor.OnLoadBinary(tablePath, binary)
    local binarySize = 0
    if binary then
        binarySize = GetTotalSize(binary)
    end

    LuaTableConfigMonitor.OnLoadBinaryWithSize(CsBinaryConfigSourceLuaType, tablePath, binarySize)
end

function LuaTableConfigMonitor.OnLoadBinaryWithSize(tablePath, binarySize)
    if tablePath == "21622" then
        local i = 1
    end
    CsHaruPerformanceMonitor.OnLoadBinary(CsBinaryConfigSourceLuaType, tablePath, binarySize)

    local info = Path2TabScope[tablePath]
    if info then
        CsHaruPerformanceMonitor.SetModule(CsBinaryConfigSourceLuaType, tablePath, info.ModuleId, info.TabScope)
    end
end

function LuaTableConfigMonitor.OnUnloadBinary(tablePath)
    CsHaruPerformanceMonitor.OnUnloadBinary(CsBinaryConfigSourceLuaType, tablePath)
end

function LuaTableConfigMonitor.RegisterFixedStructuralSize(tablePath, structural, obj, isSelf)
    if not obj then
        return
    end
    local size = 0
    size = isSelf and GetSelfSize(obj) or GetTotalSize(obj)
    CsHaruPerformanceMonitor.RegisterFixedStructuralSize(CsBinaryConfigSourceLuaType, tablePath, structural, size)
end

function LuaTableConfigMonitor.UpdateVolatileStructuralSize(tablePath, structural, obj, isSelf)
    if not obj then
        return
    end
    local size = 0
    size = isSelf and GetSelfSize(obj) or GetTotalSize(obj)
    CsHaruPerformanceMonitor.UpdateVolatileStructuralSize(CsBinaryConfigSourceLuaType, tablePath, structural, size)
end

function LuaTableConfigMonitor.UpdateStringSize(tablePath, obj, isSelf)
    if not obj then
        return
    end
    local size = 0
    size = isSelf and GetSelfSize(obj) or GetTotalSize(obj)
    CsHaruPerformanceMonitor.UpdateStringSize(CsBinaryConfigSourceLuaType, tablePath, size)
end

function LuaTableConfigMonitor.UpdateBinaryRows(tablePath, row)
    CsHaruPerformanceMonitor.UpdateBinaryRows(CsBinaryConfigSourceLuaType, tablePath, row)
end

function LuaTableConfigMonitor.UpdateBinaryFields(tablePath, obj)
    if not obj then
        return
    end
    local size = 0
    size = GetTotalSize(obj)
    CsHaruPerformanceMonitor.UpdateBinaryFields(CsBinaryConfigSourceLuaType, tablePath, size)
end

function LuaTableConfigMonitor.ReleaseBinaryFields(tablePath)
    CsHaruPerformanceMonitor.OnReleaseBinaryFields(CsBinaryConfigSourceLuaType, tablePath)
end

function LuaTableConfigMonitor.SetModuleByTabConfig(tablePath, module, tabScope)
    local info = Path2TabScope[tablePath]
    local tabScopeStr = GetTabScopeStr(tabScope) or "Unknown"
    if not info then
        info = {
            ModuleId = module,
            TabScope = tabScopeStr
        }
        Path2TabScope[tablePath] = info
    end
    info.ModuleId = module
    info.TabScope = tabScopeStr
    CsHaruPerformanceMonitor.SetModule(CsBinaryConfigSourceLuaType, tablePath, info.ModuleId, info.TabScope)
end

function LuaTableConfigMonitor.SetModuleByCacheType(tablePath, module, cacheType)
    local info = Path2TabScope[tablePath]
    local tabScopeStr = CacheTypeStr[cacheType] or "Unknown"
    if not info then
        info = {
            ModuleId = module,
            TabScope = tabScopeStr
        }
        Path2TabScope[tablePath] = info
    end
    info.ModuleId = module
    info.TabScope = tabScopeStr
    CsHaruPerformanceMonitor.SetModule(CsBinaryConfigSourceLuaType, tablePath, info.ModuleId, info.TabScope)
end

return LuaTableConfigMonitor
    