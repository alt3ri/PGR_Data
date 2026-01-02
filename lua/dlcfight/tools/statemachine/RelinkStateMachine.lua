--- @class RelinkStateMachine @Relink通用状态机
local RelinkStateMachine = XClass(nil, "RelinkStateMachine")

function RelinkStateMachine:Ctor(name)
    self._name = name

    --- 是否启用
    self._enabled = false

    --- 默认状态Id
    self._defaultStateId = 0
    --- 当前状态Id
    self._curStateId = 0
    --- 当前状态计时器
    self._stateTimer = 0

    --- @class RelinkSMTransition
    --- @field tarStateId int
    --- @field predicate function
    --- @field priority int
    --- @field normalizedExitTime number

    --- @class RelinkSMState
    --- @field name string
    --- @field enter function
    --- @field update function
    --- @field exit function
    --- @field transitions RelinkSMTransition[]
    --- @field duration number

    --- @class RelinkSMTrigger
    --- @field isOn boolean

    --- @type RelinkSMState[]
    self._states = {}

    --- @type RelinkSMTrigger[]
    self._triggers = {}

    self._enterStateCallback = nil
    self._exitStateCallback = nil
    self._onStateChangedHandler = nil
end

function RelinkStateMachine:Update(dt)
    if not self._enabled then
        return
    end

    local curState = self._states[self._curStateId]
    if curState == nil then
        return
    end

    -- 更新计时器 以及 状态函数
    self._stateTimer = self._stateTimer + dt
    if curState.update ~= nil then curState.update(dt) end

    -- 遍历检测转换，查找是否可以变更状态
    local tarStateId = nil
    local curPriority = math.mininteger
    for index, transition in pairs(curState.transitions) do
        local isPredicatePass = true
        if transition.predicate ~= nil then
            isPredicatePass = transition.predicate()
        end
        local isTimeCondPass = (self._stateTimer / curState.duration) >= transition.normalizedExitTime
        local isPriorityPass = transition.priority > curPriority
        if isPredicatePass ~= nil and isPredicatePass and isTimeCondPass and isPriorityPass then
            tarStateId = transition.tarStateId
            curPriority = transition.priority
        end
    end

    -- 状态转换
    if tarStateId ~= nil then
        local tarState = self._states[tarStateId]
        if tarState ~= nil then
            if curState.exit ~= nil then curState.exit() end

            local previousStateId = self._curStateId
            self._curStateId = tarStateId
            self._stateTimer = 0

            if tarState.enter ~= nil then
                tarState.enter()
            end

            self:InvokeOnStateChanged(previousStateId, tarStateId)
        end
    end

    -- 重置所有触发器
    self:ResetAllTriggers()
end

function RelinkStateMachine:Activate()
    if self._states[self._defaultStateId] == nil then
        return
    end

    self._enabled = true

    self._curStateId = self._defaultStateId
    local curState = self._states[self._curStateId]
    if curState.enter ~= nil then
        curState.enter()
    end
    self:InvokeOnStateChanged(nil, self._curStateId)
end

function RelinkStateMachine:Enable()
    self._enabled = true
end

function RelinkStateMachine:Disable()
    self._enabled = false
end

function RelinkStateMachine:Terminate()
    self._name = nil
    self._enabled = nil
    self._defaultStateId = nil
    self._curStateId = nil
    self._stateTimer = nil
    self._states = nil
    self._triggers = nil
    self._enterStateCallback = nil
    self._exitStateCallback = nil
    self._onStateChangedHandler = nil
end

function RelinkStateMachine:SetStateAsDefault(stateId)
    if self._states[stateId] ~= nil then
        self:Warning("状态不存在，无法设置为默认状态，状态id " .. tostring(stateId))
    end

    self._defaultStateId = stateId
end

--- 同步状态，将指定状态设立为当前状态，并且不会触发进入状态的事件
function RelinkStateMachine:SyncState(stateId)
    if self._states[stateId] == nil then
        self:Warning("状态不存在，无法同步状态，状态id " .. tostring(stateId))
    end

    self._curStateId = stateId
end

--- 添加状态
--- @param stateId int @ 状态Id
--- @param name string @ 状态名称
--- @param enterFunc function @ 进入函数
--- @param updateFunc function @ 更新函数
--- @param exitFunc function @ 退出函数
--- @param duration number @ 持续时间
function RelinkStateMachine:AddState(stateId, name, enterFunc, updateFunc, exitFunc, duration)
    if self._states[stateId] ~= nil then
        self:Warning("尝试重复添加已存在的状态")
        return
    end

    self._states[stateId] = {
        name = name,
        enter = enterFunc,
        update = updateFunc,
        exit = exitFunc,
        transitions = {},
        duration = duration
    }
end

function RelinkStateMachine:GetState(stateId)
    if self._states[stateId] == nil then
        self:Warning("尝试获取的状态不存在，状态id " .. tostring(stateId))
        return nil
    end

    return self._states[stateId]
end

function RelinkStateMachine:ChangeState(tarStateId)
    local curState = nil
    if self._curStateId ~= nil then
        curState = self:GetState(self._curStateId)
    end
    local tarState = self:GetState(tarStateId)
    if tarState ~= nil then
        if curState.exit ~= nil then curState.exit() end

        local previousStateId = self._curStateId
        self._curStateId = tarStateId
        self._stateTimer = 0

        if tarState.enter ~= nil then
            tarState.enter()
        end

        self:InvokeOnStateChanged(previousStateId, tarStateId)
    end
end

function RelinkStateMachine:GetCurStateId()
    if self._curStateId ~= nil then
        return self._curStateId
    end
    return nil
end

function RelinkStateMachine:AddTransition(stateId, tarStateId, transitionId, predicate, priority, normalizedExitTime)
    if self._states[stateId] == nil then
        self:Error("状态不存在，状态id " .. tostring(stateId))
        return
    end

    if self._states[stateId].transitions[transitionId] ~= nil then
        self:Error("尝试添加重复ID的转换")
        return
    end

    self._states[stateId].transitions[transitionId] = {
        tarStateId = tarStateId,
        predicate = predicate,
        priority = priority,
        normalizedExitTime = normalizedExitTime
    }
end

function RelinkStateMachine:SetTransition(stateId, transitionId, predicate, priority, normalizedExitTime)
    if self._states[stateId] == nil then
        self:Error("状态不存在，状态id " .. tostring(stateId))
        return
    end

    if self._states[stateId].transitions[transitionId] == nil then
        self:Error("尝试设置不存在的转换")
        return
    end

    self._states[stateId].transitions[transitionId].predicate = predicate
    self._states[stateId].transitions[transitionId].priority = priority
    self._states[stateId].transitions[transitionId].normalizedExitTime = normalizedExitTime
end

function RelinkStateMachine:AddTrigger(triggerId)
    if self._triggers[triggerId] ~= nil then
        self:Warning("尝试重复添加已存在的触发器")
        return
    end

    self._triggers[triggerId] = {
        isOn = false
    }
end

function RelinkStateMachine:CheckTrigger(triggerId)
    if self._triggers[triggerId] == nil then
        self:Warning("尝试检测不存在的触发器")
        return
    end

    return self._triggers[triggerId].isOn
end

function RelinkStateMachine:SetTrigger(triggerId)
    if not self._enabled then
        return
    end

    if self._triggers[triggerId] == nil then
        self:Warning("尝试设置不存在的触发器")
        return
    end

    self._triggers[triggerId].isOn = true
end

function RelinkStateMachine:ResetTrigger(triggerId)
    if not self._enabled then
        return
    end

    if self._triggers[triggerId] == nil then
        self:Warning("尝试重置不存在的触发器")
        return
    end

    self._triggers[triggerId].isOn = false
end

function RelinkStateMachine:ResetAllTriggers()
    for id, trigger in pairs(self._triggers) do
        self:ResetTrigger(id)
    end
end

--region Event
function RelinkStateMachine:InvokeOnStateChanged(previousStateId, nextStateId)
    if self._onStateChangedHandler == nil then return end
    self._onStateChangedHandler(previousStateId, nextStateId)
end

function RelinkStateMachine:RegisterOnStateChanged(callback)
    if callback == nil then return end
    self._onStateChangedHandler = callback
end
--endregion

--region Log
function RelinkStateMachine:Log(text)
    XLog.Debug("状态机[" .. self._name .. "]: " .. text)
end
function RelinkStateMachine:Warning(text)
    XLog.Warning("状态机[" .. self._name .. "]: " .. text)
end
function RelinkStateMachine:Error(text)
    XLog.Error("状态机[" .. self._name .. "]: " .. text)
end
--endregion

return RelinkStateMachine