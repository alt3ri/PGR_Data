XTableManager = XTableManager or {}

local BinaryConfigMonitorEnable = CS.HaruPerformance.Runtime.Agent.HaruPerformanceMonitor.IsBinaryConfigMonitorEnabled()
---@type LuaTableConfigMonitor
local LuaTableConfigMonitor
if BinaryConfigMonitorEnable then
    LuaTableConfigMonitor = require("XDebug/LuaTableConfigMonitor") 
end

XTableManager.TableLoadType =
{
    Tab = 1,
    Bytes = 2,
    Pack = 3
}
XTableManager.CryptoEnable = false
local CSRuntimeCollectTable = CS.XAssetCollectManager.RuntimeCollectTable
local CSRuntimeCollectTableEnable = CS.XAssetCollectManager.RuntimeCollectTableEnable

local router = require("XManager/XTableLoaders/XTableLoadRouter")
local tabLoader = require("XManager/XTableLoaders/XTableTabLoader")
local bytesLoader = require("XManager/XTableLoaders/XTableBytesLoader")
local packLoader = require("XManager/XTableLoaders/XTablePackLoader")
function XTableManager.GetPackLoader()
    return packLoader
end

function XTableManager.GetBytesLoader()
    return bytesLoader
end

XTableManager.ForceRelease = false

function XTableManager.CollectReadTablePath(path)
    if XMain.IsEditorDebug and CSRuntimeCollectTableEnable and CSRuntimeCollectTable then
        CSRuntimeCollectTable(path)
    end
end

--============= 外部函数 ============
--为了兼容已有的业务调用需求，因此接口上无法做到统一，所以两个loader接受的参数是不同的
function XTableManager.ReadAllByIntKey(path, xTable, identifier)
    XTableManager.CollectReadTablePath(path)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadAllByIntKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadAllByIntKey(path, xTable, identifier)
    else
        return packLoader.ReadAllByIntKey(path, xTable, identifier)
    end
end

function XTableManager.ReadAllByStringKey(path, xTable, identifier)
    XTableManager.CollectReadTablePath(path)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadAllByStringKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadAllByStringKey(path, xTable, identifier)
    else
        return packLoader.ReadAllByStringKey(path, xTable, identifier)
    end
end

function XTableManager.ReadByIntKey(path, xTable, identifier)
    XTableManager.CollectReadTablePath(path)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadByIntKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadByIntKey(path, xTable, identifier)
    else
        return packLoader.ReadByIntKey(path, xTable, identifier)
    end
end

function XTableManager.ReadByStringKey(path, xTable, identifier)
    XTableManager.CollectReadTablePath(path)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadByStringKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadByStringKey(path, xTable, identifier)
    else
        return packLoader.ReadByStringKey(path, xTable, identifier)
    end
end

function XTableManager.ReleaseAllCache()
    bytesLoader.ReleaseCache()
    packLoader.ReleaseCache()
end

-- 释放所有io
function XTableManager.ReleaseIo()
    packLoader.ReleaseIo()
end

function XTableManager.CheckTableExist(path)
    return CS.XTableManager.CheckTableExist(path)
end

-- 释放表格
function XTableManager.ReleaseTable(path)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Bytes then
        bytesLoader.ReleaseFull(path)
    elseif loadType == XTableManager.TableLoadType.Pack then
        packLoader.ReleaseFull(path)
    end
end

--region Table Monitor
function XTableManager.OnOpenBinaryTable(tablePath)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.OnOpenBinaryTable(tablePath)
end

function XTableManager.OnCloseBinaryTable(tablePath)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.OnCloseBinaryTable(tablePath)
end

function XTableManager.OnLoadBinary(tablePath, binary)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.OnLoadBinary(tablePath, binary)
end

function XTableManager.OnLoadBinaryWithSize(tablePath, binarySize)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.OnLoadBinaryWithSize(tablePath, binarySize)
end

function XTableManager.OnUnloadBinary(tablePath)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.OnUnloadBinary(tablePath)
end

function XTableManager.RegisterFixedStructuralSize(tablePath, structural, obj, isSelf)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.RegisterFixedStructuralSize(tablePath, structural, obj, isSelf)
end

function XTableManager.UpdateVolatileStructuralSize(tablePath, structural, obj, isSelf)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.UpdateVolatileStructuralSize(tablePath, structural, obj, isSelf)
end

function XTableManager.UpdateStringSize(tablePath, obj, isSelf)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.UpdateStringSize(tablePath, obj, isSelf)
end

function XTableManager.UpdateBinaryRows(tablePath, row)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.UpdateBinaryRows(tablePath, row)
end

function XTableManager.UpdateBinaryFields(tablePath, obj)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.UpdateBinaryFields(tablePath, obj)
end

function XTableManager.ReleaseBinaryFields(tablePath)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.ReleaseBinaryFields(tablePath)
end

function XTableManager.SetModuleByTabConfig(tablePath, module, tabScope)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.SetModuleByTabConfig(tablePath, module, tabScope)
end

function XTableManager.SetModuleByCacheType(tablePath, module, cacheType)
    if not BinaryConfigMonitorEnable then
        return
    end
    LuaTableConfigMonitor.SetModuleByCacheType(tablePath, module, cacheType)
end

--endregion