local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 布偶熊生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---电影院
    Cinema = 1,
    ---交汇广场
    Plaza = 2,
    ---艺术馆
    ArtGallery = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Cinema] = {x=617.938721,y=194.76062,z=1023.96503},
    [StateEnum.Plaza] = {x=581.5,y=190.5,z=912.6},
    [StateEnum.ArtGallery] = {x=583.260864,y=192.370224,z=848.190308},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Cinema] = {
        StatePos[StateEnum.Cinema],
        {x=618.2,y=194.8,z=1026.1},
        {x=588.9,y=194.1,z=1010.9},
        {x=589.2,y=194.1,z=999.8},
        {x=559.9,y=193.0,z=993.8},
        {x=559.9,y=193.0,z=993.8},
        {x=562.7,y=190.8,z=961.6},
        {x=568.0,y=188.7,z=925.4},
        {x=573.9,y=190.5,z=911.8},
        StatePos[StateEnum.Plaza],
    },
    [StateEnum.Plaza] = {
        StatePos[StateEnum.Plaza],
        StatePos[StateEnum.ArtGallery],
    },
    [StateEnum.ArtGallery] = {
        StatePos[StateEnum.ArtGallery],
        {x=582.3,y=192.4,z=851.7},
        {x=580.8,y=192.4,z=856.4},
        {x=592.4,y=192.4,z=854.7},
        {x=599.9,y=192.0,z=842.7},
        {x=600.9,y=191.9,z=869.7},
        {x=599.0,y=188.7,z=890.3},
        {x=596.0,y=188.7,z=911.5},
        {x=606.3,y=190.0,z=915.1},
        {x=610.2,y=194.1,z=966.7},
        {x=584.2,y=194.1,z=969.3},
        {x=584.9,y=194.1,z=997.0},
        {x=589.6,y=194.1,z=1013.1},
        {x=602.6,y=194.4,z=1024.7},
        {x=618.2,y=194.8,z=1026.1},
        StatePos[StateEnum.Cinema],
    },
}
--endregion


--region 状态-布偶熊-电影院
---@class XBuouxiongCinemaState: XEcologyCharAIBaseState @布偶熊电影院状态
local XBuouxiongCinemaState = XClass(XEcologyCharAIBaseState, "XBuouxiongCinemaState")

---数据配置
---@overload
function XBuouxiongCinemaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Cinema
    self.StateConfig.StateLoopAnim = "Drama_Watching_Loop"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.IgnoreCharCollider = true
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
end

---@overload
---状态进入时
---@param lastStateEnum number 上个状态
function XBuouxiongCinemaState:OnStateEnter(lastStateEnum)
    self.InteractTriggerCount = 1
    self._proxy:SetNpcPosition(self._uuid, StatePos[StateEnum.Cinema])
    XEcologyCharAIBaseState.OnStateEnter(self, lastStateEnum)
end

---@overload
function XBuouxiongCinemaState:UpdateOptionActive()
    local optionId = self.StateConfig.ShowOptionId
    if self.InteractTriggerCount == 2 then
        optionId = 5
    end
    if self.InteractTriggerCount >= 3 then
        optionId = 1
    end
    self._proxy:SetNpcInteractOneOptionActive(self._placeId, optionId)
end

function XBuouxiongCinemaState:OnNpcInteractStart(eventArgs)
    -- 被交互的不是自己不走逻辑
    if eventArgs.TargetId ~= self._uuid then
        return
    end
    self.InteractTriggerCount = self.InteractTriggerCount + 1
    self:UpdateOptionActive()
    self:PlayPerformLoopAnim()
end

function XBuouxiongCinemaState:PlayPerformAnim()
    local CinemaSitTurnPos={x=617.937012,y=194.8526,z=1027.47412}
    self._proxy:TurnPos(self._uuid,CinemaSitTurnPos,"Drama_Watching")
end
--endregion


--region 状态-布偶熊-影院广场
---@class XBuouxiongPlazaState: XEcologyCharAIBaseState @布偶熊影院广场状态
local XBuouxiongPlazaState = XClass(XEcologyCharAIBaseState, "XBuouxiongPlazaState")

---数据配置
---@overload
function XBuouxiongPlazaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Plaza
    self.StateConfig.StateLoopAnim = "Drama_Watching_Loop"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.IgnoreCharCollider = true
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
end

---@overload
---状态进入时
---@param lastStateEnum number 上个状态
function XBuouxiongPlazaState:OnStateEnter(lastStateEnum)
    self._proxy:SetNpcPosition(self._uuid, StatePos[StateEnum.Plaza])
    XEcologyCharAIBaseState.OnStateEnter(self, lastStateEnum)
end

function XBuouxiongPlazaState:PlayPerformAnim()
    local PlazaSitTurnPos={x=579.891968,y=190.512939,z=912.443176}
    self._proxy:TurnPos(self._uuid,PlazaSitTurnPos,"Drama_Watching")
end
--endregion


--region 状态-布偶熊-艺术馆
---@class XBuouxiongArtGalleryState: XEcologyCharAIBaseState @布偶熊艺术馆状态
local XBuouxiongArtGalleryState = XClass(XEcologyCharAIBaseState, "XBuouxiongArtGalleryState")

---数据配置
---@overload
function XBuouxiongArtGalleryState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.ArtGallery
    self.StateConfig.StateAnim = "Drama_Stand_05"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300701",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-布偶熊-寻路
---@class XBuouxiongFindPathState: XEcologyCharAIFindPathState @布偶熊寻路状态
local XBuouxiongFindPathState = XClass(XEcologyCharAIFindPathState, "XBuouxiongFindPathState")

---数据配置
---@overload
function XBuouxiongFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    
    self.StateConfig.PathBubbleName = "300702"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 布偶熊军备区生态AI
---@class XCharBuouxiongEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharBuouxiongEcology = XDlcScriptManager.RegCharScript(10609401, "XCharBuouxiongEcology", Base)


function XCharBuouxiongEcology:TryInitAIEnterState()
    self._proxy:SetActorIgnoreCollision(self._uuid, self._proxy:GetSceneObjectUUID(1600019), true)
    self._proxy:SetActorIgnoreCollision(self._uuid, self._proxy:GetSceneObjectUUID(1600020), true)
    self._proxy:SetActorIgnoreCollision(self._uuid, self._proxy:GetSceneObjectUUID(1600002), true)
    Base.TryInitAIEnterState(self)
end

function XCharBuouxiongEcology:InitStateConfigData()
    ---状态点坐标, 
    self.StateTargetPosDict = StatePos
    ---寻路状态枚举
    self.FindPathStateEnum = StateEnum.FindPath
    ---寻路路径字典, Key=状态枚举, Value=路径点数组
    self.FindPathDict = StatePath
    ---寻路状态下一个状态的默认枚举
    self.FindPathDefaultTargetEnum = StateEnum.Cinema
end

--- 注册状态机状态
function XCharBuouxiongEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Cinema, XBuouxiongCinemaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Plaza, XBuouxiongPlazaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.ArtGallery, XBuouxiongArtGalleryState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XBuouxiongFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharBuouxiongEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Cinema, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Cinema], 1)
    self._stateMachine:AddStateTransition(StateEnum.Plaza, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Plaza], 1)
    self._stateMachine:AddStateTransition(StateEnum.ArtGallery, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.ArtGallery], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Cinema, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Cinema], 0.1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Plaza, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Plaza], 0.5)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.ArtGallery, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.ArtGallery], 0.5)
end

return XCharBuouxiongEcology
--endregion