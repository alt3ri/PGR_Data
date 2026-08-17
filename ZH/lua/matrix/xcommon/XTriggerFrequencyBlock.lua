---@class XTriggerFrequencyBlock 频率限制块：滑动窗口内最多触发 maxCount 次
---@field private _WindowSeconds number 窗口时间（秒）
---@field private _MaxCount number 窗口内最大触发次数
---@field private _Queue XQueue 时间戳队列
local XTriggerFrequencyBlock = XClass(nil, "XTriggerFrequencyBlock")

--- @param windowSeconds number 窗口时间（秒）
--- @param maxCount number 窗口内最大触发次数
function XTriggerFrequencyBlock:Ctor(windowSeconds, maxCount)
    self._WindowSeconds = windowSeconds or 1
    self._MaxCount = maxCount or 1
    self._Queue = XQueue.New()
end


---@return boolean
function XTriggerFrequencyBlock:CheckCanTrigger()
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    local queue = self._Queue
    -- 移除已过期的时间戳
    while queue:Count() > 0 and (now - queue:Peek()) >= self._WindowSeconds do
        queue:Dequeue()
    end
    return queue:Count() < self._MaxCount
end

--- 记录一次触发（仅在允许触发时才记录）
function XTriggerFrequencyBlock:TriggerRecord()
    if not self:CheckCanTrigger() then
        return
    end
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    self._Queue:Enqueue(now)
end

--- 重置
function XTriggerFrequencyBlock:Clear()
    self._Queue:Clear()
end

return XTriggerFrequencyBlock
