local XCafeBaseState = require("XModule/XSkyGardenCafe/StateMachine/XCafeBaseState")

local AnimationIndex = {
    First = 1,
    Second = 2,
}

---@class XCafeIdleState : XCafeBaseState 闲置状态
local XCafeIdleState = XClass(XCafeBaseState, "XCafeIdleState")

function XCafeIdleState:_OnEnter()
    local skeleton1 = self._Machine:GetSkeleton(AnimationIndex.First)
    if skeleton1 then
        skeleton1.gameObject:SetActiveEx(true)
        skeleton1.AnimationState:SetAnimation(0, "idle", true)
    else
        XLog.Error("XCafeIdleState:_OnEnter: Skeleton1 not found")
        self:DoExit()
    end
    local skeleton2 = self._Machine:GetSkeleton(AnimationIndex.Second)
    if skeleton2 then
        skeleton2.gameObject:SetActiveEx(false)
    else
        XLog.Error("XCafeIdleState:_OnEnter: Skeleton2 not found")
    end
end

---@class XCafePlayThenIdleState : XCafeBaseState 播放完后切换到Idle
local XCafePlayThenIdleState = XClass(XCafeBaseState, "XCafePlayThenIdleState")

function XCafePlayThenIdleState:_OnInit(animName, activeIndex)
    self._OnAnimationComplete = function(trackEntry)
        self:DoExit()
    end
    self._AnimaName = animName
    self._ActiveIndex = activeIndex
end

function XCafePlayThenIdleState:_OnEnter()
    local skeleton = self._Machine:GetSkeleton(self._ActiveIndex)
    for _, index in pairs(AnimationIndex) do
        if index ~= self._ActiveIndex then
            local otherSkeleton = self._Machine:GetSkeleton(index)
            if otherSkeleton then
                otherSkeleton.gameObject:SetActiveEx(false)
            else
                XLog.Error("XCafePlayThenIdleState:_OnEnter: Skeleton not found, index = ", index)
            end
        end
    end
    if skeleton then
        skeleton.gameObject:SetActiveEx(true)
        skeleton.AnimationState:SetAnimation(0, self._AnimaName, false)
        skeleton.AnimationState:Complete('+', self._OnAnimationComplete)
    else
        XLog.Error("XCafePlayThenIdleState:_OnEnter: Skeleton not found, index = ", self._ActiveIndex)
        self:DoExit()
    end
end

function XCafePlayThenIdleState:_OnExit()
    local skeleton = self._Machine:GetSkeleton(self._ActiveIndex)
    if skeleton then
        skeleton.AnimationState:Complete('-', self._OnAnimationComplete)
    else
        XLog.Error("XCafePlayThenIdleState:_OnExit: Skeleton not found, index = ", self._ActiveIndex)
    end
    
    
    self._Machine:ChangeState(XMVCA.XSkyGardenCafe.GamePetState.Idle)
end

---@class XCafeLongTimeWaitState : XCafePlayThenIdleState 播放完后切换到Idle
local XCafeLongTimeWaitState = XClass(XCafePlayThenIdleState, "XCafeLongTimeWaitState")

function XCafeLongTimeWaitState:_OnExit()
    XMVCA.XSkyGardenCafe:SetLastWaitTime(XTime.GetServerNowTimestamp())
    XCafePlayThenIdleState._OnExit(self)
end


---@class XCafeStateMachine 状态机
---@field _CurrentState XCafeBaseState
---@field _StateDict table<number,XCafeBaseState>
---@field _Skeleton1 Spine.Unity.SkeletonGraphic
---@field _Skeleton2 Spine.Unity.SkeletonGraphic
local XCafeStateMachine = XClass(nil, "XCafeStateMachine")

function XCafeStateMachine:Ctor()
    self._StateDict = {}
    self._CurrentState = nil
    self._IsInitParams = false
    for _, state in pairs(XMVCA.XSkyGardenCafe.GamePetState) do
        self:AddState(state)
    end
end

function XCafeStateMachine:_InitParams(skeleton1, skeleton2)
    self._Skeleton1 = skeleton1
    self._Skeleton2 = skeleton2
    self._IsInitParams = true
    if not self._CurrentState then
        self:ChangeState(XMVCA.XSkyGardenCafe.GamePetState.Idle)
    end
end

function XCafeStateMachine:ClearParams()
    self._Skeleton1 = nil
    self._Skeleton2 = nil
    self._CurrentState = nil
    self._IsInitParams = false
end

function XCafeStateMachine:ChangeState(state)
    if not self._IsInitParams then
        return false
    end
    if self._CurrentState and self._CurrentState:IsEnter() then
        local curPriority = self._CurrentState:GetPriority()
        -- 如果当前状态的优先级大于要切换的状态，则不切换
        if curPriority >= state then
            return false
        end
        self._CurrentState:DoExit()
    end
    local newState = self._StateDict[state]
    newState:DoEnter()
    
    self._CurrentState = newState
    return true
end

function XCafeStateMachine:AddState(stateValue)
    if self._StateDict[stateValue] then
        XLog.Error("XCafeStateMachine:AddState: State already exists, stateValue = ", stateValue)
        return
    end
    local state
    if stateValue == XMVCA.XSkyGardenCafe.GamePetState.Idle then
        state = XCafeIdleState.New(self, stateValue)
    elseif stateValue == XMVCA.XSkyGardenCafe.GamePetState.LongTimeWait then
        state = XCafeLongTimeWaitState.New(self, stateValue, "wuyu", AnimationIndex.First)
    elseif stateValue == XMVCA.XSkyGardenCafe.GamePetState.AddReview then
        state = XCafePlayThenIdleState.New(self, stateValue, "miyan", AnimationIndex.First)
    elseif stateValue == XMVCA.XSkyGardenCafe.GamePetState.AddCoffee then
        state = XCafePlayThenIdleState.New(self, stateValue, "caimi", AnimationIndex.Second)
    elseif stateValue == XMVCA.XSkyGardenCafe.GamePetState.Settle then
        state = XCafePlayThenIdleState.New(self, stateValue, "record", AnimationIndex.Second)
    end
    
    if not state then
        XLog.Error("XCafeStateMachine:AddState: Invalid stateValue = ", stateValue)
        return
    end
    self._StateDict[stateValue] = state
end

---@return Spine.Unity.SkeletonGraphic
function XCafeStateMachine:GetSkeleton(index)
    if index == AnimationIndex.First then
        if not self._Skeleton1 then
            XLog.Error("XCafeStateMachine:GetSkeleton: Skeleton1 not initialized")
            return nil
        end
        return self._Skeleton1
    elseif index == AnimationIndex.Second then
        if not self._Skeleton2 then
            XLog.Error("XCafeStateMachine:GetSkeleton: Skeleton2 not initialized")
            return nil
        end
        return self._Skeleton2
    end
    XLog.Error("XCafeStateMachine:GetSkeleton: Invalid index = ", index)
    return nil
end

function XCafeStateMachine:Clear()
    self._StateDict = nil
    self._CurrentState = nil
    self._Skeleton1 = nil
    self._Skeleton2 = nil
    self._IsInitParams = false
end

return XCafeStateMachine