local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 阿西莫夫生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---物流中心瞭望台
    Port = 1,
    ---电影院
    Cinema = 2,
    ---生态花园
    Garden = 3,
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Port] = {x=556.6, y=190.8, z=957.5},
    [StateEnum.Cinema] = {x=599.0862,y=194.2651, z=984.3744},
    [StateEnum.Garden] = {x=499.9398, y=189.6071, z=1004.228},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Port] = {
        StatePos[StateEnum.Port],
        {x=560.2,y=191.4,z=971.1},
        {x=541.3,y=192.2,z=992.7},
        {x=600.3,y=194.1,z=993.5},
        StatePos[StateEnum.Cinema],
    },
    [StateEnum.Cinema] = {
        StatePos[StateEnum.Cinema],
        {x=600.3,y=194.1,z=993.5},
        {x=541.3,y=192.2,z=992.7},
        StatePos[StateEnum.Garden],
    },
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=502.4,y=185.9,z=957.4},
        {x=529.9,y=188.2,z=932.8},
        {x=567.0,y=188.7,z=934.4},
        StatePos[StateEnum.Port],
    },
}
--endregion


--region 状态-阿西莫夫-电影院
---@class XAximovCinemaState: XEcologyCharAIBaseState @阿西莫夫电影院状态
local XAximovCinemaState = XClass(XEcologyCharAIBaseState, "XAximovCinemaState")

---数据配置
---@overload
function XAximovCinemaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Cinema
    self.StateConfig.StateAnim = "Drama_Stand_05"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301301",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "301302",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-阿西莫夫-物流中心
---@class XAximovPortState: XEcologyCharAIBaseState @阿西莫夫影院广场状态
local XAximovPortState = XClass(XEcologyCharAIBaseState, "XAximovPortState")

---数据配置
---@overload
function XAximovPortState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Port
    self.StateConfig.StateAnim = "Drama_LookHand"
    self.StateConfig.TriggerId = 2
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301303",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-阿西莫夫-生态花园
---@class XAximovGardenState: XEcologyCharAIBaseState @阿西莫夫生态花园状态
local XAximovGardenState = XClass(XEcologyCharAIBaseState, "XAximovGardenState")

---数据配置
---@overload
function XAximovGardenState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Garden
    self.StateConfig.StateAnim = "Drama_Stand_10"
    self.StateConfig.TriggerId = 3
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301305",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-阿西莫夫-寻路
---@class XAximovFindPathState: XEcologyCharAIFindPathState @阿西莫夫寻路状态
local XAximovFindPathState = XClass(XEcologyCharAIFindPathState, "XAximovFindPathState")

---数据配置
---@overload
function XAximovFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 4
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }

    self.StateConfig.PathBubbleName = "301304"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 阿西莫夫军备区生态AI
---@class XCharAximovEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharAximovEcology = XDlcScriptManager.RegCharScript(10609701, "XCharAximovEcology", Base)

function XCharAximovEcology:InitStateConfigData()
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
function XCharAximovEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Port, XAximovPortState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Cinema, XAximovCinemaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Garden, XAximovGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XAximovFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharAximovEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Port, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Port], 1)
    self._stateMachine:AddStateTransition(StateEnum.Cinema, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Cinema], 1)
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Port, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Port])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Cinema, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Cinema])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
end

return XCharAximovEcology
--endregion


