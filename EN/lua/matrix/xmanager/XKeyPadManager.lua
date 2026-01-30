---按键设置管理器
---处理按键设置的服务器同步逻辑
---@class XKeyPadManager
XKeyPadManager = XKeyPadManager or {}

local RequestProto = {
    SyncPlayerKeyPadSettingRequest = "SyncPlayerKeyPadSettingRequest", -- 首次同步按键设置
    RecordPlayerKeyPadSettingRequest = "RecordPlayerKeyPadSettingRequest", -- 保存按键设置
}

-- 是否已经完成首次同步
local _HasSyncedToServer = false

-- 是否有服务端按键设置数据（用于判断 IsOpenUiFightCustomRed）
local _HasServerKeyPadData = false

-- Debug模式：禁止同步功能（用于创建新号并设置本地数据，不同步到服务端）
local _DebugDisableSync = false

-- Debug模式：是否输出日志和生成报告（默认关闭）
local _DebugEnableLog = false

-- 延时发送定时器ID（用于避免间隔太短导致服务端报错）
local _SyncTimerId = nil

---Debug日志输出（仅在Debug模式下输出）
---@param message string 日志消息
local function DebugLog(message)
    if _DebugEnableLog then
        XLog.Debug(message)
    end
end

---Debug错误日志输出（仅在Debug模式下输出）
---@param message string 错误消息
local function DebugError(message)
    if _DebugEnableLog then
        XLog.Error(message)
    end
end

---Debug警告日志输出（仅在Debug模式下输出）
---@param message string 警告消息
local function DebugWarning(message)
    if _DebugEnableLog then
        XLog.Warning(message)
    end
end

---将C#的XKeyPadComponentData转换为Lua table
---@param componentData XKeyPadComponentData C#对象
---@return table Lua table
local function ConvertComponentDataToLuaTable(componentData)
    if not componentData then
        return nil
    end
    return {
        PositionX = componentData.PositionX,
        PositionY = componentData.PositionY,
        Scale = componentData.Scale,
        Alpha = componentData.Alpha,
        IsActive = componentData.IsActive,
        IsShowPcTips = componentData.IsShowPcTips
    }
end

---将C#的Dictionary<int, XKeyPadComponentData>转换为Lua table
---@param uiData Dictionary<int, XKeyPadComponentData> C# Dictionary
---@return table Lua table
local function ConvertUiDataToLuaTable(uiData)
    if not uiData then
        return {}
    end
    local luaTable = {}
    -- 遍历C# Dictionary (XLua支持直接遍历)
    for key, value in pairs(uiData) do
        if key and value then
            luaTable[key] = ConvertComponentDataToLuaTable(value)
        end
    end
    return luaTable
end

---将C#的XKeyPadPanelCustomData转换为Lua table
---@param panelData XKeyPadPanelCustomData C#对象
---@return table Lua table
local function ConvertPanelDataToLuaTable(panelData)
    if not panelData then
        return nil
    end
    return {
        SchemeId = panelData.SchemeId,
        Version = panelData.Version,
        BallDirection = panelData.BallDirection,
        IsShowFps = panelData.IsShowFps,
        IsShowSignal = panelData.IsShowSignal,
        IsShowQteIcon = panelData.IsShowQteIcon,
        JoystickType = panelData.JoystickType,
        SafeScreenAreaWidth = panelData.SafeScreenAreaWidth,
        SafeScreenAreaHeight = panelData.SafeScreenAreaHeight,
        UiData = ConvertUiDataToLuaTable(panelData.UiData)
    }
end

---将C#的List<XKeyPadPanelCustomData>转换为Lua table数组
---@param dataList List<XKeyPadPanelCustomData> C# List
---@return table Lua table数组
local function ConvertDataListToLuaTable(dataList)
    if not dataList or dataList.Count == 0 then
        return {}
    end
    local luaTable = {}
    -- 遍历C# List (使用索引访问，索引从0开始)
    for i = 0, dataList.Count - 1 do
        local panelData = dataList[i]
        if panelData then
            table.insert(luaTable, ConvertPanelDataToLuaTable(panelData))
        end
    end
    return luaTable
end

---初始化服务端数据
---@param keyPadSetting table 服务端返回的按键设置数据
function XKeyPadManager.InitFromServer(keyPadSetting)
    -- PC模式：不同步按键设置，只在本地保存
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        DebugLog("[KeyPad] InitFromServer: [PC模式] 跳过从服务端初始化数据，只在本地保存")
        return
    end
    
    -- Debug模式：禁止同步功能
    if _DebugDisableSync then
        DebugLog("[KeyPad] InitFromServer: [Debug模式] 同步功能已禁用，跳过初始化服务端数据")
        return
    end
    
    
    if not keyPadSetting then
        DebugLog("[KeyPad] InitFromServer: keyPadSetting is nil")
        return
    end

    DebugLog("[KeyPad] InitFromServer: 开始初始化服务端数据")
    if keyPadSetting.CurSchemeId then
        DebugLog(string.format("[KeyPad] InitFromServer: CurSchemeId = %d", keyPadSetting.CurSchemeId))
    else
        DebugLog("[KeyPad] InitFromServer: CurSchemeId 不存在")
    end
    
    -- 服务端返回的字段名是 PlayerKeyPadSettingList，需要转换为 KeyPadCustomDataList
    local keyPadCustomDataList = keyPadSetting.PlayerKeyPadSettingList or keyPadSetting.KeyPadCustomDataList
    
    -- 判断是否有服务端数据（用于 IsOpenUiFightCustomRed）
    local hasData = false
    if keyPadCustomDataList then
        local count = 0
        if type(keyPadCustomDataList) == "table" then
            count = #keyPadCustomDataList
        else
            count = keyPadCustomDataList.Count
        end
        hasData = count > 0 or (keyPadSetting.CurSchemeId ~= nil and keyPadSetting.CurSchemeId >= 0)
    else
        hasData = keyPadSetting.CurSchemeId ~= nil and keyPadSetting.CurSchemeId >= 0
    end
    _HasServerKeyPadData = hasData
    
    if keyPadCustomDataList then
        -- 检查是Lua table还是C# List
        local count = 0
        if type(keyPadCustomDataList) == "table" then
            -- Lua table，使用#获取长度
            count = #keyPadCustomDataList
        else
            -- C# List，使用Count属性
            count = keyPadCustomDataList.Count
        end
        DebugLog(string.format("[KeyPad] InitFromServer: KeyPadCustomDataList 存在，类型 = %s, count = %d", 
            type(keyPadCustomDataList), count))
        
        -- 统一字段名，转换为 C# 期望的格式
        local normalizedKeyPadSetting = {
            CurSchemeId = keyPadSetting.CurSchemeId,
            KeyPadCustomDataList = keyPadCustomDataList
        }
        
        -- 调用C#层接口初始化服务端数据
        CS.XCustomUi.Instance:InitFromServer(normalizedKeyPadSetting)
    else
        DebugLog("[KeyPad] InitFromServer: KeyPadCustomDataList 不存在或为nil")
        -- 即使没有数据，也调用C#层，传递空数据
        local normalizedKeyPadSetting = {
            CurSchemeId = keyPadSetting.CurSchemeId,
            KeyPadCustomDataList = {}
        }
        CS.XCustomUi.Instance:InitFromServer(normalizedKeyPadSetting)
    end
    
    -- 标记已完成同步
    _HasSyncedToServer = true
    DebugLog(string.format("[KeyPad] InitFromServer: 初始化服务端数据完成，HasServerKeyPadData = %s", tostring(_HasServerKeyPadData)))
end

---首次同步本地数据到服务端
---触发条件：版本更新后首次登录，服务端数据为空，本地存在缓存数据
function XKeyPadManager.TryFirstSync()
    -- PC模式：不同步按键设置，只在本地保存
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        DebugLog("[KeyPad] TryFirstSync: [PC模式] 跳过首次同步，只在本地保存")
        return
    end
    
    -- Debug模式：禁止同步功能
    if _DebugDisableSync then
        DebugLog("[KeyPad] TryFirstSync: [Debug模式] 同步功能已禁用，跳过同步")
        return
    end
    
    
    DebugLog("[KeyPad] TryFirstSync: 开始尝试首次同步")
    
    -- 如果已经同步过，不再同步
    if _HasSyncedToServer then
        DebugLog("[KeyPad] TryFirstSync: 已经同步过，跳过")
        return
    end

    -- 检查C#层是否有本地缓存数据
    local hasLocalData = CS.XCustomUi.Instance:HasLocalKeyPadSetting()
    DebugLog(string.format("[KeyPad] TryFirstSync: HasLocalKeyPadSetting = %s", tostring(hasLocalData)))
    if not hasLocalData then
        DebugLog("[KeyPad] TryFirstSync: 没有本地缓存数据，跳过")
        return
    end

    -- 获取本地按键设置数据
    local localKeyPadSetting = CS.XCustomUi.Instance:GetLocalKeyPadSetting()
    if not localKeyPadSetting then
        DebugLog("[KeyPad] TryFirstSync: GetLocalKeyPadSetting 返回 nil，跳过")
        return
    end
    
    -- 检查KeyPadCustomDataList是否存在且不为空
    local keyPadCustomDataList = localKeyPadSetting.KeyPadCustomDataList
    if not keyPadCustomDataList or keyPadCustomDataList.Count == 0 then
        DebugLog("[KeyPad] TryFirstSync: KeyPadCustomDataList 为空，跳过")
        return
    end

    DebugLog(string.format("[KeyPad] TryFirstSync: 准备同步，CurSchemeId = %d, 自定义方案数量 = %d", 
        localKeyPadSetting.CurSchemeId or 0, keyPadCustomDataList.Count))

    -- 将C# List转换为Lua table数组
    local playerKeyPadSettingList = ConvertDataListToLuaTable(keyPadCustomDataList)
    DebugLog(string.format("[KeyPad] TryFirstSync: 转换后的Lua table数组长度 = %d", #playerKeyPadSettingList))

    -- 构造请求
    local req = {
        CurSchemeId = localKeyPadSetting.CurSchemeId,
        PlayerKeyPadSettingList = playerKeyPadSettingList
    }

    -- 发送请求
    DebugLog("[KeyPad] TryFirstSync: 发送 SyncPlayerKeyPadSettingRequest 请求")
    XNetwork.Call(RequestProto.SyncPlayerKeyPadSettingRequest, req, function(res)
        if res.Code == XCode.Success then
            -- 同步成功，标记有服务端数据
            _HasServerKeyPadData = true
            -- 同步成功，清除本地缓存（可选，保留作为备份）
            -- CS.XCustomUi.Instance:ClearLocalKeyPadSetting()
            _HasSyncedToServer = true
            DebugLog("[KeyPad] TryFirstSync: 首次同步按键设置成功")
        else
            DebugError(string.format("[KeyPad] TryFirstSync: 首次同步按键设置失败，错误码 = %s", tostring(res.Code)))
        end
    end)
end

---同步当前按键设置到服务端
---在保存按键设置时调用
---实际执行同步到服务端的逻辑
local function DoSyncToServer()
    -- PC模式：不同步按键设置，只在本地保存
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        DebugLog("[KeyPad] SyncToServer: [PC模式] 跳过同步到服务端，只在本地保存")
        return
    end
    
    -- Debug模式：禁止同步功能
    if _DebugDisableSync then
        DebugLog("[KeyPad] SyncToServer: [Debug模式] 同步功能已禁用，跳过同步")
        return
    end
    
    DebugLog("[KeyPad] SyncToServer: 开始同步按键设置到服务端")
    
    -- 获取当前按键设置数据
    local keyPadSetting = CS.XCustomUi.Instance:GetLocalKeyPadSetting()
    if not keyPadSetting then
        DebugLog("[KeyPad] SyncToServer: GetLocalKeyPadSetting 返回 nil，跳过")
        return
    end

    local customDataCount = 0
    if keyPadSetting.KeyPadCustomDataList then
        customDataCount = keyPadSetting.KeyPadCustomDataList.Count
    end
    
    DebugLog(string.format("[KeyPad] SyncToServer: CurSchemeId = %d, 自定义方案数量 = %d", 
        keyPadSetting.CurSchemeId or 0, customDataCount))

    -- 根据CurSchemeId找到当前选中的方案
    local curSchemeId = keyPadSetting.CurSchemeId
    if not curSchemeId then
        DebugError("[KeyPad] SyncToServer: CurSchemeId 不存在，无法保存")
        return
    end

    -- 判断是否为默认样式（NewDefault = 0, OldDefault = 4）
    local isDefaultScheme = (curSchemeId == 0) or (curSchemeId == 4)
    
    -- 构造请求，始终包含CurSchemeId
    local req = {
        CurSchemeId = curSchemeId
    }
    
    -- 如果是默认样式，只发送CurSchemeId，不发送KeyPadCustomData
    if isDefaultScheme then
        DebugLog(string.format("[KeyPad] SyncToServer: 当前为默认样式 SchemeId = %d，只发送 CurSchemeId", curSchemeId))
    else
        -- 非默认样式，需要发送KeyPadCustomData
        -- 从KeyPadCustomDataList中找到当前选中的方案
        local currentCustomData = nil
        if keyPadSetting.KeyPadCustomDataList and keyPadSetting.KeyPadCustomDataList.Count > 0 then
            for i = 0, keyPadSetting.KeyPadCustomDataList.Count - 1 do
                local customData = keyPadSetting.KeyPadCustomDataList[i]
                if customData and customData.SchemeId == curSchemeId then
                    currentCustomData = customData
                    break
                end
            end
        end

        if not currentCustomData then
            DebugError(string.format("[KeyPad] SyncToServer: 找不到 SchemeId = %d 的方案数据", curSchemeId))
            return
        end

        -- 将C#的XKeyPadPanelCustomData转换为Lua table
        local keyPadCustomData = ConvertPanelDataToLuaTable(currentCustomData)
        req.KeyPadCustomData = keyPadCustomData
        DebugLog(string.format("[KeyPad] SyncToServer: 准备保存方案 SchemeId = %d，包含 KeyPadCustomData", curSchemeId))
    end

    -- 发送请求
    DebugLog("[KeyPad] SyncToServer: 发送 RecordPlayerKeyPadSettingRequest 请求")
    XNetwork.Call(RequestProto.RecordPlayerKeyPadSettingRequest, req, function(res)
        if res.Code == XCode.Success then
            -- 同步成功，标记有服务端数据
            _HasServerKeyPadData = true
            DebugLog("[KeyPad] SyncToServer: 同步按键设置到服务端成功")
        else
            DebugError(string.format("[KeyPad] SyncToServer: 同步按键设置到服务端失败，错误码 = %s", tostring(res.Code)))
        end
    end)
end

function XKeyPadManager.SyncToServer()
    -- 如果已有待发送的定时器，先取消它
    if _SyncTimerId then
        XScheduleManager.UnSchedule(_SyncTimerId)
        _SyncTimerId = nil
        DebugLog("[KeyPad] SyncToServer: 取消之前的延时发送任务")
    end
    
    -- 延时0.5秒后发送，避免间隔太短导致服务端报错
    DebugLog("[KeyPad] SyncToServer: 设置延时发送，0.5秒后执行")
    _SyncTimerId = XScheduleManager.ScheduleOnce(function()
        _SyncTimerId = nil
        DoSyncToServer()
    end, 500)
end

---清除本地缓存（用于测试第一次登录）
function XKeyPadManager.ClearLocalCache()
    if CS.XCustomUi.Instance and CS.XCustomUi.Instance.ClearLocalKeyPadSetting then
        CS.XCustomUi.Instance:ClearLocalKeyPadSetting()
        DebugLog("[KeyPad] 已清除本地缓存，下次登录将模拟第一次登录")
    else
        DebugWarning("[KeyPad] ClearLocalKeyPadSetting 方法不存在")
    end
end

---设置Debug模式：禁止同步功能（用于创建新号并设置本地数据）
---@param enable boolean 是否启用（true=禁止同步，false=允许同步）
function XKeyPadManager.SetDebugDisableSync(enable)
    _DebugDisableSync = enable or false
    if _DebugDisableSync then
        DebugLog("[KeyPad] Debug模式已启用：禁止同步功能，可以设置本地数据但不会同步到服务端")
    else
        DebugLog("[KeyPad] Debug模式已禁用：允许同步功能")
    end
end

---获取Debug模式状态（禁止同步）
---@return boolean
function XKeyPadManager.IsDebugDisableSync()
    return _DebugDisableSync
end

---设置Debug模式：是否输出日志和生成报告
---@param enable boolean 是否启用（true=输出日志，false=不输出）
function XKeyPadManager.SetDebugEnableLog(enable)
    _DebugEnableLog = enable or false
end

---获取Debug日志模式状态
---@return boolean
function XKeyPadManager.IsDebugEnableLog()
    return _DebugEnableLog
end

---获取 IsOpenUiFightCustomRed（通过判断是否有服务端按键设置数据）
---如果有服务端数据，说明用户已经打开过布局设置
---如果没有服务端数据，检查是否有本地数据（兼容旧数据）
---@return boolean
function XKeyPadManager.IsOpenUiFightCustomRed()
    -- 如果有服务端数据，说明用户已经打开过布局设置
    if _HasServerKeyPadData then
        return true
    end
    
    -- 如果没有服务端数据，检查是否有本地数据（兼容旧数据）
    -- 如果C#层有本地数据，也认为用户已经打开过
    if CS.XCustomUi.Instance and CS.XCustomUi.Instance.HasLocalKeyPadSetting then
        local hasLocalData = CS.XCustomUi.Instance:HasLocalKeyPadSetting()
        if hasLocalData then
            return true
        end
    end
    
    -- 检查C#层的旧PlayerPrefs数据（兼容迁移）
    if CS.UnityEngine.PlayerPrefs.HasKey("IsOpenUiFightCustomRed") then
        local value = CS.UnityEngine.PlayerPrefs.GetInt("IsOpenUiFightCustomRed", 0)
        if value ~= 0 then
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- Debug功能：用于测试第一次登录同步
-- ============================================================================
-- 使用场景：
-- 1. 先用旧逻辑登录，设置键盘（会有本地缓存）
-- 2. 改用新逻辑登录，测试第一次登录同步和第二次登录
--
-- 使用方法（禁止同步功能）：
-- 1. 启用禁止同步模式：XKeyPadManager.SetDebugDisableSync(true)
--    - InitFromServer、TryFirstSync 和 SyncToServer 都不会执行
--    - 可以正常设置本地数据（在C#层）
-- 2. 创建新号，设置键盘（本地会有数据，但不会同步到服务端）
-- 3. 禁用禁止同步模式：XKeyPadManager.SetDebugDisableSync(false)
-- 4. 重新登录，会走TryFirstSync流程（因为服务端没有数据，本地有数据）
--
-- 完整测试流程示例：
--   -- 步骤1：禁止同步，创建新号并设置本地数据
--   XKeyPadManager.SetDebugDisableSync(true)     -- 禁止同步功能
--   -- 创建新号，设置键盘（本地会有数据，但不会同步到服务端）
--   
--   -- 步骤2：开启同步功能，测试第一次登录同步
--   XKeyPadManager.SetDebugDisableSync(false)    -- 允许同步功能
--   -- 重新登录，会走TryFirstSync流程（服务端没有数据，本地有数据）
--   
--   -- 步骤3：第二次登录，会走InitFromServer流程（服务端已有数据）
-- ============================================================================

return XKeyPadManager

