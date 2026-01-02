local Base = require("Common/XBigWorldCharBase")
local XStateMachineController = require("Common/StateMachine/XStateMachineController")

---生态AI基类
---@class XEcologyCharAIBase : XBigWorldCharBase
---@field _uuid number npcUUID
---@field _isInit boolean 已初始化
---@field _stateMachine XStateMachineController 状态机
---@field _proxy XDlcCSharpFuncs
---@field StateTargetPosDict table<number, Vector3> 寻路路径字典, Key=状态枚举, Value=坐标
---@field FindPathStateEnum number 寻路状态枚举
---@field FindPathDict table<number, Vector3[]> 寻路路径字典, Key=状态枚举, Value=路径点数组
---@field FindPathDefaultTargetEnum number 寻路状态下一个状态的默认枚举
local XEcologyCharAIBase = XClass(Base, "XEcologyCharAIBase")

---@param proxy XDlcCSharpFuncs
function XEcologyCharAIBase:Ctor(proxy)
    self._proxy = proxy
end

---@param dt number @ delta time
function XEcologyCharAIBase:Update(dt)
    if not self._isInit then
        self:TryInitAIEnterState()
    end
    self._stateMachine:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XEcologyCharAIBase:HandleEvent(eventType, eventArgs)
    self._stateMachine:HandleEvent(eventType, eventArgs)
end

function XEcologyCharAIBase:Terminate()
    self:TerminateStateMachine()
end

--region 基础生命周期函数
---@private
function XEcologyCharAIBase:CommonInit()
    self._isInit = false
    self._uuid = self._proxy:GetSelfNpcId()
    self:InitStateConfigData()
    self:InitStateMachine()
end
--endregion

--region 状态机
---@private
function XEcologyCharAIBase:InitStateMachine()
    self:RegisterStateSaveKey()
    -- 初始化状态机
    self._stateMachine = XStateMachineController.New(self._proxy)
    self._stateMachine:Init()
    
    self:RegisterMachineState()
    self:RegisterMachineStateTransition()
end

function XEcologyCharAIBase:InitStateConfigData()
    ---状态点坐标, 
    self.StateTargetPosDict = {}
    ---寻路状态枚举
    self.FindPathStateEnum = 0
    ---寻路路径字典, Key=状态枚举, Value=路径点数组
    self.FindPathDict = {}
    ---寻路状态下一个状态的默认枚举
    self.FindPathDefaultTargetEnum = 0
end

--- 设置状态保存
function XEcologyCharAIBase:RegisterStateSaveKey()
    self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, EEcologySaveKey.CurStateEnum)
    self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathStartStateEnum)
    self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathCuePathIndex)
end

--- 注册状态机状态
function XEcologyCharAIBase:RegisterMachineState()
end

--- 注册状态转移方程
function XEcologyCharAIBase:RegisterMachineStateTransition()
end

---@private
---初始化AI的状态
function XEcologyCharAIBase:TryInitAIEnterState()
    -- 读取当前生态状态
    local haveSave, curStateEnum = self._proxy:TryGetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.CurStateEnum)
    -- 读取寻路目标坐标
    local haveSavePath, findPathStartEnum = self._proxy:TryGetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathStartStateEnum)
    -- 读取寻路路径路径点索引
    local haveSavePathIndex, findPathTargetIndex = self._proxy:TryGetBBInt(XVarDomain.Npc, self._uuid, EEcologySaveKey.FindPathCuePathIndex)
    local tempFindPathTargetEnum = self.FindPathDefaultTargetEnum
    local tempFindPathDistance = -1
    if not haveSave then
        -- 没有状态默认为寻路状态, 判断与几个状态目标点距离
        curStateEnum = self.FindPathStateEnum
        for stateEnum, pos in pairs(self.StateTargetPosDict) do
            -- 距离状态点最近则设置为该目标
            local temp = self._proxy:CalcNpcDistanceWitchPos(self._uuid, pos.x, pos.y, pos.z)
            if temp < 0.0001 then
                curStateEnum = stateEnum
            end
            if tempFindPathDistance < 0 or tempFindPathDistance < temp then
                tempFindPathTargetEnum = stateEnum
                tempFindPathDistance = temp
            end
        end
    end

    --XLog.Debug("[脚本: "..self._proxy.Id.."]读取AI数据:", 
    --        "haveSave: ", haveSave, "curStateEnum: ", curStateEnum,
    --        "haveSavePath: ", haveSavePath, "findPathStartEnum: ", findPathStartEnum,
    --        "haveSavePathIndex: ", haveSavePathIndex, "findPathTargetIndex: ", findPathTargetIndex)
    self._stateMachine:SwitchState(curStateEnum)
    -- 没有保存寻路目标状态就以默认状态
    if curStateEnum == self.FindPathStateEnum then
        if not haveSavePath then
            findPathStartEnum = tempFindPathTargetEnum
        end
        if not haveSavePathIndex then
            findPathTargetIndex = 1
        end
        ---@type XFindPathState
        local state = self._stateMachine:GetState(curStateEnum)
        if state ~= nil then
            state:SetPath(self.FindPathDict[findPathStartEnum])
            state:UpdateCurPathPointIndex(findPathTargetIndex)
            state:StartMove()
        end
    end
    self._isInit = true
end

---@private
function XEcologyCharAIBase:TerminateStateMachine()
    self._stateMachine:Terminate()
    self._stateMachine = nil
end
--endregion

return XEcologyCharAIBase
