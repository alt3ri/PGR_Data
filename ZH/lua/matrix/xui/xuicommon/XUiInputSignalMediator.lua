--- 输入信号中介者，用于统筹和中转输入信号
---@class XUiInputSignalMediator: XUiNode
local XUiInputSignalMediator = XClass(XUiNode, 'XUiInputSignalMediator')

function XUiInputSignalMediator:OnStart(signalMap)
    self.SignalTypeList = {}
    
    if not XTool.IsTableEmpty(signalMap) then
        for signalTypeName, signalType in pairs(signalMap) do
            table.insert(self.SignalTypeList, signalType)
        end
        
        -- 按照类型从小到达大排序
        table.sort(self.SignalTypeList, function(a, b)
            return a < b
        end)
    end
    
    -- 同类互斥信号记录，key是信号类型，value是当前正在处理的该类信号的id
    self.MutexSignalRecord = {}
    
    -- 各种类型信号的处理函数映射，key是信号类型，value是处理函数
    self.SignalHandlerMap = {}
end

function XUiInputSignalMediator:OnDestroy()
    self:StopInputSignalUpdateTimer()
    
    self.SignalTypeList = nil
    self.MutexSignalRecord = nil
    self.SignalHandlerMap = nil
end

--- 接收输入信号，参数1是类型，参数2是任意值
function XUiInputSignalMediator:ReceiveInputSignal(signalType, signalData)
    -- 如果是互斥信号，检查是否有同类信号正在处理
    if self.MutexSignalRecord[signalType] then
        return false
    end

    -- 标记该类信号正在处理
    self.MutexSignalRecord[signalType] = signalData or true
end

--- 清空所有输入信号记录
function XUiInputSignalMediator:ClearAllInputSignalRecord()
    if XTool.IsTableEmpty(self.MutexSignalRecord) then
        return
    end
    
    for i, v in pairs(self.SignalTypeList) do
        self.MutexSignalRecord[v] = nil
    end
end

--- 注册信号处理函数
function XUiInputSignalMediator:RegisterSignalHandler(signalType, handlerFunc)
    self.SignalHandlerMap[signalType] = handlerFunc
end

--region 定时器更新

--- 启用信号处理定时器，间隔0.1s更新即可
function XUiInputSignalMediator:StartInputSignalUpdateTimer()
    self:StopInputSignalUpdateTimer()

    self:ClearAllInputSignalRecord()
    
    self.SignalHandleTimer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 100)
end

function XUiInputSignalMediator:StopInputSignalUpdateTimer()
    if not self.SignalHandleTimer then
        return
    end

    XScheduleManager.UnSchedule(self.SignalHandleTimer)
    self.SignalHandleTimer = nil

    self:ClearAllInputSignalRecord()
end

--- 更新逻辑主体，执行时按照顺序读取第一个信号输入，调用对应的处理函数，其信号值作为参数传入
function XUiInputSignalMediator:Update()
    for i, signalType in pairs(self.SignalTypeList) do
        local signalData = self.MutexSignalRecord[signalType]
        if signalData then
            local handlerFunc = self.SignalHandlerMap[signalType]
            
            if handlerFunc then
                handlerFunc(signalData)
            end
            -- 每次更新只处理一个信号
            break
        end
    end
    
    -- 清理所有信号记录，防止遗漏
    self:ClearAllInputSignalRecord()
end

--endregion

return XUiInputSignalMediator