XScheduleManager = XScheduleManager or {}

local CSXScheduleManager = CS.XScheduleManager
XScheduleManager.SECOND = CSXScheduleManager.SECOND

local Stat = require("XCommon/XScheduleStat")     -- Editor 真实统计 / Release noop
local IsEditor = XMain.IsEditorDebug

---------- Lua侧定时器内部实现 ----------
local FOREVER = 0
local IncId = 0
local ScheduleTable = {}     -- 活跃定时器 {[id] = schedule}
local AddList = {}            -- 待添加队列
local DeleteSet = {}          -- 待删除集合

-- 定时器节点对象池（与 C# XSchedulePool 对齐）
-- isDebug=false 关闭 XPool 的 Editor 深拷贝检测，避免高频路径上的开销
local function ResetSchedule(s)
    s.Id = 0
    s.Handler = nil
    s.Interval = 0
    s.Loop = 0
    s.Delay = 0
    s.Count = 0
    s.Timestamp = 0
end
local SchedulePool = XPool.New(
    function() local s = {}; ResetSchedule(s); return s end,
    ResetSchedule,
    false
)

local function InternalSchedule(handler, interval, loop, delay)
    IncId = IncId + 1
    local id = IncId
    local realDelay = delay or 0
    local s = SchedulePool:GetItemFromPool()
    s.Id = id
    s.Handler = handler
    s.Interval = interval             -- 毫秒
    s.Loop = loop
    s.Delay = realDelay               -- 毫秒
    s.Count = 0
    s.Timestamp = 0                   -- 毫秒，合入主表时由 Update 赋值
    AddList[#AddList + 1] = s
    if IsEditor then
        Stat.OnAdd(id, XTool.GetStackTraceName(), interval, loop, realDelay)
    end
    return id
end

-- C#每帧调用，传入毫秒（Time.timeAsDouble * 1000，double精度）
-- 顺序与 C# XScheduleManager.Update 严格对齐：触发 -> 合入 AddList -> 清理 DeleteSet
-- 这样本帧 Schedule() 创建的定时器仍在 AddList 里、不参与本帧触发，保证
-- ScheduleNextFrame(Delay=0,Interval=0) 必然下一帧才执行。
function XScheduleManager.Update(now)
    -- 1. 遍历检查触发（本帧新加的还在 AddList，不参与）
    for id, s in pairs(ScheduleTable) do
        if not DeleteSet[id] then
            if s.Loop ~= FOREVER and s.Count >= s.Loop then
                DeleteSet[id] = true
            else
                local triggerTime = s.Timestamp + s.Delay + s.Interval * (s.Count + 1)
                if now >= triggerTime then
                    local ok, err = xpcall(s.Handler, debug.traceback, s.Id)
                    if not ok then
                        XLog.Error("XScheduleManager Update error, id: " .. tostring(s.Id) .. ", error: " .. tostring(err))
                        DeleteSet[id] = true
                    end
                    s.Count = s.Count + 1
                    Stat.OnTrigger(id, s.Count)
                end
            end
        end
    end

    -- 2. 将待添加的定时器合入主表（Timestamp 在合入这一刻取，与 C# 行为对齐）
    for i = 1, #AddList do
        local s = AddList[i]
        s.Timestamp = now
        ScheduleTable[s.Id] = s
    end
    if #AddList > 0 then
        AddList = {}
    end

    -- 3. 处理删除
    local hasDelete = false
    for id in pairs(DeleteSet) do
        hasDelete = true
        local s = ScheduleTable[id]
        if s then
            ScheduleTable[id] = nil
            SchedulePool:ReturnItemToPool(s)
        end
        Stat.OnRemove(id)
    end
    if hasDelete then
        DeleteSet = {}
    end
end

---------- 公开API（签名与原有完全一致）----------

-- /// <summary>
-- /// 启动定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="interval">间隔毫秒（第一次执行在间隔时间后）</param>
-- /// <param name="loop">循环次数</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.Schedule(func, interval, loop, delay)
    return InternalSchedule(func, interval, loop, delay)
end

-- /// <summary>
-- /// 启动单次定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.ScheduleOnce(func, delay)
    return InternalSchedule(func, 0, 1, delay)
end

function XScheduleManager.ScheduleNextFrame(func)
    return InternalSchedule(func, 0, 1, 0)
end

-- /// <summary>
-- /// 启动指定时间单次定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="timeStamp">需要启动的时间</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.ScheduleAtTimestamp(func, timeStamp)
    local nowTime = XTime.GetServerNowTimestamp()
    if timeStamp <= nowTime then
        return
    end
    return XScheduleManager.ScheduleOnce(func, (timeStamp - nowTime) * XScheduleManager.SECOND)
end

-- /// <summary>
-- /// 启动永久定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="interval">间隔毫秒</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.ScheduleForever(func, interval, delay)
    return InternalSchedule(func, interval, FOREVER, delay)
end

-- /// <summary>
-- /// 启动永久定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="interval">间隔毫秒</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
-- /// PS:去除了XScheduleManager.ScheduleForever里计算时间自动叠加多一次的Interval
function XScheduleManager.ScheduleForeverEx(func, interval, delay)
    return InternalSchedule(func, interval, FOREVER, (delay or 0) - interval)
end

-- /// <summary>
-- /// 取消定时器
-- /// </summary>
-- /// <param name="id">定时器id</param>
function XScheduleManager.UnSchedule(id)
    if id then
        DeleteSet[id] = true
    end
end

-- /// <summary>
-- /// Editor调试：返回当前定时器统计快照（数组），供C#侧Inspector读取
-- /// 每项：{Name, RemainCount, TotalCreated, TotalTriggered, Interval, Delay, Loop, LastId, LastCount}
-- /// </summary>
function XScheduleManager.GetDebugSnapshot()
    return Stat.Snapshot()
end

-- /// <summary>
-- /// Editor调试：输出当前活跃定时器统计（按RemainCount降序）
-- /// </summary>
function XScheduleManager.DumpDebug()
    if not IsEditor then
        XLog.Warning("XScheduleManager.DumpDebug 仅Editor下可用")
        return
    end
    Stat.Dump()
end

local __Private = {}
__Private.__Clear__ = function ()
    if XMain.IsWindowsEditor then
        XLog.Debug("移除所有定时器")
    end
    -- 清空Lua侧定时器数据：先把节点回收回池，再丢弃容器
    for _, s in pairs(ScheduleTable) do
        SchedulePool:ReturnItemToPool(s)
    end
    for i = 1, #AddList do
        SchedulePool:ReturnItemToPool(AddList[i])
    end
    ScheduleTable = {}
    AddList = {}
    DeleteSet = {}
    IncId = 0
    Stat.Clear()
    XTool.ResetInitSchedule()
    -- 仍然清理C#侧（DontRemoveInAll的定时器仍在C#管理）
    CSXScheduleManager.UnScheduleAll()
end

-- 主动把 Update 委托回注到 C#，规避 XLua CSharpCallLua 委托类型注册要求
-- 一般不推荐写require时注册某些逻辑，因为require调用者可能没想到这个操作有附带逻辑
CSXScheduleManager.Register(XScheduleManager.Update)

return __Private
