---@class XStateMachineController @状态机组件
---@field CurStateEnum number 当前状态枚举（onlyGet）
---@field _lastStateEnum number 上个状态枚举
---@field _nextStateEnum number 下个状态枚举
---@field _transitionDict table<number, table<number, XStateMachineTransition>> 状态转移方程 key1=fromState, key2=toState value = transition
---@field _stateDict table<number, XMachineBaseState> 状态字典 key = stateEnum, value = state
---@field _dataBoard table<number, number> 数据版 key = 键值, value = 数据（可以是bool、number、table等）
---@field _proxy XDlcCSharpFuncs
local XStateMachineController = XClass(nil, "XStateMachineController")

---@param proxy XDlcCSharpFuncs
function XStateMachineController:Ctor(proxy)
    self._proxy = proxy
end

function XStateMachineController:Init()
    self.CurStateEnum = 0
    self._lastStateEnum = 0
    self._nextStateEnum = 0
    self._transitionDict = {}
    self._stateDict = {}
    self._dataBoard = {}
end

function XStateMachineController:Update(dt)
    if self:CheckStateChange(dt) then
        self:SwitchState(self._nextStateEnum)
    end
    
    if self._stateDict[self.CurStateEnum] then
        self._stateDict[self.CurStateEnum]:OnStateUpdate(dt)
    end
end

---@param eventType number
---@param eventArgs userdata
function XStateMachineController:HandleEvent(eventType, eventArgs)
    if self._stateDict[self.CurStateEnum] then
        self._stateDict[self.CurStateEnum]:HandleEvent(eventType, eventArgs)
    end
    if self._transitionDict[self.CurStateEnum] then
        for _, transition in pairs(self._transitionDict[self.CurStateEnum]) do
            transition:HandleEvent(eventType, eventArgs)
        end
    end
end

function XStateMachineController:Terminate()
    self:TerminateTransition()
    self:TerminateState()
    self:TerminateDataBoard()
    self._proxy = nil
end

--region API
---添加状态
---@param stateEnum number
---@param state XMachineBaseState
function XStateMachineController:AddState(stateEnum, state, ...)
    state:Init(self._proxy, self, ...)
    self._stateDict[stateEnum] = state
end

---添加状态转移方程
---@param fromStateEnum number
---@param toStateEnum number
---@param transition XStateMachineTransition
function XStateMachineController:AddStateTransition(fromStateEnum, toStateEnum, transition, ...)
    local fromState = self:GetState(fromStateEnum)
    local toState = self:GetState(toStateEnum)
    if fromState == nil or toState == nil then
        XLog.Error("[脚本: "..self._proxy.Id.."]XStateMachineController.AddStateTransition Error: fromState或toState未注册")
        return
    end
    transition:InitBase(self._proxy, self, fromState, toState)
    transition:InitOther(...)
    if not self._transitionDict[fromStateEnum] then
        self._transitionDict[fromStateEnum] = {}
    end
    self._transitionDict[fromStateEnum][toStateEnum] = transition
end

---切换状态
---@param nextStateEnum number 下一个状态枚举
function XStateMachineController:SwitchState(nextStateEnum)
    if self.CurStateEnum ~= 0 and nextStateEnum == self.CurStateEnum then
        return
    end

    if nextStateEnum == 0 or self._stateDict[nextStateEnum] == nil then
        XLog.Error("[脚本: "..self._proxy.Id.."]XStateMachineController.SwitchState()Error 未注册状态: "..nextStateEnum)
        return
    end

    ---@type XStateMachineTransition
    local transition
    if self.CurStateEnum ~= 0 and self._transitionDict[self.CurStateEnum] then
        transition = self._transitionDict[self.CurStateEnum][nextStateEnum]
    end

    self:BeforeSwitchState()
    if transition then
        transition:OnTransitionBefore()
    end
    if self._stateDict[self.CurStateEnum] then
        self._stateDict[self.CurStateEnum]:OnStateLeave(nextStateEnum)
    end 
    self._stateDict[nextStateEnum]:OnStateEnter(self.CurStateEnum)
    if transition then
        transition:OnTransitionAfter()
    end

    self._nextStateEnum = 0
    self._lastStateEnum = self.CurStateEnum
    self.CurStateEnum = nextStateEnum
    --XLog.Error("[脚本: "..self._proxy.Id.."]XStateMachineController.SwitchState() 切换状态: "..nextStateEnum)
    self:AfterSwitchState()
end

function XStateMachineController:GetState(stateEnum)
    if self._stateDict[stateEnum] then
        return self._stateDict[stateEnum]
    end
    XLog.Error("[脚本: "..self._proxy.Id.."]XStateMachineController.GetState()Error 未注册状态: "..stateEnum)
end

function XStateMachineController:SetDataBoard(key, value)
    self._dataBoard[key] = value
end

function XStateMachineController:GetDataBoard(key)
    return self._dataBoard[key]
end

---判断数据黑板值
---@return boolean
function XStateMachineController:CheckDataBoard(key, value)
    if not self._dataBoard[key] then
        return false
    end
    return self._dataBoard[key] == value
end

---@protected
function XStateMachineController:BeforeSwitchState()

end

---@protected
function XStateMachineController:AfterSwitchState()

end
--endregion


--region State - 状态逻辑
---根据当前状态初始化
---@protected
function XStateMachineController:InitStateController(curStateEnum)
    self:SwitchState(curStateEnum)
end

---检查状态切换方程
---@protected
function XStateMachineController:CheckStateChange(dt)
    if not self._transitionDict[self.CurStateEnum] then
        return false
    end
    self._nextStateEnum = self.CurStateEnum
    for toState, transition in pairs(self._transitionDict[self.CurStateEnum]) do
        if transition:Condition(dt) then
            self._nextStateEnum = toState
            break
        end
    end
    if self._nextStateEnum == self.CurStateEnum then
        return false
    end
    return true
end

---清理状态
---@private
function XStateMachineController:TerminateState()
    for _, state in pairs(self._stateDict) do
        state:Terminate()
    end
    self._stateDict = nil
end
--endregion


--region Transition - 状态转移方程
---清理状态切换方程
---@private
function XStateMachineController:TerminateTransition()
    for _, transitionList in pairs(self._transitionDict) do
        for _, transition in pairs(transitionList) do
            transition:Terminate()
        end
    end
    self._transitionDict = nil
end
--endregion


--region DataBoard - 数据黑板
---@private
function XStateMachineController:TerminateDataBoard()
    self._dataBoard = nil
end
--endregion

return XStateMachineController