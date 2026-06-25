---@alias pointer void* --定义指针别名


---@class UnityNativeHelper
---@field read_byte fun(ptr:pointer):number
---@field write_byte fun(ptr: number, val:number):number
---@field read_int32 fun(ptr:pointer):number
---@field write_int32 fun(ptr:pointer,val:number):number
---@field offset fun(ptr:pointer, off:number):pointer
---@field read_bytes fun(ptr:pointer, count:number):number[]
---@field read_string fun(ptr:pointer, count:number):string
local UnityNativeHelper = require("UnityNativeHelper")

---@class PtrReader
---@field bytesPtr pointer
local PtrReader = XClass(nil, "PtrReader")
local ReadByType = {}
local MaxInt32 = 2147483647
-- local FloatToInt = 10000

function PtrReader:Ctor()
end

function PtrReader:Reset(len, index)
    self.len = len
    self.index = index or 0
end

function PtrReader:LoadBytes(bytes, len, index)
    self.bytesPtr = bytes
    self:Reset(len, index)
end

function PtrReader:SetReadColumn(column)
    self.m_isUsingStringPool = self.m_binaryFileFolder:IsStringPoolColumn(column)
end

function PtrReader:SetBinaryFileFolder(folder)
    self.m_binaryFileFolder = folder
end

function PtrReader:Close()
    self.m_isUsingStringPool = false
    self.m_binaryFileFolder = nil
    self.bytesPtr = nil
end

function PtrReader:Read(type)
    return ReadByType[type](self)
end

--直接设置inde位置, 用来跳过某些字节读取
function PtrReader:SetIndex(value)
    self.index = value
end

function PtrReader:GetIndex()
    return self.index - 1
end

function PtrReader:ReadFloat()
    local num = self:ReadInt()
    if not num then
        return nil
    end

    num = num / 10000

    local a, b = math.modf(num) --拆分整数位和小数位
    if b == 0 then
        num = a
    end

    return num
end


function PtrReader:ReadBool()
    local value = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, self.index))
    self.index = self.index + 1
    return value == 1 and true or nil
end

function PtrReader:ReadByte()
    local value = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, self.index))
    self.index = self.index + 1
    return value
end

--读取string
function PtrReader:ReadString()
    if self.m_isUsingStringPool then
        local index = self:ReadInt() or 0
        return self.m_binaryFileFolder:ReadPoolStringByIndex(index)
    end

    local position = self.index
    local ass = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, position))
    if ass == nil then
        XLog.Error(string.format("读取字符串异常 postion = %s,len = %s index =%s", position, self.len, self.index))
        return
    end

    while ass > 0 do
        position = position + 1
        ass = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, position))
        if ass == nil then
            XLog.Error(string.format("读取字符串异常 postion = %s,len = %s index =%s", position, self.len, self.index))
            break
        end
    end

    if position == self.index then
        self.index = self.index + 1
        return
    end
    local count = position - self.index
    local value = UnityNativeHelper.read_string(UnityNativeHelper.offset(self.bytesPtr, self.index), count)
    self.index = position + 1

    return value
end

function PtrReader:ReadIntFix()
    local b1, b2, b3, b4 = UnityNativeHelper.read_bytes(UnityNativeHelper.offset(self.bytesPtr, self.index), 4)
    self.index = self.index + 4
    return b1 | b2 << 8 | b3 << 16 | b4 << 24
end

function PtrReader:ReadInt()
    return self:ReadInt32Variant()
end

function PtrReader:ReadInt32Variant()
    return self:ReadUInt32Variant()
end

function PtrReader:ReadUInt32Variant()
    local value = 0
    local tempByte
    local index = 0

    while not tempByte or ((tempByte >> 7) > 0) do
        tempByte = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, self.index))
        local temp1 = (tempByte & 0x7F) << index
        value = value | temp1
        index = index + 7
        self.index = self.index + 1
    end

    --负数,MaxInt32 = 2147483647 因为lua number是64bit 所以需要特殊处理负数
    if value > MaxInt32 then
        value = -(((~ value) & MaxInt32) + 1)
    end

    if value == 0 then
        return nil
    end

    return value
end

--lua 的64位int是有符号的, 不能通过long转ulong的方式, 那样会溢出的!! 所以不支持负数
function PtrReader:ReadInt64Variant()
    local value = 0
    local tempByte
    local index = 0

    while not tempByte or ((tempByte >> 7) > 0) do
        tempByte = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, self.index))
        local temp1 = (tempByte & 0x7F) << index
        value = value | temp1
        index = index + 7
        self.index = self.index + 1
    end

    if value == 0 then
        return nil
    end

    return value
end


function PtrReader:ReadListString()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadString())
    end

    return list
end


function PtrReader:ReadListBool()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadBool())
    end

    return list
end

function PtrReader:ReadListByte()
    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end
    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadByte())
    end
    return list
end


function PtrReader:ReadListInt()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadInt() or 0)
    end

    return list
end

function PtrReader:ReadListFloat()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFloat() or 0)
    end

    return list
end

function PtrReader:ReadDicStringString()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadString()
        local value = self:ReadString()
        dic[key] = value
    end

    return dic
end

function PtrReader:ReadDicIntInt()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadInt() or 0
        local value = self:ReadInt() or 0
        dic[key] = value
    end

    return dic
end

function PtrReader:ReadDicIntString()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadInt() or 0
        local value = self:ReadString()
        dic[key] = value
    end

    return dic
end


function PtrReader:ReadDicStringInt()

    local len = self:ReadInt() or 0
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadString()
        local value = self:ReadInt()
        dic[key] = value
    end

    return dic
end

function PtrReader:ReadDicIntFloat()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadInt() or 0
        local value = self:ReadFloat()
        dic[key] = value
    end

    return dic
end

--读取Fix
function PtrReader:ReadFix()
    local value = self:ReadInt64Variant() or 0
    local exp = 0
    if value ~= 0 then
        local combinedByte = UnityNativeHelper.read_byte(UnityNativeHelper.offset(self.bytesPtr, self.index))
        self.index = self.index + 1
        exp = combinedByte & 0x7F
        local negative = combinedByte >> 7
        if negative == 1 then
            value = -value
        end
    else
        return FixExZero
    end
    --local str = self:ReadString()
    --if not str then
    --    return nil
    --end

    return FixParseEx(value, exp)
end

--读取Fix
function PtrReader:ReadListFix()
    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFix())
    end

    return list
end

--读取Fix2
function PtrReader:ReadFix2()
    local fix2 = CS.Mathematics.fix2()
    fix2.x = self:ReadFix()
    fix2.y = self:ReadFix()
    return fix2
end

--读取List Fix2
function PtrReader:ReadListFix2()
    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFix2())
    end

    return list
end

--读取Fix3
function PtrReader:ReadFix3()
    local fix3 = CS.Mathematics.fix3()
    fix3.x = self:ReadFix()
    fix3.y = self:ReadFix()
    fix3.z = self:ReadFix()
    return fix3
end

--读取List Fix3
function PtrReader:ReadListFix3()
    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFix3())
    end

    return list
end

--读取FixQuaternion
function PtrReader:ReadFixQuaternion()
    local fix4 = CS.Mathematics.fixquaternion()
    fix4.value.x = self:ReadFix() or 0
    fix4.value.y = self:ReadFix() or 0
    fix4.value.z = self:ReadFix() or 0
    fix4.value.w = self:ReadFix() or 0
    return fix4
end

--读取List FixQuaternion
function PtrReader:ReadListFixQuaternion()
    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFixQuaternion())
    end

    return list
end





ReadByType = {
    [1] = PtrReader.ReadBool,
    [2] = PtrReader.ReadString,
    [3] = PtrReader.ReadFix,
    [4] = PtrReader.ReadListString,
    [5] = PtrReader.ReadListBool,
    [6] = PtrReader.ReadListInt,
    [7] = PtrReader.ReadListFloat,
    [8] = PtrReader.ReadListFix,
    [9] = PtrReader.ReadDicStringString,
    [10] = PtrReader.ReadDicIntInt,
    [11] = PtrReader.ReadDicIntString,
    [12] = PtrReader.ReadDicStringInt,
    [13] = PtrReader.ReadDicIntFloat,
    [14] = PtrReader.ReadInt,
    [15] = PtrReader.ReadFloat,
    [16] = PtrReader.ReadFix2,
    [17] = PtrReader.ReadFix3,
    [18] = PtrReader.ReadFixQuaternion,
    [19] = PtrReader.ReadListFix2,
    [20] = PtrReader.ReadListFix3,
    [21] = PtrReader.ReadListFixQuaternion,
    --[22] int2 暂时还未支持
    [23] = PtrReader.ReadByte,
    [24] = PtrReader.ReadListByte,
}


return PtrReader