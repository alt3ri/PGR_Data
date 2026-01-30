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
    -- 隐藏则不做逻辑更新
    if not self._proxy:GetNpcActive(self._uuid) then
        return
    end
    if not self._isInit then
        self:TryInitAIEnterState()
    end
    self:UpdateCheckLostWay(dt)
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
    if not haveSave or curStateEnum == 0 then
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

    if haveSave then
        -- by v4.2 xf反馈触发太慢, 每次进入时自动跳转到下一状态
        if haveSavePath and curStateEnum == self.FindPathStateEnum then
            curStateEnum = findPathStartEnum + 1
        else
            curStateEnum = curStateEnum + 1
        end
        -- 到达最大状态枚举后从1开始
        if curStateEnum >= self.FindPathStateEnum then
            curStateEnum = 1
        end
        self._proxy:SetNpcPosition(self._uuid, self.StateTargetPosDict[curStateEnum], false)
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
    self:InitCheckLostWayParam()
    self._isInit = true
end

---@private
function XEcologyCharAIBase:TerminateStateMachine()
    self._stateMachine:Terminate()
    self._stateMachine = nil
end
--endregion

--region 检查脱离路径
function XEcologyCharAIBase:InitCheckLostWayParam()
    ---@type Vector3
    self._lastPos = nil
    self._isLostWay = false
    self._checkLostWay = 5
    self._curCheckLostWatTimer = 0
end

---检查是否在路径上
function XEcologyCharAIBase:UpdateCheckLostWay(dt)
    if self._stateMachine.CurStateEnum == self.FindPathStateEnum then
        ---@type XFindPathState
        local state = self._stateMachine:GetState(self.FindPathStateEnum)
        -- 移动暂停时不检查脱离路径
        if not state._isMove then
            -- 停下时重置脱离路径计时
            if self._curCheckLostWatTimer > 0 then
                self._curCheckLostWatTimer = 0
            end
            return
        end
    end
    self._curCheckLostWatTimer = self._curCheckLostWatTimer + dt
    if self._curCheckLostWatTimer >= self._checkLostWay then
        self:CheckAndFixLostWay()
        self._curCheckLostWatTimer = 0
    end
end

function XEcologyCharAIBase:CheckAndFixLostWay()
    -- 在空中则一定是脱离路径
    if self._proxy:CheckNpcOnAir(self._uuid) then
        self._isLostWay = true
    end
    -- 存在坐标记录且是寻路状态时原地踏步(5秒内相对位移小于1)也视为路径异常
    if self._stateMachine.CurStateEnum == self.FindPathStateEnum and self._lastPos then
        local curPos = self._proxy:GetNpcPosition(self._uuid)
        if XScriptTool.Distance(self._lastPos, curPos) < 1 then
            self._isLostWay = true
        end
    end
    if self._isLostWay then
        self:TeleportInWay()
    end
    if self._stateMachine.CurStateEnum == self.FindPathStateEnum then
        self._lastPos = self._proxy:GetNpcPosition(self._uuid)
    else
        self._lastPos = nil
    end
end

function XEcologyCharAIBase:TeleportInWay()
    local position
    if self._stateMachine.CurStateEnum == self.FindPathStateEnum then
        ---@type XFindPathState
        local state = self._stateMachine:GetState(self.FindPathStateEnum)
        position = state._curTargetPathPoint
        self._proxy:SetNpcPosition(self._uuid, position, true)
    else
        position = self.StateTargetPosDict[self.FindPathDefaultTargetEnum]
        self._proxy:SetNpcPosition(self._uuid, position, true)
        self._stateMachine:SwitchState(self.FindPathDefaultTargetEnum)
    end
    self._isLostWay = false
    self._proxy:ApplyMagic(self._uuid, self._uuid, 200037, 1) --传送特效
    XLog.Warning("[脚本: "..self._proxy.Id.."]脱离路线, 开始传送, 目标坐标:", position)
end
--endregion

return XEcologyCharAIBase
