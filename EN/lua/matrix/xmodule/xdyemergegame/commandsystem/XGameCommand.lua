--- 命令参数: 传递给对应执行者的对象
---@class XGameCommandParams
---@field Uid number
---@field FinishHandle function @ 执行者完成指令后必须调用，通知控制器推进下一条指令

--- 命令（纯数据容器，不派生，具体逻辑由对应的 Executor 实现）
---@class XGameCommand
local XGameCommand = XClass(nil, 'XGameCommand')

local LockMeta = {
    __newindex = function()
        XLog.Error('数据锁定中，禁止修改')
    end
}

--- 递归冻结 table 及其所有嵌套 table，防止通过嵌套字段绕过顶层锁定
--- visited 用于防止循环引用导致死循环
local function DeepFreeze(t, visited)
    visited = visited or {}
    if visited[t] then
        return
    end
    visited[t] = true
    setmetatable(t, LockMeta)
    for _, v in pairs(t) do
        if type(v) == "table" then
            DeepFreeze(v, visited)
        end
    end
end

--- 递归解冻 table 及其所有嵌套 table
local function DeepUnfreeze(t, visited)
    visited = visited or {}
    if visited[t] then
        return
    end
    visited[t] = true
    setmetatable(t, nil)
    for _, v in pairs(t) do
        if type(v) == "table" then
            DeepUnfreeze(v, visited)
        end
    end
end

function XGameCommand:Ctor()
    self._Params = {}
    self._IsLockParams = false
    self._CommandType = nil

    self:ResetState()
end

function XGameCommand:SetUid(uid)
    self:SetParam('Uid', uid)
end

--region CommandType

function XGameCommand:SetCommandType(commandType)
    self._CommandType = commandType
end

function XGameCommand:GetCommandType()
    return self._CommandType
end

--endregion

--region State

function XGameCommand:ResetState()
    self._IsFinish = false
    self._IsStart = false
end

function XGameCommand:GetIsStart()
    return self._IsStart
end

function XGameCommand:GetIsFinish()
    return self._IsFinish
end

function XGameCommand:MarkStart()
    self._IsStart = true
end

function XGameCommand:MarkFinish()
    if self._IsStart then
        self._IsFinish = true
    else
        XLog.Error("命令尚未开始就标记结束")
    end
end

--endregion

--region Params

--- 开放外部的唯一修改接口
--- 注意：若 value 为 table，GetParams() 后该 table 会被深度冻结，不应传入外部共享的可变 table
function XGameCommand:SetParam(key, value)
    if self._IsLockParams then
        DeepUnfreeze(self._Params)
    end

    self._Params[key] = value

    if self._IsLockParams then
        DeepFreeze(self._Params)
    end
end

--- 获取参数，用于外部访问
--- 调用后对 _Params 及其所有嵌套 table 深度加锁，直到该 command 生命周期结束重置
function XGameCommand:GetParams()
    DeepFreeze(self._Params)
    self._IsLockParams = true
    return self._Params
end

--- 批量设置参数的内部专用接口，用于在锁定期间临时解锁以便批量赋值
--- Begin 和 End 必须成对调用，嵌套调用会导致提前解锁，不支持嵌套
function XGameCommand:_BeginBatchParamSet()
    if self._IsLockParams then
        DeepUnfreeze(self._Params)
    end
end

function XGameCommand:_EndBatchParamSet()
    if self._IsLockParams then
        DeepFreeze(self._Params)
    end
end

--endregion

--- 重置数据，用于回收
function XGameCommand:ResetData()
    DeepUnfreeze(self._Params)
    self._IsLockParams = false

    self._Params.Uid = nil
    self._Params.FinishHandle = nil
    self._CommandType = nil

    self:OnResetData()
    self:ResetState()

    -- 建议子类手动清空参数表，如果没有清空，则直接创建新的空表
    if not XTool.IsTableEmpty(self._Params) then
        self._Params = {}
    end
end

--- 重置数据响应方法，用于子类重写
function XGameCommand:OnResetData()
end

return XGameCommand
