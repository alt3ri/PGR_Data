local XFindPathState = require("Common/StateMachine/State/XFindPathState")

---@class XEcologyCharAIFindPathState: XFindPathState @生态AI寻路状态
---@field StateConfig XEcologyCharAIStateConfig
local XEcologyCharAIFindPathState = XClass(XFindPathState, "XEcologyCharAIFindPathState")

---@overload
function XEcologyCharAIFindPathState:SetPath(path, checkDistance)
    XFindPathState.SetPath(self, path, checkDistance)
    self._waitTimeLimit = 120
    self._curWaitTime = 0
    -- 记录寻路目标状态
    for enum, pos in pairs(self.StateConfig.PathTargetPosDict) do
        if XScriptTool.EqualVector3(pos, self.StartPos) then
            --XLog.Error("[脚本: "..self._proxy.Id.."]记录寻路目标枚举："..enum)
            self._proxy:SetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathStartStateEnum, enum)
        end
    end
end

---@overload
function XEcologyCharAIFindPathState:OnMoveNext()
    --XLog.Error("[脚本: "..self._proxy.Id.."]记录当前为第"..self._curPathPointIndex.."个路径点", self._curTargetPathPoint)
    self._proxy:SetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathCuePathIndex, self._curPathPointIndex)
end

---@overload
function XEcologyCharAIFindPathState:OnStateEnter(lastStateEnum)
    if self.StateConfig == nil then
        XLog.Error("[脚本: "..self._proxy.Id.."]生态AI没有初始化数据 PlaceId = "..self._placeId)
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
    if self._isMove then
        self._curWaitTime = self._waitTimeLimit
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
        if self.StateConfig.PathBubbleName then
            self._proxy:PlayDramaBubble(ETargetActorType.Npc, self._uuid, self.StateConfig.PathBubbleName)
        end
        self:StopMove()
        self._proxy:EnableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
        self._proxy:TurnNpc(self._uuid,self._proxy:GetLocalPlayerNpcId(),"Drama_Stand_01")
    elseif eventArgs.TriggerState == ETriggerState.Exit then
        if self.StateConfig.PathBubbleName then
            self._proxy:StopDramaBubble(ETargetActorType.Npc, self._uuid)
        end
        self:ContinueMove()
        self._proxy:DisableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
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

--region 拦路等待计时
function XEcologyCharAIFindPathState:UpdateWait(dt)
    if not self._isMove then
        self._curWaitTime = self._curWaitTime - dt
        if self._curWaitTime <= 0 then
            self:ContinueMove()
        end
    end
end
--endregion

return XEcologyCharAIFindPathState