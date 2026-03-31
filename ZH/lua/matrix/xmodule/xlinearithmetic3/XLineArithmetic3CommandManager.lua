--- 命令管理器：管理命令的执行和撤销
---@class XLineArithmetic3CommandManager
local XLineArithmetic3CommandManager = XClass(nil, "XLineArithmetic3CommandManager")

function XLineArithmetic3CommandManager:Ctor(uiGame, game)
    self._UiGame = uiGame
    self._Game = game
    -- 已执行的命令栈
    self._CommandHistory = {}
    -- 当前执行索引
    self._CurrentIndex = 0
    -- 每组操作包含的命令数量（用于按组撤销）
    self._GroupSizes = {}
    -- 是否正在播放
    self._IsPlaying = false
    -- 是否正在倒放
    self._IsRewinding = false
end

--- 记录一组操作的起始索引（在播放一组指令前调用）
function XLineArithmetic3CommandManager:BeginGroup()
    self._GroupStartIndex = self._CurrentIndex
end

--- 结束一组操作，将该组命令数量压入分组栈
function XLineArithmetic3CommandManager:EndGroup()
    local count = self._CurrentIndex - (self._GroupStartIndex or self._CurrentIndex)
    if count > 0 then
        self._GroupSizes[#self._GroupSizes + 1] = count
    end
    self._GroupStartIndex = nil
end

--- 撤销最近一组操作（回退一步）
---@param onComplete function
function XLineArithmetic3CommandManager:UndoGroup(onComplete)
    if #self._GroupSizes <= 0 or self._CurrentIndex <= 0 then
        if onComplete then onComplete() end
        return
    end

    local groupSize = table.remove(self._GroupSizes)
    self:UndoSteps(groupSize, onComplete)
end

--- 连续撤销多组操作
---@param groupCount number 要撤销的组数
---@param onComplete function
function XLineArithmetic3CommandManager:UndoGroups(groupCount, onComplete)
    if groupCount <= 0 or #self._GroupSizes <= 0 or self._CurrentIndex <= 0 then
        if onComplete then onComplete() end
        return
    end

    -- 合并多组的命令总数
    local totalSteps = 0
    local actualGroups = math.min(groupCount, #self._GroupSizes)
    for _ = 1, actualGroups do
        totalSteps = totalSteps + table.remove(self._GroupSizes)
    end

    self:UndoSteps(totalSteps, onComplete)
end

--- 添加并执行命令
---@param command XLineArithmetic3Command
---@param onComplete function
function XLineArithmetic3CommandManager:ExecuteCommand(command, onComplete)
    -- 清除当前索引之后的命令
    while #self._CommandHistory > self._CurrentIndex do
        table.remove(self._CommandHistory)
    end

    -- 添加命令到历史
    self._CommandHistory[#self._CommandHistory + 1] = command
    self._CurrentIndex = #self._CommandHistory

    -- 执行命令，传入 game
    command:Execute(self._Game, onComplete)
end

--- 批量执行命令队列
---@param commands XLineArithmetic3Command[]
---@param onAllComplete function
function XLineArithmetic3CommandManager:ExecuteCommands(commands, onAllComplete)
    if not commands or #commands == 0 then
        if onAllComplete then onAllComplete() end
        return
    end

    self._IsPlaying = true
    self._PendingCommands = commands
    self._PendingIndex = 0
    self._OnAllComplete = onAllComplete

    self:_ExecuteNextCommand()
end

function XLineArithmetic3CommandManager:_ExecuteNextCommand()
    self._PendingIndex = self._PendingIndex + 1

    if self._PendingIndex > #self._PendingCommands then
        self._IsPlaying = false
        if self._OnAllComplete then self._OnAllComplete() end
        return
    end

    local command = self._PendingCommands[self._PendingIndex]
    self:ExecuteCommand(command, function()
        self:_ExecuteNextCommand()
    end)
end

--- 撤销一个命令
---@param onComplete function
function XLineArithmetic3CommandManager:UndoOne(onComplete)
    if self._CurrentIndex <= 0 then
        if onComplete then onComplete() end
        return
    end

    -- 获取命令并执行 Undo（Command 自己负责恢复 Game 层状态）
    local command = self._CommandHistory[self._CurrentIndex]
    self._CurrentIndex = self._CurrentIndex - 1

    command:Undo(self._Game, function()
        -- Undo 完成后刷新路径显示
        self._UiGame:RefreshTraveledPathDisplay()
        if onComplete then onComplete() end
    end)
end

--- 批量撤销到指定步数
---@param steps number 撤销步数
---@param onAllComplete function
function XLineArithmetic3CommandManager:UndoSteps(steps, onAllComplete)
    if steps <= 0 or self._CurrentIndex <= 0 then
        if onAllComplete then onAllComplete() end
        return
    end

    self._IsRewinding = true
    self._UndoRemaining = math.min(steps, self._CurrentIndex)

    self:_UndoNextCommand(onAllComplete)
end

function XLineArithmetic3CommandManager:_UndoNextCommand(onAllComplete)
    if self._UndoRemaining <= 0 then
        self._IsRewinding = false
        if onAllComplete then onAllComplete() end
        return
    end

    self._UndoRemaining = self._UndoRemaining - 1
    self:UndoOne(function()
        self:_UndoNextCommand(onAllComplete)
    end)
end

--- 停止当前播放/倒放
function XLineArithmetic3CommandManager:Stop()
    self._IsPlaying = false
    self._IsRewinding = false
    self._UiGame:StopAllTweens()
end

--- 是否正在播放
function XLineArithmetic3CommandManager:IsPlaying()
    return self._IsPlaying
end

--- 设置播放状态
function XLineArithmetic3CommandManager:SetPlaying(isPlaying)
    self._IsPlaying = isPlaying
end

--- 是否正在倒放
function XLineArithmetic3CommandManager:IsRewinding()
    return self._IsRewinding
end

--- 是否可以撤销
function XLineArithmetic3CommandManager:CanUndo()
    return self._CurrentIndex > 0
end

--- 获取当前命令索引
function XLineArithmetic3CommandManager:GetCurrentIndex()
    return self._CurrentIndex
end

--- 清空历史
function XLineArithmetic3CommandManager:Clear()
    self._CommandHistory = {}
    self._CurrentIndex = 0
    self._GroupSizes = {}
end

--- 销毁，清理所有引用
function XLineArithmetic3CommandManager:Destroy()
    -- 销毁所有 Command
    for _, command in ipairs(self._CommandHistory) do
        if command and command.Destroy then
            command:Destroy()
        end
    end
    self._CommandHistory = {}
    self._PendingCommands = nil
    self._OnAllComplete = nil
    self._UiGame = nil
    self._Game = nil
end

return XLineArithmetic3CommandManager
