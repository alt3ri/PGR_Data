--- 大巴扎表现层事件总线(env 级服务,单局尺度)
--- 承接 VM:Emit 的语义事件:一帧内累积"哪些类型的状态变了"(EventEnum 键去重),
---   帧尾由上层 Drain 抽干后派发给表现层。事件只带身份(枚举键)不带值,值由 Reader 拉。
--- 不进事务 journal(表现事件在模拟之外,保回放确定性);回滚导致的过标记无害(UI 多拉一次现值)。
---@class XPresentEventBus
---@field _Set XHash 本帧事件类型去重集(存 STECustomEnum.EventEnum 数字键)
local XPresentEventBus = XClass(nil, "XPresentEventBus")
local XHash = require("XCommon/XHash")

function XPresentEventBus:Ctor()
    self._Set = XHash.New()
end

--- 承接 vm:Emit(签名对齐 events:Emit(eventType, args))。
--- args 有意丢弃:本通道只记"哪类状态变了"(身份/枚举键),不搬运值;
---   表现层收到事件后自行经 Reader 拉当前值,避免事件携带易失快照。
---@param eventType number STECustomEnum.EventEnum 键
---@param args table|nil 有意不接(仅为对齐 VM:Emit 签名)
function XPresentEventBus:Emit(eventType, args)
    self._Set:Add(eventType)
end

--- 抽干本帧累积的事件类型到 out(填充式导出+自清)。
--- 遵循项目 Fill 契约:调用方负责 out 的清空;内部 table 不外泄(只逐个拷键)。
--- 抽干即清:导出后清空去重集,下帧重新累积。
---@param out XList 调用方提供并自清的容器,本帧事件键按序写入
---@return number count 写入个数
function XPresentEventBus:Drain(out)
    -- out 为 XList 实例（调用方自清 + 复用），:Append 追加事件键，零 per-call GC
    local n = self._Set:Count()
    for i = 1, n do
        out:Append(self._Set:GetByIndex(i))
    end
    self._Set:Clear()
    return n
end

--- 不消费直接清(换局/异常兜底)。
function XPresentEventBus:Clear()
    self._Set:Clear()
end

return XPresentEventBus
