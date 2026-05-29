--region state

---肉鸽6状态基类, 使用时注意以下事项
---| 搭配肉鸽6状态机使用
---| 此类为抽象类,不能直接实例化. 需要先派生子类再使用
---@class XTheatre6State
---@field Start fun(state:self) 状态进入逻辑
---@field ReEnter fun(state:self) 状态重进逻辑
---@field End fun(state:self, newState:XTheatre6State) 状态退出逻辑
---@field Update fun(state:self, dt:number) 状态更新逻辑
---@field Name string 状态名(静态变量)
---@field Id integer 状态Id(静态变量)
local XTheatre6State = XClass(nil, "XTheatre6State")

---@param stateMachine XTheatre6StateMachine
function XTheatre6State:Init(stateMachine)
    self._stateMachine = stateMachine --肉鸽6状态机
    self._owner = stateMachine._owner --肉鸽6角色脚本或关卡脚本
    self._proxy = self._owner._proxy ---@type XDlcCSharpFuncs c#脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

---设置状态Id(静态方法)
---@param StateClass XTheatre6State XTheatre6State的子类
---@param name string 状态名
---@param id integer 状态Id
function XTheatre6State.SetStaticKey(StateClass, name, id)
    if StateClass == XTheatre6State then
        XLog.Error("XTheatre6State.SetId Error: Set Abstract Id")
        return
    end
    StateClass.Name = name
    StateClass.Id = id
end

function XTheatre6State:LogError(str)
    return self._owner:LogError("State." .. self.Name .. "." .. self.Id .. ": " .. str)
end

--endregion

--region stateMachine

---肉鸽6状态机基类, 使用时注意以下事项
---| 搭配肉鸽6状态使用
---| 此类为抽象类,不能直接实例化. 需要先派生子类再使用
---@class XTheatre6StateMachine
---@field StateClasses table<string|integer, XTheatre6State>
local XTheatre6StateMachine = XClass(nil, "XTheatre6StateMachine")

---@param owner XTheatre6FightBase
function XTheatre6StateMachine:Ctor(owner)
    self._owner = owner
    self._curState = nil ---@type XTheatre6State

    local states = {} ---@type table<string|integer, XTheatre6State>
    for key, stateClass in pairs(self.StateClasses) do
        if states[key] then goto continue end
        local state = stateClass.New()
        state:Init(self)
        states[state.Id] = state
        states[state.Name] = state
        ::continue::
    end
    self._states = states
end

---更新逻辑
function XTheatre6StateMachine:Update(dt)
    if not (self._curState and self._curState.Update) then return end

    return self._curState:Update(dt)
end

---修改状态
---@param newStateId integer
function XTheatre6StateMachine:SetStateById(newStateId)
    local newState = newStateId and self._states[newStateId]
    local owner = self._owner
    if not newState then
        owner:LogError("XTheatre6StateMachine.SetStateById Error: Unknown Id " .. tostring(newStateId))
        return
    end

    local oldState = self._curState
    if oldState == newState then return newState.ReEnter and newState:ReEnter() end

    -- owner:LogError(".XTheatre6StateMachine.SetStateById is called. State changes from " ..
    --     tostring(oldState and oldState.Name) .. " to " .. tostring(newState and newState.Name))

    if oldState and oldState.End then oldState:End(newState) end
    self._curState = newState
    if newState.Start then newState:Start() end
end

---检查状态
---@param stateId integer
function XTheatre6StateMachine:CheckStateById(stateId)
    local curState = self._curState
    return curState and curState.Id == stateId
end

---获取状态实例列表
---@return table<string|integer, XTheatre6State>
function XTheatre6StateMachine:GetStates()
    return self._states
end

---@param id integer
---@return XTheatre6State
function XTheatre6StateMachine:GetStateById(id)
    return self._states[id]
end

function XTheatre6StateMachine:GetCurStateId()
    return self._curState and self._curState.Id
end

---@private
---创建肉鸽6状态派生类
---@param stateEnum table<string, integer> 类型枚举表
---@param namePrefix string 类名前缀,用于为新生成的state类创建名称
---@return table<string|integer, XTheatre6State>
function XTheatre6StateMachine.CreateStateClassByEnum(stateEnum, namePrefix)
    local states = {}
    for stateName, id in pairs(stateEnum) do
        if states[id] then
            XLog.Error("XTheatre6StateMachine.CreateStateClasses Error: repeated stateId " .. id)
            goto continue
        end
        if states[stateName] then
            XLog.Error("XTheatre6StateMachine.CreateStateClasses Error: repeated stateName " .. stateName)
            goto continue
        end
        local stateClass = XClass(XTheatre6State, namePrefix .. ".State." .. stateName)
        stateClass:SetStaticKey(stateName, id)
        states[id] = stateClass
        states[stateName] = stateClass
        ::continue::
    end
    return states
end

---通过枚举创建肉鸽6状态机和肉鸽6状态的派生类
---@param stateEnum table<string, integer> 类型枚举表
---@param namePrefix string 类名前缀,用于为新生成的state类创建名称
---@return XTheatre6StateMachine stateMachine 肉鸽6状态机派生类
---@return table<string|integer, XTheatre6State> states 肉鸽6状态派生类列表
function XTheatre6StateMachine:CreateClassByEnum(stateEnum, namePrefix)
    if type(namePrefix) ~= "string" then
        XLog.Error("XTheatre6StateMachine.CreateStateClasses Error: illegal namePrefix")
        return
    end

    local smClass = XClass(XTheatre6StateMachine, namePrefix .. ".StateMachine")
    local stateClasses = self.CreateStateClassByEnum(stateEnum, namePrefix)
    smClass.StateClasses = stateClasses
    return smClass, stateClasses
end

---@private
---创建肉鸽6状态派生类
---@param states table<string|integer, XTheatre6State> 父类列表
---@param namePrefix string 类名前缀,用于为新生成的state类创建名称
---@return table<string|integer, XTheatre6State>
function XTheatre6StateMachine:CreateStateClassByClass(namePrefix)
    local _states = {}
    for key, state in pairs(self.StateClasses) do
        if _states[key] then goto continue end
        local name, id = state.Name, state.Id
        local stateClass = XClass(state, namePrefix .. ".State." .. name)
        stateClass:SetStaticKey(name, id)
        _states[id] = stateClass
        _states[name] = stateClass
        ::continue::
    end
    return _states
end

---通过父类创建肉鸽6状态机和肉鸽6状态的派生类

---@param namePrefix string 类名前缀,用于为新生成的state类创建名称
---@return XTheatre6StateMachine stateMachine 肉鸽6状态机派生类
---@return table<string|integer, XTheatre6State> states 肉鸽6状态派生类列表
function XTheatre6StateMachine:CreateChildClasses(namePrefix)
    if type(namePrefix) ~= "string" then
        XLog.Error("XTheatre6StateMachine.CreateStateClasses Error: illegal namePrefix")
        return
    end

    local smClass = XClass(self, namePrefix .. ".StateMachine")
    local stateClasses = self:CreateStateClassByClass(namePrefix)
    smClass.StateClasses = stateClasses
    return smClass, stateClasses
end

--endregion

do return XTheatre6StateMachine end
