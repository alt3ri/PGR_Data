---@class XGameAnimationParams
---@field Uid
---@field FinishHandle function

--- 行为表现最小单位
---@class XGameAnimation
local XGameAnimation = XClass(nil, 'XGameAnimation')

local LockMeta = {
    __newindex = function()
        XLog.Error('数据锁定中，禁止修改')
    end
}

function XGameAnimation:Ctor()
    self._Params = {}
    self._IsLockParams = false
    
    self:ResetState()
    
    self._MaxRunTime = 5 -- 最长的执行时间，实际时间超过时将强制停止
    
    self._MarkFinishHandle = handler(self, self.MarkFinish)
end

function XGameAnimation:SetUid(uid)
    self:SetParam('Uid', uid)
    self:SetParam('FinishHandle', self._MarkFinishHandle)
end

function XGameAnimation:GetActionType()
    return self._Params.ActionType
end

--region State

function XGameAnimation:ResetState()
    self._IsFinish = false
    self._IsStart = false
    self._StartTime = 0 -- 开始执行的时间
end

function XGameAnimation:GetIsStart()
    return self._IsStart
end

function XGameAnimation:GetIsFinish()
    return self._IsFinish
end

function XGameAnimation:CheckIsTimeOut(curTime)
    if self._IsFinish or not self._IsStart then
        return false
    end
    
    return curTime > self._StartTime + self._MaxRunTime
end

function XGameAnimation:MarkStart(curTime, uid)
    self._IsStart = true
    self._StartTime = curTime
end

function XGameAnimation:MarkFinish()
    self._IsFinish = true
end

function XGameAnimation:SetMaxRunTime(maxRunTime)
    self._MaxRunTime = maxRunTime
end

--endregion

--region Params

--- 开放外部的唯一修改接口
function XGameAnimation:SetParam(key, value)
    -- 修改前解禁
    if self._IsLockParams then
        setmetatable(self._Params, nil)
    end

    self._Params[key] = value
    
    -- 修改完立刻锁上
    if self._IsLockParams then
        setmetatable(self._Params, LockMeta)
    end
end

--- 获取参数，用于外部访问，一旦存在外部访问，将不再能够轻易修改数据, 直到该animation生命周期结束重置
function XGameAnimation:GetParams()
    setmetatable(self._Params, LockMeta)
    self._IsLockParams = true
    
    return self._Params
end

--- 基于锁定，为了内部的赋值方便提供的特殊接口, begin和end必须成对使用
function XGameAnimation:_OnParamsInnerSetBegin()
    if self._IsLockParams then
        setmetatable(self._Params, nil)
    end
end

function XGameAnimation:_OnParamsInnerSetEnd()
    if self._IsLockParams then
        setmetatable(self._Params, LockMeta)
    end
end

--endregion

--- 重置数据，用于回收
function XGameAnimation:ResetData()
    setmetatable(self._Params, nil)
    self._IsLockParams = false

    self._Params.Uid = nil
    self._Params.FinishHandle = nil

    self:OnResetData()
    self:ResetState()
    
    -- 建议子类手动清空参数表，如果没有清空，则直接创建新的空表
    if not XTool.IsTableEmpty(self._Params) then
        self._Params = {}
    end
end

--- 重置数据响应方法，用于子类重写
function XGameAnimation:OnResetData()
    
end

return XGameAnimation