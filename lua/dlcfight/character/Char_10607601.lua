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
    CinemaPlaza =2,
    ---观景台
    Platform = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    [StateEnum.Garden] = { x = 469.4728, y = 193.5831, z = 1007.583 },
    [StateEnum.CinemaPlaza] = {x=589.64, y=194.09, z=966.59 },
    [StateEnum.Platform] = { x = 536.1525, y = 195.5267, z = 960.2019 },
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        {x=485.3941, y=193.6244, z=1021.004},
        {x=509.7,    y=193.4,    z=1018.2},
        {x=512.4915, y=189.6201, z=1007.088},
        {x=514.0338, y=189.6201, z=1006.527},
        {x=528.831,  y=189.7296, z=1005.151},
        {x=541.97,   y=192.11,   z=1003.13},
        {x=550.5229, y=192.19,   z=1011.98},
        {x=559.3719, y=193.0384, z=1011.054},
        {x=578.3996, y=194.0679, z=1004.22},
        {x=586.37,   y=194.03,   z=994.4137},
        {x=586.7,    y=193.4,    z=980.9},
        {x=586.1,    y=193.9,    z=971.6},
        StatePos[StateEnum.CinemaPlaza],
    },
    [StateEnum.CinemaPlaza] = {
        StatePos[StateEnum.CinemaPlaza],
        { x = 603.7284, y = 194.0976, z = 968.9106 },
        { x = 609.6507, y = 194.0976, z = 968.0659 },
        { x = 609.4893, y = 194.2919, z = 957.5839 },
        { x = 596.8604, y = 194.4947, z = 957.0972 },
        { x = 579.4637,    y = 190.8108,    z = 956.176 },
        { x = 554,    y = 191.1,    z = 959.18 },
        StatePos[StateEnum.Platform],
    },
    [StateEnum.Platform] = {
        StatePos[StateEnum.Platform],
        { x = 553.9694, y = 190.8183, z = 957.01 },
        { x = 566.0119, y = 190.8108, z = 954.9474 },
        { x = 565.8343, y = 188.7449, z = 928.2853 },
        { x = 544.0945, y = 188.7449, z = 927.8363 },
        { x = 539.2832, y = 188.7449, z = 923.47 },
        { x = 529.4707, y = 188.1772, z = 932.8041 },
        { x = 528.0245, y = 185.8784, z = 944.324 },
        { x = 527.0227, y = 185.877,  z = 956.0771 },
        { x = 502.66,   y = 185.82,   z = 957.5862 },
        { x = 501.3246, y = 189.6116, z = 996.9355 },
        { x = 511.32,   y = 189.64,   z = 1005.56 },
        { x = 511.63,   y = 193.5119, z = 1018.91 },
        { x = 484.92,   y = 193.62,   z = 1019.698 },
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
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
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
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 1
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
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

function XBiankaCinemaPlazaState:PlayPerformAnim()
    if self.StateConfig and self.StateConfig.StateAnim then
        self._proxy:PlayNpcCustomPerformAnim(self._uuid, self.StateConfig.StateAnim, 0, 0, false, {x=0,y=0,z=0}, true)
    end
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
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 2
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
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
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }

    self.StateConfig.PathBubbleName = "300902"
    self.StateConfig.PathTargetPosDict = StatePos
end

function XBiankaFindPathState:OnMeetCommander()
    -- 行走中的npc在剧情时不停下
    if not self._isMove or self._proxy:HasRunningDrama() then
        return
    end
    if self.StateConfig.PathBubbleName then
        self._proxy:PlayDramaBubble(ETargetActorType.Npc, self._uuid, self.StateConfig.PathBubbleName)
    end
    self:StopMove()
    self._proxy:EnableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
    self._proxy:TurnNpc(self._uuid,self._proxy:GetLocalPlayerNpcId(),"Drama_Stand_01", true)
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