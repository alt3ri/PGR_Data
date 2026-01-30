---@class XBigWorldViewData
---@field IsRecycle boolean 是否被回收
local XBigWorldViewData = XClass(nil, "XBigWorldViewData")

function XBigWorldViewData:Ctor()
    self.IsRecycle = false
    self.PrimaryKey = 17
    self.SecondaryKey = 34
end

function XBigWorldViewData:Recycle()
    self.IsRecycle = true
    self:OnReset()
end

function XBigWorldViewData:Retain()
    self.IsRecycle = false
end

function XBigWorldViewData:OnReset()
end

function XBigWorldViewData:SetParams(...)
end

function XBigWorldViewData:GetHashCode()
end

function XBigWorldViewData:IsAlive()
    return not self.IsRecycle
end

return XBigWorldViewData