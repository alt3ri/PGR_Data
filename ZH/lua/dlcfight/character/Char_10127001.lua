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
    [StateEnum.Garden] = {x=474.6948, y=192.72, z=1025.204},
    [StateEnum.Cinema] = {x=597.2913, y=194.2651, z=986.6304},
    [StateEnum.ArtGallery] = {x=552.583, y=192.356, z=832.691},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=472.2758, y=192.72000, z=1022.91},
        {x=513.3771, y=193.4375, z=1021.204},
        {x=543.3136, y=192.1723, z=1002.054},
        {x=560.6064, y=193.0575, z=994.9433},
        {x=579.475, y=194.0679, z=1002.077},
        {x=602.694, y=194.0679, z=996.8626},
        StatePos[StateEnum.Cinema],
    },
    [StateEnum.Cinema] = {
        StatePos[StateEnum.Cinema],
        {x=597.2913, y=194.2651, z=986.6304},
        {x=602.0005, y=194.2651, z=986.5113},
        {x=601.3565, y=194.0679, z=996.7715},
        {x=565.9553, y=193.0384, z=995.5836},
        StatePos[StateEnum.ArtGallery],
    },
    [StateEnum.ArtGallery] = {
        StatePos[StateEnum.ArtGallery],
        {x=552.384, y=192.3565, z=832.691},
        {x=561.3833, y=192.7738, z=834.9805},
        {x=566.9894, y=192.1259, z=866.3001},
        {x=512.0649, y=193.4374, z=1019.652},
        {x=506.185, y=193.4375, z=1020.709},
        {x=490.7641, y=193.6258, z=1019.966},
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
    self.StateConfig.StateAnim = "Drama_BoardAct1001"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Near] = {
            Name = "500707",
            TriggerDistance = 6,
            TriggerCD = 5,
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
    self.StateConfig.StateAnim = "Drama_Stand_05"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Near] = {
            Name = "500708",
            TriggerDistance = 6,
            TriggerCD = 5,
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
    self.StateConfig.StateAnim = "Drama_Stand_05"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Near] = {
            Name = "500709",
            TriggerDistance = 6,
            TriggerCD = 5,
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
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
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

