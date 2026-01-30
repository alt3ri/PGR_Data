---@class XCafeBaseState 基础状态
---@field _Machine XCafeStateMachine
---@field _State number
local XCafeBaseState = XClass(nil, "XCafeBaseState")

local RunState = {
    Enter = 1,
    Exit = 2,
}

function XCafeBaseState:Ctor(machine, state, ...)
    self._Machine = machine
    self._State = state
    self:_OnInit(...)
end

function XCafeBaseState:_OnInit(...)
end

function XCafeBaseState:DoEnter()
    self._RunState = RunState.Enter
    self:_OnEnter()
end

function XCafeBaseState:_OnEnter()
end

function XCafeBaseState:DoExit()
    if self._RunState == RunState.Exit then
        return
    end
    
    self._RunState = RunState.Exit
    self:_OnExit()
end

function XCafeBaseState:_OnExit()
end

function XCafeBaseState:GetPriority()
    return self._State
end

function XCafeBaseState:IsEnter()
    return self._RunState == RunState.Enter
end

return XCafeBaseState