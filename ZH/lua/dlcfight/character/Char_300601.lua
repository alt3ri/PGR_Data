local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 露西亚生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---生态花园
    Garden = 1,
    ---影院广场
    CinemaPlaza = 2,
    ---艺术馆
    ArtGallery = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Garden] = {x=467.1739, y=193.6555, z=1031.173},
    [StateEnum.CinemaPlaza] = {x=527.1191, y=195.5426, z=957.161},
    [StateEnum.ArtGallery] = {x=535.700989, y=191.985992, z=825.593018},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=472.130005, y=192.72000, z=1025.81995},
        {x=492.206604, y=193.626144, z=1020.25391},
        {x=511.954865, y=193.4375, z=1020.13019},
        {x=541.7, y=192.2, z=1001.3},
        StatePos[StateEnum.CinemaPlaza],
    },
    [StateEnum.CinemaPlaza] = {
        StatePos[StateEnum.CinemaPlaza],
        {x=562.499634, y=188.745941, z=919.598877},
        {x=567.570496, y=192.475922, z=876.669983},
        {x=548.682007, y=192.370224, z=822.999023},
        {x=537.913574, y=192.004593, z=845.563599},
        StatePos[StateEnum.ArtGallery],
    },
    [StateEnum.ArtGallery] = {
        StatePos[StateEnum.ArtGallery],
        {x=568.5, y=192.8, z=857.1},
        {x=543.234375, y=192.370224, z=856.400269},
        {x=527.933533, y=190.821762, z=875.113525},
        {x=539.505127, y=188.745941, z=923.377991},
        {x=501.643066, y=189.172089, z=972.858032},
        {x=511.954865, y=193.4375, z=1020.13019},
        {x=492.206604, y=193.626144, z=1020.25391},
        {x=472.130005, y=192.72000, z=1025.81995},
        StatePos[StateEnum.Garden],
    },
}
--endregion


--region 状态-露西亚-生态花园
---@class XLuxiyaGardenState: XEcologyCharAIBaseState @露西亚生态花园状态
local XLuxiyaGardenState = XClass(XEcologyCharAIBaseState, "XLuxiyaGardenState")

---数据配置
---@overload
function XLuxiyaGardenState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Garden
    self.StateConfig.StateAnim = "Drama_Stand_05"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300604",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-露西亚-影院广场
---@class XLuxiyaCinemaPlazaState: XEcologyCharAIBaseState @露西亚影院广场状态
local XLuxiyaCinemaPlazaState = XClass(XEcologyCharAIBaseState, "XLuxiyaCinemaPlazaState")

---数据配置
---@overload
function XLuxiyaCinemaPlazaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.CinemaPlaza
    self.StateConfig.StateAnim = "Drama_Stand_06"
    self.StateConfig.TriggerId = 2
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300605",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "300601",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-露西亚-艺术馆
---@class XLuxiyaArtGalleryState: XEcologyCharAIBaseState @露西亚艺术馆状态
local XLuxiyaArtGalleryState = XClass(XEcologyCharAIBaseState, "XLuxiyaArtGalleryState")

---数据配置
---@overload
function XLuxiyaArtGalleryState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.ArtGallery
    self.StateConfig.StateAnim = "Drama_Stand_07"
    self.StateConfig.TriggerId = 3
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "300606",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "300602",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-露西亚-寻路
---@class XLuxiyaFindPathState: XEcologyCharAIFindPathState @露西亚寻路状态
local XLuxiyaFindPathState = XClass(XEcologyCharAIFindPathState, "XLuxiyaFindPathState")

---数据配置
---@overload
function XLuxiyaFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 4
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }

    self.StateConfig.PathBubbleName = "300603"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 露西亚军备区生态AI
---@class XCharLuxiyaEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharLuxiyaEcology = XDlcScriptManager.RegCharScript(300601, "XCharLuxiyaEcology", Base)

function XCharLuxiyaEcology:InitStateConfigData()
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
function XCharLuxiyaEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Garden, XLuxiyaGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.CinemaPlaza, XLuxiyaCinemaPlazaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.ArtGallery, XLuxiyaArtGalleryState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XLuxiyaFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharLuxiyaEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.CinemaPlaza, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.CinemaPlaza], 1)
    self._stateMachine:AddStateTransition(StateEnum.ArtGallery, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.ArtGallery], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.CinemaPlaza, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.CinemaPlaza])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.ArtGallery, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.ArtGallery])
end

return XCharLuxiyaEcology
--endregion
