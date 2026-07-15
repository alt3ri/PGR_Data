---@class XTabConfig 表格配置类
local XTabConfig = XClass(nil, "XTabConfig")

local stringFormat = string.format

local IsWindowsEditor = XMain.IsWindowsEditor
local TEMP_TAB_READ_INTERVAL = 10

local TAB_FILE_EXTENSION = ".tab"
local CLIENT_START_NAME = "Client/"
local SHARE_START_NAME = "Share/"

-- 表格作用域
local TabScope = XConfigUtil.TabScope

local ReadHandlerDict = nil
local function GetReadHandler(readType)
    if not ReadHandlerDict then
        ReadHandlerDict = {
            [XConfigUtil.ReadType.Int] = XTableManager.ReadByIntKey,
            [XConfigUtil.ReadType.IntAll] = XTableManager.ReadAllByIntKey,
            [XConfigUtil.ReadType.String] = XTableManager.ReadByStringKey,
            [XConfigUtil.ReadType.StringAll] = XTableManager.ReadAllByStringKey,
        }
    end
    local func = ReadHandlerDict[readType]
    if not func then
        XLog.Error(string.format("不存在类型为：%s 的读表函数", readType))
    end
    return func
end

local function GetTablePath(dirPath, parentPath, tabName)
    local path
    if dirPath == XConfigUtil.DirectoryType.Client then
        path = stringFormat("%s%s/%s%s", CLIENT_START_NAME, parentPath, tabName, TAB_FILE_EXTENSION)
    elseif dirPath == XConfigUtil.DirectoryType.Custom then
        path = dirPath
    else
        path = stringFormat("%s%s/%s%s", SHARE_START_NAME, parentPath, tabName, TAB_FILE_EXTENSION)
    end
    return path
end

function XTabConfig:Ctor(moduleId)
    self._ModuleId = moduleId

    self._TabKey = nil
    self._TabPath = nil
    self._Args = nil
    self._ConfigDict = {}

    if IsWindowsEditor then
        self._CheckerHandler = {}
        self._TempTabReadTimes = {}
    end
end

function XTabConfig:InitConfigByTabKey(parentPath, tabKey, defaultScope)
    self:_UpdateTabKey(tabKey)
    self:_GetOrInitArgs()

    for tbName, v in pairs(tabKey) do
        local path = GetTablePath(v.DirPath, parentPath, tbName)
        if not self._Args[path] then
            local arg = {
                [1] = v.ReadFunc or XConfigUtil.ReadType.Int, -- 默认读int
                [2] = v.TableDefinedName and XTable[v.TableDefinedName] or XTable["XTable" .. tbName], -- XTable
                [3] = v.Identifier or "Id", -- 表格主键
                [4] = v.TabScope and (v.TabScope | defaultScope) or defaultScope,
            }
            self:_UpdateTabPath(tbName, path)
            self:AddSingleConfig(path, arg)
        end
    end
end

function XTabConfig:InitConfigByArgs(args)
    if not self._Args then
        self._Args = args
        --只用于Editor环境收集模块配置表
        XEventManager.DispatchEvent(XEventId.EVENT_INIT_CONFIG_BY_ARGS, args)
    else
        for path, arg in pairs(args) do
            if not self._Args[path] then
                self:AddSingleConfig(path, arg)
            end
        end
    end
end

function XTabConfig:AddSingleConfig(path, arg)
    --只用于Editor环境收集模块配置表
    XEventManager.DispatchEvent(XEventId.EVENT_ADD_SIGLE_CONFIG, path)

    if self._Args[path] then
        XLog.Error("请勿重复注册配置表: " .. path)
        return
    end
    self._Args[path] = arg
end

function XTabConfig:Get(path, tabScope)
    local args = self:_GetOrInitArgs()
    local arg = args[path]
    if not arg then
        XLog.Error("未注册配置表: " .. path)
        return
    end
    local scope = arg[4]
    if not self:_ContainScope(scope, tabScope) then
        XLog.Error(string.format("表格作用域错误, 配置作用域：%s 使用时作用域: %s", scope, tabScope))
        return
    end
    
    local config = self._ConfigDict[path]
    if config then
        return config
    end
    
    local handler = GetReadHandler(arg[1])
    if not handler then
        return
    end
    config = handler(path, arg[2], arg[3])
    XTableManager.SetModuleByTabConfig(path, self._ModuleId, tabScope)
    --非临时缓存时，存入缓存中
    if not self:_ContainScope(scope, TabScope.Temp) then
        self._ConfigDict[path] = config or {} --避免空表反复加载解析二进制
    end
    self:_CheckTab(path, arg, config)

    return config
end

function XTabConfig:GetByTabKey(tabKey, tabScope)
    local path = self:GetPathByTabKey(tabKey)
    return self:Get(path, tabScope)
end

function XTabConfig:GetConfigByPathAndId(path, key, tabScope, noTips)
    if not path then
        XLog.Error("The path given is not exist. ModuleId: " .. self._ModuleId)
        return
    end
    local allConfig = self:Get(path, tabScope)
    if not allConfig then
        return
    end
    local config = allConfig[key]
    if not config then
        if not noTips then
            XLog.Error(string.format("ModuleId:%s出错:找不到%s数据。搜索路径: %s 索引%s = %s", self._ModuleId, "唯一Id", path, "唯一Id", tostring(key)))
        end
        return nil
    end
    return config
end

function XTabConfig:GetConfigByTabKeyAndId(tabKey, key, tabScope, noTips)
    local path = self:GetPathByTabKey(tabKey)
    return self:GetConfigByPathAndId(path, key, tabScope, noTips)
end

function XTabConfig:GetPathByTabKey(tabKey)
    local key = self._TabKey[tabKey]
    if not key then
        XLog.Error("The tableKey given is not exist. ModuleId: " .. self._ModuleId)
        return
    end

    local path = self._TabPath[key]
    if not path then
        XLog.Error("The path given is not exist. ModuleId: " .. self._ModuleId)
        return
    end
    return path
end

function XTabConfig:Clear(path)
    local config = self._ConfigDict[path]
    if not config then
        return
    end
    XTableManager.ReleaseTable(path)
    self._ConfigDict[path] = nil
end

function XTabConfig:ClearControl()
    if not self._Args then
        return
    end
    for path, arg in pairs(self._Args) do
        local scope = arg[4]
        if self:_ContainScope(scope, TabScope.Control)
                and not self:_ContainScope(scope, TabScope.Agency) then
            local config = self._ConfigDict[path]
            if config then
                XTableManager.ReleaseTable(path)
                self._ConfigDict[path] = nil
                if IsWindowsEditor then
                    WeakRefCollector.AddRef(WeakRefCollector.Type.Config, config, path)
                end
            end
        end
    end
end

function XTabConfig:Release()
    for path, _ in pairs(self._ConfigDict) do
        XTableManager.ReleaseTable(path)
    end
    self._ConfigDict = nil
    self._Args = nil
    self._TabKey = nil
    self._TabPath = nil
    self._CheckerHandler = nil
    self._TempTabReadTimes = nil
end

function XTabConfig:ContainArgs(path)
    if not self._Args then
        return false
    end
    return self._Args[path] and true or false
end

function XTabConfig:AddCheckerByPath(path, func, caller)
    if not IsWindowsEditor then
        return
    end
    if not self._CheckerHandler[path] then
        self._CheckerHandler[path] = { func, caller }
    else
        XLog.Error(string.format("重复添加表格检查器，表格路径：%s", path))
    end
end

function XTabConfig:AddCheckerByTabKey(tabKey, func, caller)
    if not IsWindowsEditor then
        return
    end
    local path = self:GetPathByTabKey(tabKey)
    if not path then
        XLog.Error(string.format("表格路径不存在，表格key：%s", tabKey))
    end
    self:AddCheckerByPath(path, func, caller)
end

--region 私有方法

function XTabConfig:_ContainScope(targetScope, tabScope)
    return (targetScope & tabScope) ~= 0
end

function XTabConfig:_UpdateTabKey(tabKey)
    if not self._TabKey then
        self._TabKey = {}
    end
    for k, v in pairs(tabKey) do
        self._TabKey[v] = k
    end
end

function XTabConfig:_UpdateTabPath(tbName, path)
    if not self._TabPath then
        self._TabPath = {}
    end
    self._TabPath[tbName] = path
end

function XTabConfig:_GetOrInitArgs()
    if not self._Args then
        self._Args = {}
    end
    return self._Args
end

function XTabConfig:_CheckTab(path, arg, config)
    if not IsWindowsEditor then
        return
    end
    local checker = self._CheckerHandler[path]
    if checker then
        checker[1](checker[2], config)
    end
    local scope = arg[4]
    if self:_ContainScope(scope, TabScope.Temp) then
        --增加时间检查
        local time = os.time()
        local lastTime = self._TempTabReadTimes[path]
        if lastTime and time - lastTime <= TEMP_TAB_READ_INTERVAL then
            XLog.Error(string.format("临时表格读取过于频繁，请检查表格读取逻辑，表格路径：%s", path))
        end
        self._TempTabReadTimes[path] = time
        WeakRefCollector.AddRef(WeakRefCollector.Type.Config, config, path)
    end

    if self:_ContainScope(scope, TabScope.Control) then
        --模块内的表格增加弱引用
        if not XMVCA:_CheckControlRef(self._ModuleId) then
            XLog.Error(string.format("配置表:%s为control使用, 但模块:%s Control已经释放.", path, self._ModuleId))
        end
    end
end

--endregion 私有方法

return XTabConfig