local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 万事生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---生态花园
    Garden = 1,
    ---影院
    Cinema = 2,
    ---艺术馆
    ArtGallery = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Garden] = {x=478.959, y=192.72, z=1022.99},
    [StateEnum.Cinema] = {x=569.224, y=194.561, z=979.3866},
    [StateEnum.ArtGallery] = {x=550.533, y=192.3702, z=833.2363},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=472.130005, y=192.72000, z=1025.81995},
        {x=492.206604, y=193.626144, z=1020.25391},
        {x=511.954865, y=193.4375, z=1020.13019},
        StatePos[StateEnum.ArtGallery],
    },
    [StateEnum.ArtGallery] = {
        StatePos[StateEnum.ArtGallery],
        StatePos[StateEnum.Cinema],
    },
    [StateEnum.Cinema] = {
        StatePos[StateEnum.Cinema],
        StatePos[StateEnum.Garden],
    },
}
--endregion


--region 状态-万事-生态花园
---@class XWanshiGardenState: XEcologyCharAIBaseState @万事生态花园状态
local XWanshiGardenState = XClass(XEcologyCharAIBaseState, "XWanshiGardenState")

---数据配置
---@overload
function XWanshiGardenState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Garden
    self.StateConfig.StateAnim = "Drama_Stand_03"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Near] = {
            Name = "500709",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-万事-影院广场
---@class XWanshiCinemaState: XEcologyCharAIBaseState @万事影院状态
local XWanshiCinemaState = XClass(XEcologyCharAIBaseState, "XWanshiCinemaState")

---数据配置
---@overload
function XWanshiCinemaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Cinema
    self.StateConfig.StateAnim = "Drama_Stand_03"
    self.StateConfig.TriggerId = 2
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Near] = {
            Name = "500707",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-万事-艺术馆
---@class XWanshiArtGalleryState: XEcologyCharAIBaseState @万事艺术馆状态
local XWanshiArtGalleryState = XClass(XEcologyCharAIBaseState, "XWanshiArtGalleryState")

---数据配置
---@overload
function XWanshiArtGalleryState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.ArtGallery
    self.StateConfig.StateAnim = "Drama_Stand_03"
    self.StateConfig.TriggerId = 3
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Near] = {
            Name = "500708",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-万事-寻路
---@class XWanshiFindPathState: XEcologyCharAIFindPathState @万事寻路状态
local XWanshiFindPathState = XClass(XEcologyCharAIFindPathState, "XWanshiFindPathState")

---数据配置
---@overload
function XWanshiFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 4
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
    }

    self.StateConfig.PathBubbleName = "500710"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 万事军备区生态AI
---@class XCharWanshiEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharWanshiEcology = XDlcScriptManager.RegCharScript(10127001, "XCharWanshiEcology", Base)

function XCharWanshiEcology:InitStateConfigData()
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
function XCharWanshiEcology:RegisterMachineState()
    XCharWanshiEcology.New(self._proxy)
    self._stateMachine:AddState(StateEnum.Garden, XWanshiGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Cinema, XWanshiCinemaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.ArtGallery, XWanshiArtGalleryState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XWanshiFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharWanshiEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.Cinema, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Cinema], 1)
    self._stateMachine:AddStateTransition(StateEnum.ArtGallery, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.ArtGallery], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Cinema, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Cinema])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.ArtGallery, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.ArtGallery])
end

return XCharWanshiEcology
--endregion

