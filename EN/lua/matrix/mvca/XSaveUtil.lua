---@class XSaveUtil
local XSaveUtil = XClass(nil, 'XSaveUtil')

local VERSION_KEY = '__Version' -- 记录版本号的字段
local IS_CUSTOM_VERSION_KEY = '__IsCustomVersion' -- 记录是否是自定义版本号的字段
local DATA_OWNER_ID_KEY = '__OwnerId' -- 记录数据所有者Id的字段
local DEFAULT_DATA_BLOCK_KEY = 'Default' -- 默认数据块的唯一标识符

function XSaveUtil:Ctor(id)
    self._Id = id
    self._IsVersionCheck = true
    self._DataKeyPrefix = 'MVCAModule_' .. self._Id .. '_'
    self._DataBlockMap = {} -- 存储一系列相互独立的数据块(可能一个MVCA对应多个子系统，不同子系统缓存数据的生命周期不一致)
    self._CustomVersionGetFuncMap = {} -- 存储一系列自定义的版本获取委托
end

function XSaveUtil:ReleaseData()
    self._DataBlockMap = {}
end

---@param key @自定义数据块的key，不传加载默认数据块
function XSaveUtil:LoadData(key)
    local blockKey = key or DEFAULT_DATA_BLOCK_KEY
    local dataKey = self._DataKeyPrefix .. blockKey .. '_' .. XPlayer.Id

    local dataBlock = XSaveTool.GetData(dataKey)

    local needNewEmptyData = false

    if dataBlock == nil then
        needNewEmptyData = true
    elseif self._IsVersionCheck and self:_CheckIsVersionChanged(dataBlock, blockKey) then
        needNewEmptyData = true
        -- 删除旧数据缓存
        XSaveTool.RemoveData(dataKey)
    end

    -- 没有数据，或数据过期时，需要重新创建空数据
    if needNewEmptyData then
        dataBlock = {
            __Version = self:GetCurVersion(blockKey),
            __IsCustomVersion = self:GetCurDataBlockIsCustomVersion(blockKey),
            __OwnerId = XPlayer.Id,
        }
    end

    -- 将数据添加到缓存字典中
    self._DataBlockMap[blockKey] = dataBlock
end

--region 常规数据访问接口

--- 从默认数据块中获取数据
function XSaveUtil:GetData(key)
    return self:GetDataByBlockKey(DEFAULT_DATA_BLOCK_KEY, key)
end

--- 将数据写入默认数据块中
function XSaveUtil:SaveData(key, value)
    self:SaveDataByBlockKey(DEFAULT_DATA_BLOCK_KEY, key, value)
end

--- 清除默认数据块数据
function XSaveUtil:ClearData()
    self:ClearDataByBlockKey(DEFAULT_DATA_BLOCK_KEY)
end

--endregion

--region 数据访问接口扩展-支持细化数据分布

--- 读取指定数据块中的数据
function XSaveUtil:GetDataByBlockKey(blockKey, key)
    local dataBlock = self._DataBlockMap[blockKey]

    if not dataBlock or XPlayer.Id ~= dataBlock.__OwnerId then
        self:LoadData(blockKey)
    end

    dataBlock = self._DataBlockMap[blockKey]

    if dataBlock then
        return dataBlock[key]
    end

    return nil
end

--- 将数据写入指定数据块中
function XSaveUtil:SaveDataByBlockKey(blockKey, key, value)
    -- 不允许篡改版本信息
    if key == VERSION_KEY or key == IS_CUSTOM_VERSION_KEY then
        XLog.Error('Module: ' .. tostring(self._Id) .. ' 在缓存本地数据时尝试修改版本信息')
        return
    end
    -- 不允许篡改数据所有者
    if key == DATA_OWNER_ID_KEY then
        XLog.Error('Module: ' .. tostring(self._Id) .. ' 在缓存本地数据时尝试数据所有者')
        return
    end

    local dataBlock = self._DataBlockMap[blockKey]

    if not dataBlock or XPlayer.Id ~= dataBlock.__OwnerId then
        self:LoadData()
    end

    dataBlock = self._DataBlockMap[blockKey]

    if dataBlock then
        local dataKey = self._DataKeyPrefix .. blockKey .. '_' .. XPlayer.Id

        dataBlock[key] = value

        XSaveTool.SaveData(dataKey, dataBlock)
    end
end

---@param key @自定义数据块的key，不传则使用默认数据块
function XSaveUtil:ClearDataByBlockKey(key)
    local blockKey = key or DEFAULT_DATA_BLOCK_KEY

    local dataKey = self._DataKeyPrefix .. blockKey .. '_' .. XPlayer.Id

    XSaveTool.RemoveData(dataKey)

    self._DataBlockMap[blockKey] = nil
end

--endregion

--region 数据差异检查相关

--- 版本检查启用的总控开关
function XSaveUtil:SetVersionCheckEnable(isVersionCheck)
    self._IsVersionCheck = isVersionCheck
end

--- 自定义版本号获取接口
--- 用于某些常驻活动，跨多个版本才换新一期的情况
function XSaveUtil:SetCustomVersionGetFunc(versionGetFunc, customBlockKey)
    if versionGetFunc == nil or not type(versionGetFunc) == 'function' then
        XLog.Error('注册的自定义版本获取方法参数不是一个function类型：', versionGetFunc)
        return
    end
    local blockKey = customBlockKey or DEFAULT_DATA_BLOCK_KEY
    
    self._CustomVersionGetFuncMap[blockKey] = versionGetFunc
end

function XSaveUtil:GetCurVersion(customBlockKey)
    local blockKey = customBlockKey or DEFAULT_DATA_BLOCK_KEY
    
    local customGetFunc = self._CustomVersionGetFuncMap[blockKey]
    
    return customGetFunc ~= nil and customGetFunc() or CS.XRemoteConfig.ApplicationVersion
end

--- 判断指定的数据块（不传参则是默认数据块）
function XSaveUtil:GetCurDataBlockIsCustomVersion(customBlockKey)
    local blockKey = customBlockKey or DEFAULT_DATA_BLOCK_KEY

    local customGetFunc = self._CustomVersionGetFuncMap[blockKey]

    return customGetFunc ~= nil
end

--- 检查数据版本是否改变
function XSaveUtil:_CheckIsVersionChanged(dataBlock, customBlockKey)
    if not dataBlock then
        return false
    end
    
    local curVersion = self:GetCurVersion(customBlockKey)
    
    local oldVersion = dataBlock.__Version
    
    -- 如果数据版本类型和当前版本类型不同，则一定改变
    if self:GetCurDataBlockIsCustomVersion(customBlockKey) ~= dataBlock.__IsCustomVersion then
        return true
    end
    
    return curVersion ~= oldVersion
end

--endregion

return XSaveUtil