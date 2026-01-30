local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 里生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---生态花园
    Garden = 1,
    ---物流中心
    Port = 2,
    ---智慧游廊
    ArtGallery = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Garden] = {x=474.676971, y=192.719742, z=1013.74915},
    [StateEnum.ArtGallery] = {x=561.2, y=192.8, z=852.7},
    [StateEnum.Port] = {x=486.910004, y=186.542755, z=957.331848},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=512.6,y=193.4,z=1021.4},
        {x=512.4,y=193.5,z=1015.9},
        {x=501.5,y=189.6,z=989.9},
        StatePos[StateEnum.Port]
    },
    [StateEnum.Port] = {
        StatePos[StateEnum.Port],
        {x=531.9,y=188.2,z=933.6},
        {x=552.1,y=190.5,z=916.0},
        StatePos[StateEnum.ArtGallery],
    },
    [StateEnum.ArtGallery] = {
        StatePos[StateEnum.ArtGallery],
        {x=567.3,y=192.1,z=883.9},
        {x=535.1,y=188.8,z=927.1},
        {x=529.3,y=185.9,z=947.3},
        {x=501.5,y=189.6,z=989.9},
        {x=512.4,y=193.5,z=1015.9},
        {x=512.6,y=193.4,z=1021.4},
        {x=502.1,y=193.9,z=1020.3},
        {x=485.2,y=193.6,z=1020.4},
        StatePos[StateEnum.Garden],
    },
}
--endregion


--region 状态-里-生态花园
---@class XLiGardenState: XEcologyCharAIBaseState @里电影院状态
local XLiGardenState = XClass(XEcologyCharAIBaseState, "XLiGardenState")

---数据配置
---@overload
function XLiGardenState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Garden
    self.StateConfig.StateAnim = "Drama_Stand_05"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301204",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
---@overload
---状态进入时
---@param lastStateEnum number 上个状态
function XLiGardenState:OnStateEnter(lastStateEnum)
    self.InteractTriggerCount = 01
    XEcologyCharAIBaseState.OnStateEnter(self, lastStateEnum)
end

---@overload
function XLiGardenState:UpdateOptionActive()
    local optionId = self.StateConfig.ShowOptionId
    if self.InteractTriggerCount == 2 then
        optionId = 5
    end
    if self.InteractTriggerCount >= 3 then
        optionId = 1
    end
    self._proxy:SetNpcInteractOneOptionActive(self._placeId, optionId)
end

function XLiGardenState:OnNpcInteractStart(eventArgs)
    -- 被交互的不是自己不走逻辑
    if eventArgs.TargetId ~= self._uuid then
        return
    end
    self.InteractTriggerCount = self.InteractTriggerCount + 1
    self:UpdateOptionActive()
end
--endregion




--region 状态-里-物流中心
---@class XLiPortState: XEcologyCharAIBaseState @里影院广场状态
local XLiPortState = XClass(XEcologyCharAIBaseState, "XLiPortState")

---数据配置
---@overload
function XLiPortState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.Port
    self.StateConfig.StateAnim = "Drama_Stand_06"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301201",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-里-智慧游廊
---@class XLiArtGalleryState: XEcologyCharAIBaseState @里智慧游廊状态
local XLiArtGalleryState = XClass(XEcologyCharAIBaseState, "XLiArtGalleryState")

---数据配置
---@overload
function XLiArtGalleryState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.ArtGallery
    self.StateConfig.StateAnim = "Drama_Stand_07"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301202",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "301203",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end
--endregion


--region 状态-里-寻路
---@class XLiFindPathState: XEcologyCharAIFindPathState @里寻路状态
local XLiFindPathState = XClass(XEcologyCharAIFindPathState, "XLiFindPathState")

---数据配置
---@overload
function XLiFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }

    self.StateConfig.PathBubbleName = "301205"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 里军备区生态AI
---@class XCharLiEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharLiEcology = XDlcScriptManager.RegCharScript(10607801, "XCharLiEcology", Base)

function XCharLiEcology:InitStateConfigData()
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
function XCharLiEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Garden, XLiGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.Port, XLiPortState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.ArtGallery, XLiArtGalleryState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XLiFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharLiEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.Port, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Port], 1)
    self._stateMachine:AddStateTransition(StateEnum.ArtGallery, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.ArtGallery], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Port, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Port])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.ArtGallery, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.ArtGallery])
end

return XCharLiEcology
--endregion

