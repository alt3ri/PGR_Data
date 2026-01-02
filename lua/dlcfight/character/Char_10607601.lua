local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 比安卡生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---生态花园
    Garden = 1,
    ---影院广场
    CinemaPlaza = 2,
    ---观景台
    Platform = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Garden] = { x = 469.85, y = 193.641, z = 1008.197 },
    [StateEnum.CinemaPlaza] = { x = 589.64, y = 194.09, z = 966.59 },
    [StateEnum.Platform] = { x = 532.91, y = 195.54, z = 954.77 },
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],

        StatePos[StateEnum.CinemaPlaza],
    },
    [StateEnum.CinemaPlaza] = {
        StatePos[StateEnum.CinemaPlaza],

        StatePos[StateEnum.Platform],
    },
    [StateEnum.Platform] = {
        StatePos[StateEnum.Platform],
 
        StatePos[StateEnum.Garden],
    },
}
--endregion


--region 状态-比安卡-生态花园
---@class XBiankaGardenState: XEcologyCharAIBaseState @比安卡生态花园状态
local XBiankaGardenState = XClass(XEcologyCharAIBaseState, "XBiankaGardenState")

---数据配置
---@overload
function XBiankaGardenState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Garden
    self.StateConfig.StateAnim = "Drama_Stand_02"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300904",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-比安卡-影院广场
---@class XBiankaCinemaPlazaState: XEcologyCharAIBaseState @比安卡影院广场状态
local XBiankaCinemaPlazaState = XClass(XEcologyCharAIBaseState, "XBiankaCinemaPlazaState")

---数据配置
---@overload
function XBiankaCinemaPlazaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.CinemaPlaza
    self.StateConfig.StateAnim = "Drama_Stand_01"
    self.StateConfig.TriggerId = 2
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300901",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "300905",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-比安卡-观景台
---@class XBiankaPlatformState: XEcologyCharAIBaseState @比安卡观景台状态
local XBiankaPlatformState = XClass(XEcologyCharAIBaseState, "XBiankaPlatformState")

---数据配置
---@overload
function XBiankaPlatformState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Platform
    self.StateConfig.StateAnim = "Drama_Stand_03"
    self.StateConfig.TriggerId = 3
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300903",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-比安卡-寻路
---@class XBiankaFindPathState: XEcologyCharAIFindPathState @比安卡寻路状态
local XBiankaFindPathState = XClass(XEcologyCharAIFindPathState, "XBiankaFindPathState")

---数据配置
---@overload
function XBiankaFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 4
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }

    self.StateConfig.PathBubbleName = "300902"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 比安卡军备区生态AI
---@class XCharBiankaEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharBiankaEcology = XDlcScriptManager.RegCharScript(10607601, "XCharBiankaEcology", Base)

function XCharBiankaEcology:InitStateConfigData()
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
function XCharBiankaEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Garden, XBiankaGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.CinemaPlaza, XBiankaCinemaPlazaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Platform, XBiankaPlatformState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XBiankaFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharBiankaEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.CinemaPlaza, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.CinemaPlaza], 1)
    self._stateMachine:AddStateTransition(StateEnum.Platform, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Platform], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.CinemaPlaza, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.CinemaPlaza])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Platform, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Platform])
end

return XCharBiankaEcology
--endregion