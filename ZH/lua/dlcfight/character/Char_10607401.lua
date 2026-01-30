local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 薇拉生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    Cinema = 1,    ---电影院
    Garden = 2,    ---生态花园
    Port = 3,      ---货运中心
    FindPath = 4,  ---寻路过程
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Cinema] = {x=581.2296, y=194.0679, z=1007.925},
    [StateEnum.Garden] = {x=469.0241, y=193.5831, z=1034.533},
    [StateEnum.Port] = {x=529.2028, y=185.877, z=957.3785},
}

---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Cinema] = {
        StatePos[StateEnum.Cinema],
        {x=512.2364, y=193.4375, z=1020.978},
        StatePos[StateEnum.Garden],
    },
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=512.2364, y=193.4375, z=1020.978},
        StatePos[StateEnum.Port],
    },
    [StateEnum.Port] = {
        StatePos[StateEnum.Port],
        StatePos[StateEnum.Cinema],
    },
}
--endregion


--region 状态-薇拉-电影院
---@class XVeraCinemaState: XEcologyCharAIBaseState @薇拉电影院状态
local XVeraCinemaState = XClass(XEcologyCharAIBaseState, "XVeraCinemaState")

---数据配置
---@overload
function XVeraCinemaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Cinema
    self.StateConfig.StateAnim = "Drama_BoardAct1002"
    self.StateConfig.StateLoopAnim = "Drama_BoardAct1002_Loop"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "1216",
            TriggerDistance = 6,
            TriggerCD = 3,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "1217",
            TriggerDistance = 2.5,
            TriggerCD = 5,
            LoopTime = 6,
        }
    }
end
--endregion


--region 状态-薇拉-生态花园
---@class XVeraGardenState: XEcologyCharAIBaseState @薇拉生态花园状态
local XVeraGardenState = XClass(XEcologyCharAIBaseState, "XVeraGardenState")

---数据配置
---@overload
function XVeraGardenState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Garden
    self.StateConfig.StateAnim = "Drama_SitUpright"
    self.StateConfig.StateLoopAnim = "Drama_SitUpright_Loop"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.IgnoreCharCollider = true
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "1218",
            TriggerDistance = 6,
            TriggerCD = 3,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "1219",
            TriggerDistance = 2.5,
            TriggerCD = 5,
            LoopTime = 3,
        }
    }
end

---@overload
---状态进入时
---@param lastStateEnum number 上个状态
function XVeraGardenState:OnStateEnter(lastStateEnum)
    self._proxy:SetNpcPosition(self._uuid, StatePos[StateEnum.Garden])
    XEcologyCharAIBaseState.OnStateEnter(self, lastStateEnum)
end

function XVeraGardenState:PlayPerformAnim()
    local GardenSitRot = {x=467.673248,y=193.583115,z=1032.74292}
    self._proxy:TurnPos(self._uuid, GardenSitRot, self.StateConfig.StateAnim)
end
--endregion


--region 状态-薇拉-货运中心
---@class XVeraPortState: XEcologyCharAIBaseState @薇拉货运中心状态
local XVeraPortState = XClass(XEcologyCharAIBaseState, "XVeraPortState")

---数据配置
---@overload
function XVeraPortState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Port
    self.StateConfig.StateAnim = "Drama_BoardAct0203"
    self.StateConfig.StateLoopAnim = "Drama_BoardAct0203_Loop"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "1220",
            TriggerDistance = 6,
            TriggerCD = 3,
            LoopTime = 4,
        },
    }
end

function XVeraPortState:PlayPerformAnim()
    local GardenSitRot = {x=467.673248,y=193.583115,z=1032.74292}
    self._proxy:TurnPos(self._uuid, GardenSitRot, self.StateConfig.StateAnim,true)
end
--endregion


--region 状态-薇拉-寻路
---@class XVeraFindPathState: XEcologyCharAIFindPathState @薇拉寻路状态
local XVeraFindPathState = XClass(XEcologyCharAIFindPathState, "XVeraFindPathState")

---数据配置
---@overload
function XVeraFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }

    self.StateConfig.PathBubbleName = "1221"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 薇拉军备区生态AI
---@class XCharVeraEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharVeraEcology = XDlcScriptManager.RegCharScript(10607401, "XCharVeraEcology", Base)

function XCharVeraEcology:TryInitAIEnterState()
    self._proxy:SetActorIgnoreCollision(self._uuid, self._proxy:GetSceneObjectUUID(1100080), true)
    Base.TryInitAIEnterState(self)
end

function XCharVeraEcology:InitStateConfigData()
    ---状态点坐标, 
    self.StateTargetPosDict = StatePos
    ---寻路状态枚举
    self.FindPathStateEnum = StateEnum.FindPath
    ---寻路路径字典, Key=状态枚举, Value=路径点数组
    self.FindPathDict = StatePath
    ---寻路状态下一个状态的默认枚举
    self.FindPathDefaultTargetEnum = StateEnum.Garden
end

--- 注册状态机状态
function XCharVeraEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Cinema, XVeraCinemaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Garden, XVeraGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Port, XVeraPortState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XVeraFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharVeraEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Cinema, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Cinema], 1)
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.Port, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30,  StatePath[StateEnum.Port], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Cinema, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Cinema])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Port, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Port])
end

return XCharVeraEcology
--endregion

