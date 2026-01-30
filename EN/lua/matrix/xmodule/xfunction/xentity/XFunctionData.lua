---@class XFunctionData
---@field FunctionId number 玩法Id(XFunctionManager.FunctionName)
---@field DwellTime number 停留时间
---@field IsRecording boolean 是否在记录中
local XFunctionData = XClass(nil, "XFunctionData")

function XFunctionData:Ctor()
    self:Reset()
end

-- 设置玩法Id
function XFunctionData:SetFunctionId(functionId)
    self:Reset()
    self.FunctionId = functionId
end

-- 进入玩法
function XFunctionData:Enter()
    self.IsRecording = true
    self.EnterTime = XTime.GetServerNowTimestamp()
    self.ExitTime = nil
end

-- 退出玩法
---@return number 停留时间
function XFunctionData:Exit()
    if not self.IsRecording then
        return self.DwellTime
    end

    self.IsRecording = false
    self.ExitTime = XTime.GetServerNowTimestamp()
    self.DwellTime = self.DwellTime + (self.ExitTime - self.EnterTime)
    return self.DwellTime
end

function XFunctionData:Reset()
    self.FunctionId = 0
    self.DwellTime = 0
    self.IsRecording = false
end

function XFunctionData:GetFunctionId()
    return self.FunctionId
end

-- 获取在模块的停留时间
function XFunctionData:GetDwellTime()
    return self.DwellTime
end

-- 是否在记录中
function XFunctionData:GetIsRecording()
    return self.IsRecording
end

return XFunctionData