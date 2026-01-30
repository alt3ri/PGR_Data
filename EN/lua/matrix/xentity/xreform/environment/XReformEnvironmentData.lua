---@class XReformEnvironmentData
local XReformEnvironmentData = XClass(nil, "XReformEnvironmentData")

function XReformEnvironmentData:Ctor(environments)
    self._Data = environments
end

function XReformEnvironmentData:GetData()
    return self._Data
end

return XReformEnvironmentData