local XLevelNpcState = require("Common/StateMachine/State/XLevelNpcState")

---@class XEcologyCharAIStateConfig
---@field StateEnum number 状态枚举
---@field StateAnim string 该状态的演出动画
---@field ShowOptionId number 该状态显示的交互参数
---@field TriggerId number 触发器Id, 用以气泡和靠近等
---@field RegisterWorldEventList table<string> 该状态监听的事件
---@field BubbleDict table<number, XAiBubbleInfo> 气泡配置字典, key = EEcologyBubbleType, value = 气泡配置
---@field PathBubbleName string 寻路气泡
---@field PathTargetPosDict table<number, Vector3> 寻路目标点字典, Key = 状态枚举, value = 坐标

---@class XEcologyCharAIBaseState: XLevelNpcState @生态状态基类
---@field StateConfig XEcologyCharAIStateConfig
local XEcologyCharAIBaseState = XClass(XLevelNpcState, "XEcologyCharAIBaseState")

---@overload
---状态进入时
---@param lastStateEnum number 上个状态
function XEcologyCharAIBaseState:OnStateEnter(lastStateEnum)
    if self.StateConfig == nil then
        XLog.Error("[脚本: "..self._proxy.Id.."]生态AI没有初始化数据 PlaceId = "..self._placeId)
        return
    end
    self.StateEnum = self.StateConfig.StateEnum
    self._proxy:SetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.CurStateEnum, self.StateConfig.StateEnum)
    self:RegisterWorldEvent()
    self:InitAiBubble()
    self:UpdateOptionActive()
    self:PlayPerformAnim()
end

---@overload
---状态进入时
---@param nextStateEnum number 下个状态
function XEcologyCharAIBaseState:OnStateLeave(nextStateEnum)
    self:UnRegisterWorldEvent()
end

---@overload
---状态进行时（每帧更新)
function XEcologyCharAIBaseState:OnStateUpdate(dt)
    if self.StateConfig == nil then
        return
    end
    self:UpdateAiBubble(dt)
end

---@overload
---额外事件监听
---@param eventType number EWorldEvent
---@param eventArgs table 对应时间参数
function XEcologyCharAIBaseState:HandleEvent(eventType, eventArgs)
    if self.StateConfig == nil then
        return
    end
    if eventType == EWorldEvent.ActorTrigger then
        self:OnActorTrigger(eventArgs)
    elseif eventType == EWorldEvent.NpcInteractStart then
        self:OnNpcInteractStart(eventArgs)
    end
end

--region 初始化
---状态配置初始化
---@overload
function XEcologyCharAIBaseState:InitStateConfig()
    self.StateConfig = nil
end
--endregion

--region 交互
function XEcologyCharAIBaseState:UpdateOptionActive()
    self._proxy:SetNpcInteractOneOptionActive(self._placeId, self.StateConfig.ShowOptionId)
end
--endregion

--region WorldEvent监听及处理
---@private
function XEcologyCharAIBaseState:RegisterWorldEvent()
    for _, event in pairs(self.StateConfig.RegisterWorldEventList) do
        self._proxy:RegisterEvent(event)
    end
end

---@private
function XEcologyCharAIBaseState:UnRegisterWorldEvent()
    for _, event in pairs(self.StateConfig.RegisterWorldEventList) do
        self._proxy:UnregisterEvent(event)
    end
end

function XEcologyCharAIBaseState:OnActorTrigger(eventArgs)
    -- 不是玩家触发且定义触发的TriggerId不执行逻辑
    if eventArgs.TriggerId ~= self.StateConfig.TriggerId
            or self._uuid ~= eventArgs.TriggerHolderUUID
            or not self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID)
    then
        return
    end
    if eventArgs.TriggerState == ETriggerState.Enter then
        self._proxy:StopNpcPerformAnim(self._uuid)
        self._proxy:EnableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
    elseif eventArgs.TriggerState == ETriggerState.Exit then
        self:PlayPerformAnim()
        self._proxy:DisableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
    end
end

function XEcologyCharAIBaseState:OnNpcInteractStart(eventArgs)
    -- 被交互的不是自己不走逻辑
    if eventArgs.TargetId ~= self._uuid then
        return
    end
end
--endregion

--region Anim 演出动画
function XEcologyCharAIBaseState:PlayPerformAnim()
    if self.StateConfig and self.StateConfig.StateAnim then
        self._proxy:PlayNpcCustomPerformAnim(self._uuid, self.StateConfig.StateAnim, 0, 0)
    end
end
--endregion

--region 气泡管理器
---@class XAiBubbleInfo 气泡对象
---@field Name string 气泡Id
---@field Type number 气泡类型 EEcologyBubbleType
---@field State number 气泡状态 EEcologyBubbleState
---@field TriggerDistance number 气泡触发的距离
---@field TriggerCD number 气泡的内置CD
---@field LoopTime number 气泡的循环时间
---@field CurTime number 气泡计时

---@private
function XEcologyCharAIBaseState:InitAiBubble()
    ---@type table<number, XAiBubbleInfo>
    self._bubbleDict = {}
    ---@type number
    self._curPlayBubbleType = EEcologyBubbleType.None
    if not self.StateConfig.BubbleDict then
        return
    end
    for bubbleType, data in pairs(self.StateConfig.BubbleDict) do
        self:RegisterAiBubbleInfo(data.Name, bubbleType, data.TriggerDistance, data.TriggerCD, data.LoopTime)
    end
end

---@private
---@return XAiBubbleInfo
function XEcologyCharAIBaseState:RegisterAiBubbleInfo(bubbleName, bubbleType, TriggerDistance, TriggerCD, LoopTime)
    ---@type XAiBubbleInfo
    local info = self:CreateAiBubbleInfo(bubbleName, bubbleType, TriggerDistance,TriggerCD,LoopTime)
    if info then
        self._bubbleDict[bubbleType] = info
    end
end

---@private
---@return XAiBubbleInfo
function XEcologyCharAIBaseState:CreateAiBubbleInfo(bubbleName, bubbleType, TriggerDistance, TriggerCD, LoopTime)
    ---@type XAiBubbleInfo
    local info = {}

    info.Name = bubbleName
    info.Type = bubbleType
    info.State = EEcologyBubbleState.None
    info.TriggerDistance = TriggerDistance
    info.TriggerCD = TriggerCD
    info.LoopTime = LoopTime
    info.CurTime = 0

    return info
end

function XEcologyCharAIBaseState:UpdateAiBubble(dt)
    local playerDistance = self:GetWithPlayerDistance()
    local distance = 0
    local triggerBubbleType = EEcologyBubbleType.None
    local curBubbleInfo = self._bubbleDict[self._curPlayBubbleType]
    
    for bubbleType, bubbleInfo in pairs(self._bubbleDict) do
        if bubbleInfo.TriggerDistance > playerDistance then
            if distance == 0 or distance < bubbleInfo.TriggerDistance then
                distance = bubbleInfo.TriggerDistance
                triggerBubbleType = bubbleType
            end
        end
    end
    -- 离开范围之后气泡照常播放不计入CD
    if triggerBubbleType == EEcologyBubbleType.None and 
            self._curPlayBubbleType ~= EEcologyBubbleType.None and
            curBubbleInfo ~= nil and
            curBubbleInfo.State == EEcologyBubbleState.Playing
    then
        self:RefreshAiBubble(self._curPlayBubbleType, dt)
    else
        self:SetCurBubbleType(triggerBubbleType)
        self:RefreshAiBubble(self._curPlayBubbleType, dt)
    end
end

---@private
---@param bubbleType number
function XEcologyCharAIBaseState:RefreshAiBubble(bubbleType, dt)
    if bubbleType == EEcologyBubbleType.None then
        return
    end
    local aiBubbleInfo = self._bubbleDict[bubbleType]
    if not aiBubbleInfo or not aiBubbleInfo.Name then
        return
    end
    aiBubbleInfo.CurTime = aiBubbleInfo.CurTime + dt
    if aiBubbleInfo.State == EEcologyBubbleState.Playing then
        if aiBubbleInfo.CurTime >= aiBubbleInfo.LoopTime then
            self._proxy:StopDramaBubble(ETargetActorType.Npc, self._uuid)
            aiBubbleInfo.State = EEcologyBubbleState.CD
            aiBubbleInfo.CurTime = 0
        end
    elseif aiBubbleInfo.State == EEcologyBubbleState.CD then
        if aiBubbleInfo.CurTime >= aiBubbleInfo.TriggerCD then
            self._proxy:PlayDramaBubble(ETargetActorType.Npc, self._uuid, aiBubbleInfo.Name)
            aiBubbleInfo.State = EEcologyBubbleState.Playing
            aiBubbleInfo.CurTime = 0
        end
    end
end

---@private
function XEcologyCharAIBaseState:SetCurBubbleType(bubbleType)
    self._curPlayBubbleType = bubbleType
    local aiBubbleInfo = self._bubbleDict[bubbleType]
    if not aiBubbleInfo then
        return
    end
    if aiBubbleInfo.State == EEcologyBubbleState.None then
        aiBubbleInfo.State = EEcologyBubbleState.CD
        aiBubbleInfo.CurTime = aiBubbleInfo.TriggerCD
    end
end

---@private
function XEcologyCharAIBaseState:GetWithPlayerDistance()
    return self._proxy:CalcNpcDistance(self._uuid, self._proxy:GetLocalPlayerNpcId())
end
--endregion

return XEcologyCharAIBaseState