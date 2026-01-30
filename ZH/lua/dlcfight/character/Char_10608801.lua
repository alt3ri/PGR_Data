local Base = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBase")
local XEcologyCharAIBaseState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIBaseState")
local XEcologyCharAIFindPathState = require("Character/BigWorld/XEcologyCharAI/XEcologyCharAIFindPathState")
local XOther2FindPathTransition = require("Common/StateMachine/Transition/XOther2FindPathTransition")
local XFindPath2OtherTransition = require("Common/StateMachine/Transition/XFindPath2OtherTransition")

--region 罗塞塔生态1.5期静态参数
---生态状态枚举
local StateEnum = {
    None = 0,
    ---生态花园
    Garden = 1,
    ---交汇广场
    CrossPlaza = 2,
    ---艺术馆
    ArtGallery = 3,
    ---寻路过程
    FindPath = 4,
}
---生态状态坐标
---@type table<number, Vector3>
local StatePos = {
    --停留在生态花园的坐标
    [StateEnum.Garden] = {x=509.861, y=193.462, z=1022.992},
    --停留在交汇广场的坐标
    [StateEnum.CrossPlaza] = { x=569.352, y=188.7459, z=921.834},
    --停留在艺术馆的坐标
    [StateEnum.ArtGallery] = {x=567.7385, y=192.77, z=841.597},
}
---寻路路径
---@type table<number, Vector3>
local StatePath = {
    [StateEnum.Garden] = {
        StatePos[StateEnum.Garden],
        StatePos[StateEnum.CrossPlaza],
    },
    [StateEnum.CrossPlaza] = {
        StatePos[StateEnum.CrossPlaza],
        StatePos[StateEnum.ArtGallery],
    },
    [StateEnum.ArtGallery] = {
        StatePos[StateEnum.ArtGallery],
        StatePos[StateEnum.Garden],
    },
}
--endregion


--region 状态-罗塞塔-生态花园
---@class XLuosaitaGardenState: XEcologyCharAIBaseState @罗塞塔生态花园状态
local XLuosaitaGardenState = XClass(XEcologyCharAIBaseState, "XLuosaitaGardenState")

---数据配置
---@overload
function XLuosaitaGardenState:InitStateConfig()
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
            Name = "301001",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "301002",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end

---@overload
---状态进入时
---@param lastStateEnum number 上个状态
function XLuosaitaGardenState:OnStateEnter(lastStateEnum)
    self.InteractTriggerCount = 0
    XEcologyCharAIBaseState.OnStateEnter(self, lastStateEnum)
end

---@overload
function XLuosaitaGardenState:UpdateOptionActive()
    local optionId = self.StateConfig.ShowOptionId
    if self.InteractTriggerCount == 1 then
        optionId = 2
    end
    self._proxy:SetNpcInteractOneOptionActive(self._placeId, optionId)
end

function XLuosaitaGardenState:OnNpcInteractStart(eventArgs)
    -- 被交互的不是自己不走逻辑
    if eventArgs.TargetId ~= self._uuid then
        return
    end
    self:PlayPerformAnim()
    self.InteractTriggerCount = self.InteractTriggerCount + 1
    self:UpdateOptionActive()

end
--endregion


--region 状态-罗塞塔-交汇广场
---@class XLuosaitaCrossPlazaState: XEcologyCharAIBaseState @罗塞塔交汇广场状态
local XLuosaitaCrossPlazaState = XClass(XEcologyCharAIBaseState, "XLuosaitaCrossPlazaState")

---数据配置
---@overload
function XLuosaitaCrossPlazaState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.CrossPlaza
    self.StateConfig.StateAnim = "Drama_Stand_16"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 3
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301003",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
    }
end
--endregion


--region 状态-罗塞塔-艺术馆
---@class XLuosaitaArtGalleryState: XEcologyCharAIBaseState @罗塞塔艺术馆状态
local XLuosaitaArtGalleryState = XClass(XEcologyCharAIBaseState, "XLuosaitaArtGalleryState")

---数据配置
---@overload
function XLuosaitaArtGalleryState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.ArtGallery
    self.StateConfig.StateAnim = "Drama_Luosaita_Sad"
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 4
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }
    self.StateConfig.BubbleDict = {
        [EEcologyBubbleType.Around] = {
            Name = "301005",
            TriggerDistance = 6,
            TriggerCD = 2,
            LoopTime = 3,
        },
        [EEcologyBubbleType.Near] = {
            Name = "301004",
            TriggerDistance = 2.5,
            TriggerCD = 2,
            LoopTime = 3,
        }
    }
end

---@overload
function XLuosaitaArtGalleryState:PlayPerformAnim()
    if self.StateConfig and self.StateConfig.StateAnim then
        self._proxy:TurnPos(self._uuid,{x=567.44, y=192.77, z=857.5}, self.StateConfig.StateAnim)
    end
end
--endregion


--region 状态-罗塞塔-寻路
---@class XLuosaitaFindPathState: XEcologyCharAIFindPathState @罗塞塔寻路状态
local XLuosaitaFindPathState = XClass(XEcologyCharAIFindPathState, "XLuosaitaFindPathState")

---数据配置
---@overload
function XLuosaitaFindPathState:InitStateConfig()
    self.StateConfig = {}
    self.StateConfig.StateEnum = StateEnum.FindPath
    self.StateConfig.TriggerId = 1
    self.StateConfig.ShowOptionId = 5
    self.StateConfig.RegisterWorldEventList = {
        EWorldEvent.ActorTrigger,
        EWorldEvent.NpcInteractStart,
        EWorldEvent.NpcInteractComplete,
    }

    self.StateConfig.PathBubbleName = "301006"
    self.StateConfig.PathTargetPosDict = StatePos
end
--endregion


--region 罗塞塔军备区生态AI
---@class XCharLuosaitaEcology : XEcologyCharAIBase
---@field _stateMachine XStateMachineController 状态机
local XCharLuosaitaEcology = XDlcScriptManager.RegCharScript(10608801, "XCharLuosaitaEcology", Base)

function XCharLuosaitaEcology:InitStateConfigData()
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
function XCharLuosaitaEcology:RegisterMachineState()
    self._stateMachine:AddState(StateEnum.Garden, XLuosaitaGardenState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.CrossPlaza, XLuosaitaCrossPlazaState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.ArtGallery, XLuosaitaArtGalleryState.New(self._proxy))
    self._stateMachine:AddState(StateEnum.FindPath, XLuosaitaFindPathState.New(self._proxy))
end

--- 注册状态转移方程
function XCharLuosaitaEcology:RegisterMachineStateTransition()
    self._stateMachine:AddStateTransition(StateEnum.CrossPlaza, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.CrossPlaza], 1)
    self._stateMachine:AddStateTransition(StateEnum.ArtGallery, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.ArtGallery], 1)
    self._stateMachine:AddStateTransition(StateEnum.Garden, StateEnum.FindPath, XOther2FindPathTransition.New(self._proxy), 30, StatePath[StateEnum.Garden], 1)
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.Garden, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.Garden])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.CrossPlaza, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.CrossPlaza])
    self._stateMachine:AddStateTransition(StateEnum.FindPath, StateEnum.ArtGallery, XFindPath2OtherTransition.New(self._proxy), StatePos[StateEnum.ArtGallery])
end

return XCharLuosaitaEcology
--endregion

