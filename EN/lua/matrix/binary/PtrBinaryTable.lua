---@type UnityNativeHelper
local UnityNativeHelper = require("UnityNativeHelper")
local BinaryManager = CS.BinaryManager
local HEAD_LEN = 4
local PtrBinaryTable = {}
local tableEmpty = {}

local DefaultOfTypeNew = {
    [1] = false,
    [2] = nil,
    [3] = fix.zero,
    [4] = tableEmpty,
    [5] = tableEmpty,
    [6] = tableEmpty,
    [7] = tableEmpty,
    [8] = tableEmpty,
    [9] = tableEmpty,
    [10] = tableEmpty,
    [11] = tableEmpty,
    [12] = tableEmpty,
    [13] = tableEmpty,
    [14] = 0,
    [15] = 0,
    [16] = fix2.zero,
    [17] = fix3.zero,
    [18] = fixquaternion.identity,
    [19] = tableEmpty,
    [20] = tableEmpty,
    [21] = tableEmpty,
}

--读取全部
function PtrBinaryTable.ReadAll(path, identifier)
    local bt = PtrBinaryTable.ReadHandle(path)

    if not bt then
        return nil
    end

    local tab = bt:ReadAllContent(identifier, nil, true)
    bt:ReleaseFull()
    bt = nil

    return tab
end

--读取句柄
function PtrBinaryTable.ReadHandle(path)
    local bt = PtrBinaryTable.New(path)

    if not bt or not bt:IsTableExist() then
        return nil
    end

    return bt
end

function PtrBinaryTable.New(path)
    local temp = {}
    setmetatable(temp, { __index = PtrBinaryTable })
    temp:Ctor(path)
    return temp
end

function PtrBinaryTable:__ReadInt()
    if self.Length < HEAD_LEN then
        XLog.Error(string.format("%s ReadInt Error, file might be empty", self.FilePath))
        return 0
    end
    local b1, b2, b3, b4 = UnityNativeHelper.read_bytes(self.BytesPtr, 4)
    return b1 | b2 << 8 | b3 << 16 | b4 << 24
end

function PtrBinaryTable:__GetReader(len, offset)
    offset = offset or 0
    if offset + len > self.Length then
        XLog.Error(string.format("%s GetReader out of range exception", self.FilePath))
        return nil
    end
    local reader = ReaderPool.GetReader()
    reader:LoadBytes(self.BytesPtr, len, offset)
    reader:SetBinaryFileFolder(self)
    return reader
end

function PtrBinaryTable:__ResetReader(reader, len, offset)
    offset = offset or 0
    if offset + len > self.Length then
        XLog.Error(string.format("%s GetReader out of range exception", self.FilePath))
        return nil
    end
    reader:Reset(len, offset)
end

-- 关闭读取器
function PtrBinaryTable:__CloseReader(reader)
    ReaderPool.ReleaseReader(reader)
end

function PtrBinaryTable:_InitMetaTable()
    local colType = self.colTypes
    local colNames = self.colNames
    local colNameIndex = {}
    for i = 1, #colNames do
        local name = colNames[i]
        colNameIndex[name] = i
    end

    local metaTable = {}
    metaTable.__index = function(tbl, colName)
        local idx = colNameIndex[colName]
        if not idx or not tbl then
            return nil
        end

        local result = rawget(tbl, idx)
        if not result then
            local resultType = colType[idx]
            if not resultType then
                XLog.Error(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", colName))
            end

            result = DefaultOfTypeNew[resultType]
        end

        return result
    end

    metaTable.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    metaTable.__metatable = "readonly table"
    metaTable.__pairs = function(t)
        self:InitBinary()
        local function stateless_iter(tbl, key)
            local nk, v = next(tbl, key)

            if nk and v then
                local nv = t[v] or t[nk]
                return nk, nv
            end
        end

        return stateless_iter, colNameIndex, nil
    end

    self.MetaTable = metaTable
    XTableManager.RegisterFixedStructuralSize(self.FilePath, "m_metaTable", self.MetaTable, false)
end

function PtrBinaryTable:Ctor(path)
    self.FilePath = path
end

function PtrBinaryTable:IsTableExist()
    return CS.XTableManager.FileExists(self.FilePath)
end

function PtrBinaryTable:GetRowCount()
    self:InitBinary()
    return self.row
end

function PtrBinaryTable:InitBinary()
    if self.m_initialized then return end

    self.Bytes = BinaryManager.LoadNativePtrByte(self.FilePath)
    if not self.Bytes then
        XLog.Error(string.format("PtrBinaryTable.InitBinary 加载文件失败 %s", self.FilePath))
        return nil
    end
    self.BytesPtr = self.Bytes:GetDataPtr()
    self.Length = self.Bytes.Length
    --初始化
    XTableManager.OnLoadBinaryWithSize(self.FilePath, self.Length)
    XTableManager.RegisterFixedStructuralSize(self.FilePath, "m_tableName", self.FilePath, false)
    local result = self:Init()
    return result
end

--初始化表头
function PtrBinaryTable:Init()
    local len = self:__ReadInt()
    local reader = self:__GetReader(len, HEAD_LEN)

    self.col = reader:ReadInt()
    self.infoTrunkLen = len

    self.colTypes = {}
    self.colNames = {}
    for i = 1, self.col do
        table.insert(self.colTypes, reader:ReadInt())
        local name = reader:ReadString()
        table.insert(self.colNames, name)
    end

    self.hasPrimarykey = reader:ReadBool()
    if self.hasPrimarykey then
        local primarykeyIndex = reader:ReadInt() or 0
        self.primarykey = self.colNames[primarykeyIndex + 1]
        -- self.primarykey = reader:ReadString()
        self.primarykeyLen = reader:ReadInt()
    end

    for i = 1, #self.colNames do
        local name = self.colNames[i]
        if self.primarykey == name then
            self.primarykeyType = self.colTypes[i]
            break
        end
    end

    self.rowTrunkLen = reader:ReadInt()
    self.row = reader:ReadInt() or 0
    self.contentTrunkLen = reader:ReadInt()
    self.m_initialized = true

    XTableManager.UpdateBinaryRows(self.FilePath, self.row)
    XTableManager.RegisterFixedStructuralSize(self.FilePath, "m_properyNames", self.colNames, false)
    XTableManager.RegisterFixedStructuralSize(self.FilePath, "m_properyTypeIndex", self.colTypes, false)

    if not self.contentTrunkLen then
        if XMain.IsDebug then
            XLog.Warning(string.format("PtrBinaryTable:InitBinary,%s, 空表", self.FilePath))
        end
        self:__CloseReader(reader)
        return
    end

    self:_InitMetaTable()
    self:__CloseReader(reader)

    self.cachesCount = 0
    if not self.m_skipCache then
        self.caches = {}
    end
    self.m_poolColumnSize = -1

    return true
end

-- 获取表头后的位置，后面是行信息块
function PtrBinaryTable:GetIndexTrunkPosition()
    self:InitBinary()
    return self.infoTrunkLen + HEAD_LEN
end

function PtrBinaryTable:GetAfterPrimaryKeyTrunkPosition()
    local position = self:GetIndexTrunkPosition()
    if self.hasPrimarykey then
        position = position + self.primarykeyLen
    end
    return position
end

--获取内容块位置
function PtrBinaryTable:GetContentTrunkPosition()
    return self:GetAfterPrimaryKeyTrunkPosition() + self.rowTrunkLen
end

-- 获取字符串池偏移数组的开始位置
function PtrBinaryTable:GetPoolOffsetTrunkStartPosition()
    return self:GetContentTrunkPosition() + self.contentTrunkLen
end

-- 获取字符串池内容的开始位置
function PtrBinaryTable:GetPoolContentTrunkStartPosition()
    return self:GetPoolOffsetTrunkStartPosition() + self.m_poolContentStartPos
end

--获取内容块
function PtrBinaryTable:GetContentTrunkReader()
    local position = self:GetContentTrunkPosition()

    if position < 0 then
        return
    end

    local reader = self:__GetReader(self.contentTrunkLen, position)
    return reader
end

-- 获取所有数据
function PtrBinaryTable:ReadAllContent(identifier, isPair, skipCache)
    self.m_skipCache = skipCache

    local reader = self:GetContentTrunkReader()
    if not reader then
        XLog.Error(string.format("可能是空表 路径:%s 请检查", self.FilePath))
        return tableEmpty
    end

    local row = self.row
    local col = self.col
    local colType = self.colTypes
    local colNames = self.colNames

    local index = 0
    for i = 1, #colNames do
        local name = colNames[i]
        if name == identifier then
            index = i
            break
        end
    end

    if index <= 0 then
        XLog.Warning(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", self.FilePath))
    end

    local checkIndex = false
    local trunkPos = 0
    if self.cachesCount > 0 and isPair then--满足这两条件才可以(这里判断是for循环即可)
        checkIndex = true
        trunkPos = self:GetContentTrunkPosition()
    end

    local tab = {}
    for i = 1, row do
        if not checkIndex or not self.cachesRow[i] then
            local temp = {}
            local keyValue = nil

            for j = 1, col do
                reader:SetReadColumn(j)
                local type = colType[j]
                local value = reader:Read(type)
                temp[j] = value
                if index > 0 and j == index then
                    keyValue = value or 0
                end
            end

            if index == 0 then
                keyValue = i
            end

            setmetatable(temp, self.MetaTable)
            tab[keyValue] = temp

            if not self.m_skipCache then
                self.caches[keyValue] = temp
                XTableManager.UpdateBinaryFields(self.FilePath, temp)
            end
        else
            local tail = self.m_rowIndexArray[i]
            tail = tail + trunkPos
            reader:SetIndex(tail)
        end
    end

    if not self.m_skipCache then
        self.cachesCount = self.row
        XTableManager.UpdateVolatileStructuralSize(self.FilePath, "m_xTableDic", self.caches, true)
    end
    self:__CloseReader(reader)
    return tab
end

-- 获取Key字段
function PtrBinaryTable:Get(key)
    self:InitBinary()
    if not self.caches then return end

    local v = self.caches[key]
    if v then
        return v
    end

    if self.cachesCount == self.row then --遍历完了还没找到的
        return nil
    end

    local t, index = self:ReadElement(key)
    if t ~= nil then
        self.caches[key] = t
        self.cachesCount = self.cachesCount + 1
        self.cachesRow[index] = true
        XTableManager.UpdateVolatileStructuralSize(self.FilePath, "m_xTableDic", self.caches, true)
        XTableManager.UpdateVolatileStructuralSize(self.FilePath, "m_cachesRow", self.cachesRow, true)
    end

    return t
end

--读取索引块
function PtrBinaryTable:ReadIndexTrunk()
    local len = self.primarykeyLen
    local position = self:GetIndexTrunkPosition()

    if len <= 0 or position < 0 then
        XLog.Error(string.format("%s,读取索引块失败!! primarykey = %s", self.FilePath, self.primarykey))
        return
    end

    self.primaryKeyList = {}
    local reader = self:__GetReader(len, position)
    local colCnt = #self.colNames
    local colNum = 0
    for col = 1, colCnt do
        if self.colNames[col] == self.primarykey then
            colNum = col
            break
        end
    end
    reader:SetReadColumn(colNum)
    for i = 1, self.row do
        local temp = reader:Read(self.primarykeyType) or 0
        self.primaryKeyList[temp] = i
    end
    XTableManager.RegisterFixedStructuralSize(self.FilePath, "m_primarykeyDic", self.primaryKeyList, false)
    self:__CloseReader(reader)
    return true
end

-- 读取每行的位置和长度
function PtrBinaryTable:ReadRowIndexTrunk()
    local len = self.rowTrunkLen
    local position = self:GetAfterPrimaryKeyTrunkPosition()
    if len <= 0 or position < 0 then
        XLog.Error(string.format("%s,PtrBinaryTable:ReadRowIndexTrunk 读取行位置块失败！", self.FilePath))
        return
    end

    self.cachesRow = {} --缓存读取过的行
    self.m_rowIndexArray = {}
    local reader = self:__GetReader(len, position)
    for _ = 1, self.row do
        table.insert(self.m_rowIndexArray, reader:ReadInt() or 0)
    end

    XTableManager.RegisterFixedStructuralSize(self.FilePath, "m_rowIndexArray", self.m_rowIndexArray, true)
    self:__CloseReader(reader)
end

-- 读取条目
function PtrBinaryTable:ReadElement(key)
    if not self.primarykey then
        XLog.Error(string.format("%s,主键未初始化 ", self.FilePath))
        return nil
    end

    if not self.primaryKeyList then
        self:ReadIndexTrunk()
    end

    local element = nil
    local index = self.primaryKeyList[key]
    if index then
        element = self:ReadElementInner(index, key)
    end

    if not element then
        --  XLog.Warning(string.format("%s,PtrBinaryTable:ReadElement,查询失败，未找到条目 %s = %s", self.filePath, self.primarykey, value))
        return
    end
    XTableManager.UpdateBinaryFields(self.FilePath, element)
    return element, index
end

-- 读取行条目
function PtrBinaryTable:_ReadRow(index)
    if not self.m_rowIndexArray then
        self:ReadRowIndexTrunk()
    end

    local rowIndexCnt = #self.m_rowIndexArray
    if rowIndexCnt <= 0 then
        XLog.Error(string.format("%s,PtrBinaryTable:ReadRow,读取行位置数据失败", self.FilePath))
        return
    end

    if index > rowIndexCnt then
        XLog.Error(string.format("%s,PtrBinaryTable:ReadRow,%s超出总行数%s长度", self.FilePath, index, rowIndexCnt))
        return
    end

    local position = self:GetContentTrunkPosition()
    local start = index - 1
    local startIndex = start <= 0 and 0 or self.m_rowIndexArray[start]
    local endIndex = self.m_rowIndexArray[index]
    local len = endIndex - startIndex
    local reader = self:__GetReader(len, position + startIndex)
    return reader
end

-- 读取行内部数据
function PtrBinaryTable:ReadElementInner(index, keyName)
    local reader = self:_ReadRow(index)
    if not reader then
        XLog.Warning(string.format("%s,PtrBinaryTable:ReadElementInner,查询数据失败 %s = %s", self.FilePath, self.primarykey, keyName))
        return
    end

    local colType = self.colTypes
    local temp = {}
    for j = 1, self.col do
        reader:SetReadColumn(j)
        local type = colType[j]
        local value = reader:Read(type)
        temp[j] = value
    end

    setmetatable(temp, self.MetaTable)

    self:__CloseReader(reader)
    return temp
end

-- 初始化字符串池数据
function PtrBinaryTable:ReadPoolInfoTrunk()
    local position = self:GetPoolOffsetTrunkStartPosition()
    if position <= 0 then
        XLog.Error(string.format("%s,PtrBinaryTable:ReadPoolInfoTrunk position 读取字符串池失败！", self.FilePath))
        return
    end

    local reader = self:__GetReader(HEAD_LEN, position)
    local poolHeadLength = reader:ReadIntFix() or 0
    if poolHeadLength <= 0 then
        self.m_poolColumnSize = 0
        self:__CloseReader(reader)
        return
    end

    self:__ResetReader(reader, poolHeadLength, position + HEAD_LEN)
    self.m_poolColumnSize = reader:ReadInt() or 0
    if self.m_poolColumnSize <= 0 then
        self:__CloseReader(reader)
        return
    end

    local m_stringPoolSize = reader:ReadInt() or 0  -- 用于初始化字符串池大小保留
    local m_poolColumnLen = reader:ReadInt() or 0
    local m_poolOffsetTrunkLen = reader:ReadInt() or 0
    local m_poolInfoOffsetLen = poolHeadLength + HEAD_LEN
    self.m_poolContentStartPos = m_poolInfoOffsetLen + m_poolColumnLen + m_poolOffsetTrunkLen

    if m_poolColumnLen <= 0 then
        XLog.Error(string.format("%s,PtrBinaryTable:ReadPoolInfoTrunk m_poolColumnLen 读取字符串池失败！", self.FilePath))
        self:__CloseReader(reader)
        return
    end

    self.m_columnMap = {}
    self:__ResetReader(reader, m_poolColumnLen, m_poolInfoOffsetLen + position)
    for _ = 1, self.m_poolColumnSize do
        local columnIndex = reader:ReadInt() or 0
        self.m_columnMap[columnIndex + 1] = true
    end

    if m_poolOffsetTrunkLen <= 0 then
        XLog.Error(string.format("%s,PtrBinaryTable:ReadPoolInfoTrunk m_poolOffsetTrunkLen 读取字符串池失败！", self.FilePath))
        self:__CloseReader(reader)
        return
    end
    self.m_poolColumnSizeStartPos = m_poolColumnLen + m_poolInfoOffsetLen + position

    -- 偏移数组某些配置表比较大所以去掉了缓存，直接偏移读取
    -- self.m_poolOffsetInfoArray = {}
    -- self:__ResetReader(reader, m_poolOffsetTrunkLen, m_poolColumnLen + m_poolInfoOffsetLen + position)
    -- for _ = 1, m_stringPoolSize do
    --     table.insert(self.m_poolOffsetInfoArray, reader:ReadInt() or 0)
    -- end
    self:__CloseReader(reader)
end

-- 判断是否是字符串池列
function PtrBinaryTable:IsStringPoolColumn(columnIndex)
    if columnIndex < 0 then
        return false
    end
    if self.m_poolColumnSize == -1 then
        self:ReadPoolInfoTrunk()
    end
    if self.m_poolColumnSize <= 0 then
        return false
    end
    return self.m_columnMap[columnIndex]
end

-- 通过字符串池获取字符串
function PtrBinaryTable:ReadPoolStringByIndex(index)
    -- if not self.m_poolOffsetInfoArray or #self.m_poolOffsetInfoArray <= 0 then
    --     XLog.Error(string.format("%s,PtrBinaryTable:ReadPoolStringByIndex 读取行位置数据失败", self.FilePath))
    --     return
    -- end

    -- local luaIndex = index + 1
    -- if luaIndex > #self.m_poolOffsetInfoArray then
    --     XLog.Error(string.format("%s,PtrBinaryTable:ReadPoolStringByIndex 超出总行数长度 : %s 查询长度 : %s", self.FilePath, #self.m_poolOffsetInfoArray, index))
    --     return
    -- end

    -- 主线比较多配置表没清除，先不cache
    -- if not self.stringCaches then
    --     self.stringCaches = {}
    -- end
    local str-- = self.stringCaches[luaIndex]
    -- if not str then
    local realIndex = index - 1
    local firstPos = self.m_poolColumnSizeStartPos + realIndex * HEAD_LEN
    local reader = self:__GetReader(HEAD_LEN, firstPos)
    local startPos = realIndex < 0 and 0 or reader:ReadIntFix()

    self:__ResetReader(reader, HEAD_LEN, firstPos + HEAD_LEN)
    local endPos = reader:ReadIntFix()

    -- local startPos = index <= 0 and 0 or self.m_poolOffsetInfoArray[index]
    -- local endPos = self.m_poolOffsetInfoArray[luaIndex]

    local poolContentStartPos = self:GetPoolContentTrunkStartPosition()
    self:__ResetReader(reader, endPos - startPos, poolContentStartPos + startPos)
    -- local reader = self:__GetReader(endPos - startPos, poolContentStartPos + startPos)
    str = reader:ReadString()
    self:__CloseReader(reader)
    --     self.stringCaches[luaIndex] = str
    -- end
    return str
end

-- 释放缓存
function PtrBinaryTable:ReleaseCache()
    self.caches = {}
    self.cachesCount = 0
    if self.cachesRow then
        self.cachesRow = {}
    end

    if self.m_initialized then
        XTableManager.ReleaseBinaryFields(self.FilePath)
        XTableManager.UpdateVolatileStructuralSize(self.FilePath, "m_xTableDic", self.caches, true)
    end
end

-- 释放所有
function PtrBinaryTable:ReleaseFull()
    -- self.stringCaches = nil
    self.m_columnMap = nil
    self:ReleaseCache()
    self.BytesPtr = nil
    if self.Bytes then
        self.Bytes:Release()
    end
    self.Bytes = nil

    XTableManager.OnUnloadBinaryBytes(self.FilePath)
end

-- 关闭，好像没调用
function PtrBinaryTable:Close()
    XLog.Error("PtrBinaryTable:Close", self.FilePath)
    self:ReleaseFull()
end

return PtrBinaryTable
