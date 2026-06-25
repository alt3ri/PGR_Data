-- XScheduleManager 的运行时统计模块。
-- Editor 下做真实统计；Release 下整个接口表都是 noop，主模块可以无条件调用，
-- 避免在 Update 热路径里反复检查 IsEditor。

local M = {}

if not XMain.IsEditorDebug then
    M.OnAdd = function() end
    M.OnRemove = function() end
    M.OnTrigger = function() end
    M.Snapshot = function() return nil end
    M.Dump = function() end
    M.Clear = function() end
    return M
end

-- ============ Editor 实现 ============
-- DebugDict: { [name] = {RemainCount, TotalCreated, TotalTriggered, Interval, Delay, Loop, LastId, LastCount} }
-- IdToName : { [id]   = name }   触发/取消时反查
local DebugDict = {}
local IdToName = {}

function M.OnAdd(id, name, interval, loop, delay)
    local d = DebugDict[name]
    if not d then
        d = { RemainCount = 0, TotalCreated = 0, TotalTriggered = 0,
              Interval = interval, Delay = delay, Loop = loop,
              LastId = id, LastCount = 0 }
        DebugDict[name] = d
    end
    d.RemainCount  = d.RemainCount  + 1
    d.TotalCreated = d.TotalCreated + 1
    d.Interval = interval
    d.Delay    = delay
    d.Loop     = loop
    d.LastId   = id
    IdToName[id] = name
end

function M.OnRemove(id)
    local name = IdToName[id]
    if not name then return end
    IdToName[id] = nil
    local d = DebugDict[name]
    if d then
        d.RemainCount = d.RemainCount - 1
    end
end

function M.OnTrigger(id, count)
    local name = IdToName[id]
    if not name then return end
    local d = DebugDict[name]
    if d then
        d.TotalTriggered = d.TotalTriggered + 1
        d.LastCount = count
    end
end

function M.Snapshot()
    local list = {}
    for name, d in pairs(DebugDict) do
        list[#list + 1] = {
            Name = name,
            RemainCount    = d.RemainCount,
            TotalCreated   = d.TotalCreated,
            TotalTriggered = d.TotalTriggered,
            Interval = d.Interval,
            Delay    = d.Delay,
            Loop     = d.Loop,
            LastId   = d.LastId,
            LastCount = d.LastCount,
        }
    end
    return list
end

function M.Dump()
    local list = M.Snapshot()
    table.sort(list, function(a, b) return a.RemainCount > b.RemainCount end)
    XLog.Debug(string.format("==== XScheduleManager Dump (活跃定时器组数=%d) ====", #list))
    XLog.Debug("Name | Remain | Created | Triggered | Interval(ms) | Loop")
    for i = 1, #list do
        local d = list[i]
        XLog.Debug(string.format("%s | %d | %d | %d | %d | %d",
            d.Name, d.RemainCount, d.TotalCreated, d.TotalTriggered, d.Interval, d.Loop))
    end
end

function M.Clear()
    for k in pairs(DebugDict) do DebugDict[k] = nil end
    for k in pairs(IdToName) do IdToName[k] = nil end
end

return M
