--- 命令组（串行队列 + 历史记录）
---@class XGameCommandGroup
local XGameCommandGroup = XClass(nil, 'XGameCommandGroup')

local XDeque = require("XCommon/XDeque")

function XGameCommandGroup:Ctor(maxHistoryCount)
    self._MaxHistoryCount = maxHistoryCount or -1 -- 最多保存多少个历史命令，-1 表示不限制

    ---@type XDeque
    self._HistoryCommandList = XDeque.New()    -- 已完成的命令，按入列顺序存储；Undo 时从列尾依次取出

    ---@type XQueue
    self._WaitingCommandQueue = XQueue.New()   -- 待执行命令队列

    ---@type XGameCommand
    self._RunningCommand = nil -- 当前正在执行的命令
end

--region State

--- GetIsAllFinish 只做查询，不修改任何状态
--- 历史命令的移入由 MarkRunningCommandDone 负责，此处不能绕过
function XGameCommandGroup:GetIsAllFinish()
    if not self._WaitingCommandQueue:IsEmpty() then
        return false
    end

    if self._RunningCommand == nil then
        return true
    end

    return self._RunningCommand:GetIsFinish()
end

function XGameCommandGroup:GetIsAnyCommandRunning()
    return self._RunningCommand ~= nil
end

--- 获取当前正在执行的命令类型，无命令时返回 nil
function XGameCommandGroup:GetRunningCommandType()
    return self._RunningCommand and self._RunningCommand:GetCommandType() or nil
end

--- 待执行队列是否为空
function XGameCommandGroup:IsWaitingQueueEmpty()
    return self._WaitingCommandQueue:IsEmpty()
end

--endregion

--region Command Flow

function XGameCommandGroup:AddCommand(command)
    self._WaitingCommandQueue:Enqueue(command)
end

--- 尝试取出下一条待执行命令并设为 Running 状态，不调用 MarkStart（由 Control 在实际执行前调用）
--- 当前有命令正在执行、或待执行队列为空时返回 false
---@return boolean, XGameCommand
function XGameCommandGroup:TryGetNextCommand()
    if self:GetIsAnyCommandRunning() then
        XLog.Error("有指令正在执行，无法获取下一个指令")
        return false, nil
    end

    if self._WaitingCommandQueue:IsEmpty() then
        return false, nil
    end

    local command = self._WaitingCommandQueue:Dequeue()
    self._RunningCommand = command

    return true, command
end

--- 将当前正在执行的命令标记为完成并移入历史列表
--- 若历史列表超出上限，将最早的命令从列表头部弹出并返回（由 Control 负责回收入池）
---@return XGameCommand @ 因历史溢出而被淘汰的命令，不存在时返回 nil
function XGameCommandGroup:MarkRunningCommandDone()
    if not self:GetIsAnyCommandRunning() then
        XLog.Error("当前没有正在执行的指令，无法标记完成")
        return nil
    end

    self._RunningCommand:MarkFinish()
    self._HistoryCommandList:Enqueue(self._RunningCommand)
    self._RunningCommand = nil

    -- 历史超出上限，弹出最早的命令交给 Control 回收
    if self._MaxHistoryCount ~= -1 and self._HistoryCommandList:Count() > self._MaxHistoryCount then
        return self._HistoryCommandList:Dequeue()
    end

    return nil
end

--endregion

--region Recycle Helper（供 Control 在 Reset 时批量回收）

--- 取出所有待执行命令（清空待执行队列）
---@return XGameCommand[]
function XGameCommandGroup:TakeAllWaitingCommands(in_result)
    local result = in_result or {}

    while not self._WaitingCommandQueue:IsEmpty() do
        result[#result + 1] = self._WaitingCommandQueue:Dequeue()
    end

    return result
end

--- 取出当前正在执行的命令（清空 Running 槽位）
---@return XGameCommand
function XGameCommandGroup:TakeRunningCommand()
    local command = self._RunningCommand
    self._RunningCommand = nil
    return command
end

--- 取出所有历史命令（清空历史队列）
---@return XGameCommand[]
function XGameCommandGroup:TakeAllHistoryCommands(in_result)
    local result = in_result or {}

    while not self._HistoryCommandList:IsEmpty() do
        result[#result + 1] = self._HistoryCommandList:Dequeue()
    end

    return result
end

--endregion

return XGameCommandGroup
