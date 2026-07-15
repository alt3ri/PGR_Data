--- 命令控制器
---@class XGameCommandControl
local XGameCommandControl = XClass(nil, 'XGameCommandControl')

function XGameCommandControl:Init(commandCls, groupCls, maxHistoryCount)
    self._CommandCls = commandCls or require('XModule/XDyeMergeGame/CommandSystem/XGameCommand')
    self._CommandGroupCls = groupCls or require('XModule/XDyeMergeGame/CommandSystem/XGameCommandGroup')

    ---@type XGameCommandGroup
    self._CommandGroup = self._CommandGroupCls.New(maxHistoryCount)

    -- 命令对象池
    ---@type XPool
    self._CommandPool = XPool.New(function()
        return self._CommandCls.New()
    end, function(command)
        command:ResetData()
    end, false)

    self._CommandUidCounter = 1

    -- Reset 时自增，用于使旧 FinishHandle 闭包失效（见 GetCommandFromPool）
    self._Generation = 0

    -- 分发主循环运行标志：TryDoNextCommand 的 while 循环执行期间为 true
    -- _OnCommandFinish 读取此标志，同步场景下不重复驱动队列（见 _OnCommandFinish）
    self._IsDispatchingCommands = false

    -- 执行者注册表：commandType -> executor
    -- executor 需实现 OnExecuteCommand(params, finishHandle)
    self._Executors = {}
end

--- 注册命令执行者
--- 一种 commandType 对应一个 executor，重复注册会覆盖
--- 若该类型的命令当前正在执行，拒绝注册以防止同批次命令行为不一致
function XGameCommandControl:RegisterExecutor(commandType, executor)
    if not commandType then
        XLog.Error("XGameCommandControl:RegisterExecutor 命令类型不能为空")
        return
    end
    if self._CommandGroup:GetRunningCommandType() == commandType then
        XLog.Error("XGameCommandControl:RegisterExecutor 命令类型 " .. tostring(commandType) .. " 正在执行，拒绝覆盖")
        return
    end
    self._Executors[commandType] = executor
end

--- 数据重置，回收所有命令对象
function XGameCommandControl:Reset()
    self._CommandCallBack = nil

    -- 注意：不在此处修改 _IsDispatchingCommands
    -- 若 Reset 在主循环执行期间被调用，强制置 false 会导致后续 _OnCommandFinish 误判为"主循环已退出"而触发重入
    -- _IsDispatchingCommands 由 TryDoNextCommand 自行管理，Reset 不干预

    -- generation 自增，使所有旧 FinishHandle 闭包失效
    -- 此后任何异步 Executor 持有的旧闭包调用时会因 generation 不匹配而直接返回
    self._Generation = self._Generation + 1

    -- 回收待执行队列
    local waiting = self._CommandGroup:TakeAllWaitingCommands()
    for _, command in ipairs(waiting) do
        self._CommandPool:ReturnItemToPool(command)
    end

    -- 回收正在执行的命令
    local running = self._CommandGroup:TakeRunningCommand()
    if running then
        self._CommandPool:ReturnItemToPool(running)
    end

    -- 回收历史命令（历史列表是命令的唯一归宿，此处是合法的回收路径）
    local history = self._CommandGroup:TakeAllHistoryCommands()
    for _, command in ipairs(history) do
        self._CommandPool:ReturnItemToPool(command)
    end

    -- 重置 Uid 计数器
    self._CommandUidCounter = 1
end

--region CommandPool

--- 从对象池取出一个命令对象并完成初始化
--- 调用方拿到对象后只应使用 SetParam 配置参数，最终调用 AddCommand 提交
--- 提交后不应再持有或操作此对象，所有权归 Control
---@param commandType @ 命令类型，用于分发给对应的 Executor
---@return XGameCommand
function XGameCommandControl:GetCommandFromPool(commandType)
    if not commandType then
        XLog.Error("XGameCommandControl:GetCommandFromPool 命令类型不能为空")
        return nil
    end

    local command = self._CommandPool:GetItemFromPool()

    command:SetUid(self._CommandUidCounter)
    self._CommandUidCounter = self._CommandUidCounter + 1

    command:SetCommandType(commandType)

    -- FinishHandle 在此处构造，提前捕获 uid 和 generation 为 upvalue：
    --   uid：避免异步场景下 command 已被回收/重用，延迟访问 GetParams().Uid 会读到脏数据
    --   generation：Reset() 后异步 Executor 仍回调时，generation 不匹配则静默返回
    local uid = self._CommandUidCounter - 1  -- SetUid 已自增，回退取当前值
    local capturedGeneration = self._Generation
    local alreadyCalled = false
    command:SetParam('FinishHandle', function()
        if capturedGeneration ~= self._Generation then
            -- Control 已被 Reset，此次回调作废
            return
        end
        if alreadyCalled then
            XLog.Error("FinishHandle 被重复调用，uid=" .. tostring(uid))
            return
        end
        alreadyCalled = true
        self:_OnCommandFinish(command)
    end)

    return command
end

--endregion

--region Running

function XGameCommandControl:GetIsRunning()
    return self._CommandGroup:GetIsAnyCommandRunning()
end

--- 添加指令到指令组中
--- 添加后调用方不应再操作此 command 对象，所有权转交 Control
function XGameCommandControl:AddCommand(command)
    if not command then
        XLog.Error("XGameCommandControl:AddCommand 命令对象不能为空")
        return
    end
    self._CommandGroup:AddCommand(command)
end

--- 尝试执行下一条命令
--- 若队列已空，则触发全部完成回调（若有）
--- 注意：cb 是覆盖语义，多次传入不同 cb 时只保留最后一次；若不需要覆盖请勿在队列执行中途传入新 cb
---@param cb function @ 可选，队列执行完毕后的回调，仅在队列空时立即触发
function XGameCommandControl:TryDoNextCommand(cb)
    if cb then
        self._CommandCallBack = cb
    end

    self._IsDispatchingCommands = true

    while not self._CommandGroup:IsWaitingQueueEmpty() do
        local isSuccess, command = self._CommandGroup:TryGetNextCommand()
        if not isSuccess then
            -- 理论上不应到达此处（循环条件保证队列非空且无命令在执行）
            -- 若发生则说明 Group 内部状态不一致，终止本轮驱动
            XLog.Error("XGameCommandControl: TryGetNextCommand 意外失败，Group 状态不一致")
            break
        end

        local executor = self._Executors[command:GetCommandType()]

        if not executor then
            XLog.Error("XGameCommandControl: 未注册的命令类型 " .. tostring(command:GetCommandType()) .. "，将自动跳过")
            -- 补 MarkStart 保证状态完整，直接 MarkDone，循环继续取下一条
            command:MarkStart()
            local evicted = self._CommandGroup:MarkRunningCommandDone()
            if evicted then
                self._CommandPool:ReturnItemToPool(evicted)
            end

        else
            -- MarkStart 紧靠实际执行前，确保 GetIsStart() 与 Executor 真正开始时序一致
            command:MarkStart()
            -- GetParams() 会触发深度参数锁定，之后执行者只能读取
            local params = command:GetParams()
            executor:OnExecuteCommand(params, params.FinishHandle)

            -- 同步 Executor：FinishHandle 已在 OnExecuteCommand 内调用完毕
            --   → _RunningCommand 已被清空，GetIsAnyCommandRunning() 为 false，循环继续
            -- 异步 Executor：FinishHandle 尚未调用
            --   → _RunningCommand 仍有值，GetIsAnyCommandRunning() 为 true，退出循环等回调
            if self._CommandGroup:GetIsAnyCommandRunning() then
                self._IsDispatchingCommands = false
                return
            end
        end
    end

    self._IsDispatchingCommands = false

    if self._CommandCallBack then
        local callback = self._CommandCallBack
        self._CommandCallBack = nil
        callback()
    end
end

--- 命令执行完成时由 FinishHandle 回调触发（Control 内部使用）
function XGameCommandControl:_OnCommandFinish(command)
    -- 标记完成并移入历史；若历史溢出，返回被淘汰的最旧命令，由此处负责回收
    -- 注意：command 本身已进入历史列表，不在此处回收；只有被淘汰的才回收
    local evicted = self._CommandGroup:MarkRunningCommandDone()
    if evicted then
        self._CommandPool:ReturnItemToPool(evicted)
    end

    -- 同步场景：_IsDispatchingCommands 为 true，主循环仍在栈上，检测到 GetIsAnyCommandRunning() 为 false 后会自然继续，此处不重入
    -- 异步场景：_IsDispatchingCommands 为 false，主循环已退出，需要重新驱动队列
    if not self._IsDispatchingCommands then
        self:TryDoNextCommand()
    end
end

--endregion

return XGameCommandControl
