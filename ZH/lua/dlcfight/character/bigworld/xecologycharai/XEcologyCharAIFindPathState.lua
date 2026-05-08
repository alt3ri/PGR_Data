local XFindPathState = require("Common/StateMachine/State/XFindPathState")

---@class XEcologyCharAIFindPathState: XFindPathState @生态AI寻路状态
---@field StateConfig XEcologyCharAIStateConfig
local XEcologyCharAIFindPathState = XClass(XFindPathState, "XEcologyCharAIFindPathState")

---@overload
function XEcologyCharAIFindPathState:SetPath(path, checkDistance)
    XFindPathState.SetPath(self, path, checkDistance)
    self._waitTimeLimit = 10
    self._curWaitTime = 0
    -- 记录寻路目标状态
    for enum, pos in pairs(self.StateConfig.PathTargetPosDict) do
        if XScriptTool.EqualVector3(pos, self.StartPos) then
            --XScriptTool.EcologyError("记录寻路目标枚举："..enum)
            self._proxy:SetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathStartStateEnum, enum)
        end
    end
end

---@overload
function XEcologyCharAIFindPathState:OnMoveNext()
    --XScriptTool.EcologyError("记录当前为第"..self._curPathPointIndex.."个路径点", self._curTargetPathPoint)
    self._proxy:SetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathCuePathIndex, self._curPathPointIndex)
end

---@overload
function XEcologyCharAIFindPathState:OnStateEnter(lastStateEnum)
    if self.StateConfig == nil then
        XScriptTool.EcologyError(self, "生态AI没有初始化数据")
        return
    end
    self.StateEnum = self.StateConfig.StateEnum
    self._proxy:SetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.CurStateEnum, self.StateConfig.StateEnum)

    self:UpdateOptionActive()
    self:RegisterWorldEvent()
    XFindPathState.OnStateEnter(self, lastStateEnum)
end

---@overload
function XEcologyCharAIFindPathState:OnStateUpdate(dt)
    if self.StateConfig == nil then
        return
    end

    self:UpdateWait(dt)
    self:UpdateStop2Move(dt)
    XFindPathState.OnStateUpdate(self, dt)
end

---@overload
function XEcologyCharAIFindPathState:OnStateLeave()
    if self.StateConfig == nil then
        return
    end
    self:UnRegisterWorldEvent()
    self._proxy:NpcStopMove(self._uuid)
end

---@overload
function XEcologyCharAIFindPathState:HandleEvent(eventType, eventArgs)
    if self.StateConfig == nil then
        return
    end
    if eventType == EWorldEvent.ActorTrigger then
        self:OnActorTrigger(eventArgs)
    elseif eventType == EWorldEvent.NpcInteractStart then
        self:OnNpcInteractStart(eventArgs)
    end
end

---@overload
function XEcologyCharAIFindPathState:SetMoveState(value)
    self._isMove = value
    if not self._isMove then
        self._curWaitTime = self._waitTimeLimit
    else
        self._curWaitTime = 0
    end
end

--region WorldEvent监听及处理
---@private
function XEcologyCharAIFindPathState:RegisterWorldEvent()
    for _, event in pairs(self.StateConfig.RegisterWorldEventList) do
        self._proxy:RegisterEvent(event)
    end
end

---@private
function XEcologyCharAIFindPathState:UnRegisterWorldEvent()
    for _, event in pairs(self.StateConfig.RegisterWorldEventList) do
        self._proxy:UnregisterEvent(event)
    end
end

function XEcologyCharAIFindPathState:OnActorTrigger(eventArgs)
    -- 不是玩家触发且定义触发的TriggerId不执行逻辑
    if eventArgs.TriggerId ~= self.StateConfig.TriggerId
            or self._uuid ~= eventArgs.TriggerHolderUUID
            or not self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID)
    then
        return
    end

    if eventArgs.TriggerState == ETriggerState.Enter then
        self:OnMeetCommander()
    end
end

function XEcologyCharAIFindPathState:OnNpcInteractStart(eventArgs)
    -- 被交互的不是自己不走逻辑
    if eventArgs.TargetId ~= self._uuid then
        return
    end
    if self.StateConfig.PathBubbleName then
        self._proxy:StopDramaBubble(ETargetActorType.Npc, self._uuid)
    end
    self:StopMove()
end
--endregion

--region 初始化
---状态配置初始化
---@overload
function XEcologyCharAIFindPathState:InitStateConfig()
    self.StateConfig = nil
end
--endregion

--region 交互
function XEcologyCharAIFindPathState:UpdateOptionActive()
    self._proxy:SetNpcInteractOneOptionActive(self._placeId, self.StateConfig.ShowOptionId)
end
--endregion

--region 
function XEcologyCharAIFindPathState:OnMeetCommander()
    -- 等待结束离开的npc在0.5秒内不停下
    if self._curWaitTime > 0 then
        return
    end
    -- 行走中的npc在剧情时不停下
    if not self._isMove or self._proxy:HasRunningDrama() then
        return
    end
    if self.StateConfig.PathBubbleName then
        self._proxy:PlayDramaBubble(ETargetActorType.Npc, self._uuid, self.StateConfig.PathBubbleName)
    end
    self:StopMove()
    self._proxy:EnableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
    self._proxy:TurnNpc(self._uuid,self._proxy:GetLocalPlayerNpcId(),"Drama_Stand_01")
end

function XEcologyCharAIFindPathState:OnLeaveCommander()
    if self.StateConfig.PathBubbleName then
        self._proxy:StopDramaBubble(ETargetActorType.Npc, self._uuid)
    end
    self:ContinueMove()
    self._proxy:DisableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
end

function XEcologyCharAIFindPathState:UpdateStop2Move(dt)
    if self._isMove then
        return
    end

    if self._proxy:CheckNpcDistance(self._uuid, self._proxy:GetLocalPlayerNpcId(), 3.5) then
        return
    end

    -- 离开后1s选择离开
    if self._curWaitTime > 1 then
        self._curWaitTime = 1
    end
end
--endregion

--region 拦路等待计时
function XEcologyCharAIFindPathState:UpdateWait(dt)
    -- 停下时在剧情中则不计时离开
    if self._isMove then
        if self._curWaitTime > 0 then
            self._curWaitTime = self._curWaitTime - dt
        end
        return
    end
    if self._proxy:HasRunningDrama() then
        return
    end
    self._curWaitTime = self._curWaitTime - dt
    if self._curWaitTime <= 0 then
        self:OnLeaveCommander()
        -- 主动离开的有0.5秒的停下冷却
        self._curWaitTime = 0.5
    end
end
--endregion

return XEcologyCharAIFindPathState