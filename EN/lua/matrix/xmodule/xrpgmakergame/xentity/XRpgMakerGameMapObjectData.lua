-- 推箱子地图对象数据类
---@class XMapObjectData
---@field private _Row number X坐标
---@field private _Col number Y坐标
---@field private _Type number 对象类型
---@field private _Params number[] 参数
local XMapObjectData = XClass(nil, "XMapObjectData")

function XMapObjectData:Ctor(row, col, params)
    self._Row = row
    self._Col = col

    local values = string.Split(params, "&")
    if #values >= 1 then
        self._Type = tonumber(values[1]) or 0
    end
    self._Params = {}
    for i = 2, #values, 1 do
        self._Params[i - 1] = tonumber(values[i]) or 0
    end
end

function XMapObjectData:GetX()
    return self._Col
end

function XMapObjectData:GetY()
    return self._Row
end

function XMapObjectData:GetRow()
    return self._Row
end

function XMapObjectData:GetCol()
    return self._Col
end

function XMapObjectData:GetType()
    return self._Type
end

function XMapObjectData:GetParams()
    return self._Params
end

return XMapObjectData