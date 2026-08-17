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
    if queue:Count() >= self._MaxCount then
        if now - queue:Peek() < self._WindowSeconds then
            return false
        end
    end
    return true
end

--- 记录一次触发
function XTriggerFrequencyBlock:TriggerRecord()
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    local queue = self._Queue
    if queue:Count() >= self._MaxCount then
        -- 队列已满（窗口已过期）：清空并用当前时间填满，
        -- 使窗口从当前时间重新起算，避免旧记录相继过期导致连续放行
        queue:Clear()
        for i = 1, self._MaxCount do
            queue:Enqueue(now)
        end
    else
        queue:Enqueue(now)
    end
end

--- 重置
function XTriggerFrequencyBlock:Clear()
    self._Queue:Clear()
end

return XTriggerFrequencyBlock
