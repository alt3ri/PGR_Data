local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙
---@class XChar8056 : XFightBase
local XChar8056 = XDlcScriptManager.RegCharScript(8056, "XChar8056", Base)

XChar8056.EInterpMode =
{
    Linear = 0,
    EaseOutCubic = 1
}

XChar8056.EFightState = {
    Inactive = 0,
    Normal = 1,
    OD = 2,
    ODBreakStart = 3,
    ODBreaking = 4,
    Break = 5,
    Death = 6
}

--region 函数: 脚本生命周期
function XChar8056:Init()
    Base.Init(self)

    self._syncDomain = 1

    -- !! syncKeys与syncVarLocalVals必须最早被初始化
    --- 参与网络变量同步的变量键值
    self._syncKeys =
    {
        isAiActivated = 8005001,
        isInWrestleState = 8005002,
        battleLoopIdx = 8005003,
        curSeqIdx = 8005004,
        nextSeqIdx = 8005005,
        curSkillId = 8005006,
        curComboId = 8005007,
        fightStateId = 8005008
    }
    --- 参与网络变量同步的变量的本地值
    self._syncVarLocalVals =
    {
        [8005001] = true,
        [8005002] = false,
        [8005003] = 0,
        [8005004] = 0,
        [8005005] = 0,
        [8005006] = 0,
        [8005007] = 0,
        [8005008] = XChar8056.EFightState.Inactive
    }

    -- AI总控
    self:InitSyncBool(self._syncKeys.isAiActivated)

    self:InitAggroSystem()
    self:InitChasingSystem()
    self:InitCoreCombatSystem()
    self:InitDelayCallSystem()
    self:InitDebugSystem()

    -- 一些通用的效果ID
    self._rHandReflectParticle = 8005003
    self._lHandReflectParticle = 8005002
    self._lightReflectSlomo = 8005004
    self._heavyReflectSlomo = 8005005

    -- 状态机
    self:InitFightStateMachine()

    -- 开始运行AI
    self:DelayCall("DelayStartCombat", 3)
end

function XChar8056:DelayStartCombat()
    -- 开始运行
    --[[
    for k, playerID in ipairs(self._proxy:GetPlayerNpcList()) do
        if self:IsPlayerCarry(playerID) then
            self._proxy:SetNpcPosition(playerID, {x = 57.5, y = 2, z = 43.5})
        end
        if self:IsPlayerTank(playerID) then
            self._proxy:SetNpcPosition(playerID, {x = 55.5, y = 2, z = 45})
        end
        if self:IsPlayerSup(playerID) then
            self._proxy:SetNpcPosition(playerID, {x = 59.5, y = 2, z = 45})
        end
    end
    self._proxy:SetNpcPosition(self._uuid, {x = 57.5, y = 2, z = 60})
    ]]

    self:SetIsAiActivated(false)

    self._fightSM:Activate()
    self._fightSM:SetTrigger(self._fightSMTriggers.activate)
end

---@param dt number @ delta time
function XChar8056:Update(dt)
    Base.Update(self, dt)

    -- 延迟调用
    self:UpdateDelayCallSystem(dt)

    -- 测试用tick
    self:UpdateDebugSystem(dt)

    -- 同步是否启动AI
    if not self:GetIsAiActivated() then
        return
    end

    self._fightSM:Update(dt)

    -- 固定频率更新仇恨目标
    self:UpdateAggroSystem(dt)

    -- 如果突破了仇恨系统大关，发现目标仍然不合法或没有目标，就执行和平逻辑
    if self._curAggroTarUUID == nil or (not self._proxy:CheckNpc(self._curAggroTarUUID)) or self._proxy:IsNpcDead(self._curAggroTarUUID) then
        self:ForceSetNearestAlivePlayerAsAggroTarget()

        if self._curAggroTarUUID == 0 then
            self:UpdatePeaceSystem(dt)
        end
        return
    end

    -- 角力状态阻断后续逻辑
    if self:GetIsInWrestleState() then
        return
    end

    -- 追逐逻辑
    self:UpdateChasingSystem(dt)

    -- 战斗核心逻辑
    self:UpdateCoreCombatSystem(dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8056:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8056:InitEventCallBackRegister()
    -- 事件绑定
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcOverDriveFull)
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)

    -- 指定目标事件绑定
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter, self._uuid)

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)
end

function XChar8056:Terminate()
    -- 追逐系统注销
    self._proxy:SetNpcStopFollow(self._uuid)

    -- 事件解绑
    self._proxy:UnregisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:UnregisterEvent(EWorldEvent.NpcDamage)
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcOverDriveFull)
    self._proxy:UnregisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcODExitBreakAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcWrestleStart)
    self._proxy:UnregisterEvent(EWorldEvent.NpcWrestlePursuit)
    self._proxy:UnregisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:UnregisterEvent(EWorldEvent.NpcDodge)

    -- 指定目标事件解绑
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter, self._uuid)

    -- 注销所有同步变量
    for variable, key in pairs(self._syncKeys) do
        self:UnregSyncVar(key)
    end

    Base.Terminate(self)
end
--endregion

--region 延迟调用系统
--- 延迟调用函数：参数1：函数名，参数2：延迟，后续参数：函数参
function XChar8056:DelayCall(...)
    -- 未启用延迟，则不予调用
    if not self._enableDelayFeature then
        return
    end

    -- 检测是否超过最大调用数量(添加表Count + 更新表Count)
    if (#self._delayCallTable + #self._delayCallAddTable) >= self._maxDelayCallCount then
        return
    end

    -- 合法性检测
    local paramCount = select("#", ...)
    if paramCount < 2 then
        return
    end

    -- 构建参数
    local func
    local delay = 0
    local funcParams = { self }
    local args = {...}
    for i = 1, paramCount do
        if i == 1 then
            local funcName = args[i]
            if type(funcName) ~= "string" then
                return
            end
            func = self[funcName]
            if type(func) ~= "function" then
                return
            end
        elseif i == 2 then
            delay = args[i]
            if type(delay) ~= "number" then
                return
            end
        else
            table.insert(funcParams, args[i])
        end
    end

    -- 参数加入添加表
    table.insert(self._delayCallAddTable, {func, delay, funcParams})
end

--- 初始化：延迟调用系统
function XChar8056:InitDelayCallSystem()
    -- 延迟调用：可配置参数
    --- 是否启用延迟调用特性
    self._enableDelayFeature = true;
    --- 延迟调用上限
    self._maxDelayCallCount = 5

    -- 延迟调用：这下面的变量别动
    --- 延迟调用添加表
    self._delayCallAddTable = {}
    --- 延迟调用更新表
    self._delayCallTable = {}
    --- 延迟调用移除表
    self._delayCallRemoveTable = {}
end

--- 更新：延迟调用系统
function XChar8056:UpdateDelayCallSystem(dt)
    -- 未启用延迟，则不予调用
    if not self._enableDelayFeature then
        return
    end

    -- 延迟调用添加
    for i = 1, #self._delayCallAddTable do
        table.insert(self._delayCallTable, self._delayCallAddTable[i])
    end
    -- 清空添加表
    self._delayCallAddTable = {}

    -- 延迟调用更新
    for i = 1, #self._delayCallTable do
        self._delayCallTable[i][2] = self._delayCallTable[i][2] - dt

        if self._delayCallTable[i][2] <= 0 then
            -- 调用函数
            self._delayCallTable[i][1](table.unpack(self._delayCallTable[i][3]))
            -- 可移除
            table.insert(self._delayCallRemoveTable, i)
        end
    end

    -- 延迟调用移除(倒序)
    for i = #self._delayCallRemoveTable, 1, -1 do
        table.remove(self._delayCallTable, self._delayCallRemoveTable[i])
    end
    self._delayCallRemoveTable = {}
end
--endregion

--region 仇恨系统
--- 初始化：仇恨系统
function XChar8056:InitAggroSystem()
    --- 当前仇恨目标UUID
    self._curAggroTarUUID = nil
    --- 仇恨目标更新频率
    self._aggroUpdateInterval = 0.25
    --- 仇恨目标更新计时器
    self._aggroUpdateTimer = 0
    --- 当前到仇恨目标的距离
    self._curDisToAggroTar = 0

    --- 当前点名目标UUID
    self._curPickingTarUUID = nil
end

--- 更新：仇恨系统
function XChar8056:UpdateAggroSystem(dt)
    if self._aggroUpdateTimer >= self._aggroUpdateInterval then
        -- 基于仇恨系统的获取
        local targetNpc = self._proxy:GetMaxThreatNpc(self._uuid)
        --设置为仇恨目标
        if self._proxy:CheckNpc(targetNpc) then
            self._curAggroTarUUID = targetNpc
            -- 如果不为空，就更新为fight target
            if self._curAggroTarUUID ~= nil then
                self._curDisToAggroTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
            end
        end

        self._aggroUpdateTimer = 0
    end

    -- 是否有目标存在？目标如果不合法就强制更新一次
    if self._curAggroTarUUID == nil or (not self._proxy:CheckNpc(self._curAggroTarUUID)) or self._proxy:IsNpcDead(self._curAggroTarUUID) then
        self:ForceSetNearestAlivePlayerAsAggroTarget()
    end

    -- 点名目标消失处理
    if self._curPickingTarUUID ~= nil then
        if not self._proxy:CheckNpc(self._curPickingTarUUID) or self._proxy:IsNpcDead(self._curPickingTarUUID) then
            self._curPickingTarUUID = nil
        end
    end

    self._aggroUpdateTimer = self._aggroUpdateTimer + dt
end

--- 强制让距离最近的玩家成为仇恨目标，目前临时用作仇恨系统出问题的保底对策
function XChar8056:ForceSetNearestAlivePlayerAsAggroTarget()
    local curMinDisPlayer = 0
    local curMinDis = math.huge
    for i, player in ipairs(self._proxy:GetPlayerNpcList()) do
        local curDis = self._proxy:CalcNpcDistance(self._uuid, player)
        if (not self._proxy:IsNpcDead(player)) and curDis < curMinDis then
            curMinDisPlayer = player
            curMinDis = curDis
        end
    end

    if curMinDisPlayer ~= 0 then
        self._curAggroTarUUID = curMinDisPlayer
    end
end

--- 获取当前技能目标，有点名选点名，没点名选仇恨
function XChar8056:GetSkillTarget()
    if self._curPickingTarUUID == nil then
        return self._curAggroTarUUID
    else
        return self._curPickingTarUUID
    end
end
--endregion

--region 追逐系统
--- 初始化：追逐系统
function XChar8056:InitChasingSystem()
    --- 最短的追逐停止距离
    self._minChaseStopDis = 8
    --- 当前追逐停止距离
    self._curChaseStopDis = 10
    --- 当前追逐目标UUID
    self._curChasingTarUUID = nil
    --- 是否正在追逐
    self._isChasing = false

    -- 防止换端还在追逐，先执行一次停止
    self._proxy:SetNpcStopFollow(self._uuid)
end

--- 更新：追逐系统
function XChar8056:UpdateChasingSystem(dt)
    -- 追逐未开始，不执行后续逻辑
    if not self._isChasing then
        return
    end

    -- 追逐停止的条件检测，为了方便debug停止原因，这里分开单独判断
    local isAggroTargetNull = self:GetSkillTarget() == nil
    local isAggroTargetChange = self:GetSkillTarget() ~= self._curChasingTarUUID
    local isInStopDis = self._curDisToAggroTar <= self._curChaseStopDis

    -- 追逐流程停止
    if isAggroTargetNull or isAggroTargetChange or isInStopDis then
        self._proxy:SetNpcStopFollow(self._uuid)
        self._isChasing = false

        -- 输出log
        if self._isDebugChasingLogic then
            local logInfo = "白龙追逐系统: 追逐停止！停止原因为"
            if isAggroTargetNull then
                logInfo = logInfo .. "[仇恨目标为空]"
            end
            if isAggroTargetChange then
                logInfo = logInfo .. "[仇恨目标变更]"
            end
            if isInStopDis then
                logInfo = logInfo .. "[到达停止距离]"
            end
            XLog.Debug(logInfo)
        end
        return
    end
end

--- 追逐仇恨目标
---@param stopDis number @ 停止追逐距离
function XChar8056:ChasingAggroTarget(stopDis)
    -- 仇恨目标是否为空
    if self:GetSkillTarget() == nil then
        return
    end

    -- 参数类型和是否为空的验证
    if stopDis == nil or type(stopDis) ~= "number" then
        return
    end

    -- 参数合法性验证以及修正
    if stopDis < self._minChaseStopDis then
        stopDis = self._minChaseStopDis
    end

    -- 如果还在追逐流程，则先停止追逐
    if self._isChasing then
        --self._followController:CancelFollow()
        self._proxy:SetNpcStopFollow(self._uuid)
        XLog.Debug("白龙追逐系统: 上一个追逐流程未结束，强制停止！")
    end

    -- 开始追击
    self._curChaseStopDis = stopDis;
    self._curChasingTarUUID = self:GetSkillTarget()
    self._isChasing = true;
    --self._followController:SetFollowTargetNpcNoNavMesh(self._curChasingTarUUID,  0, self._curChaseStopDis, 0.05)
    self._proxy:SetNpcDirectlyFollow(
            self._uuid,
            self._curChaseStopDis,
            0,
            false,
            false,
            false,
            0,
            false,
            self._curChasingTarUUID,
            45)

    if self._isDebugChasingLogic then
        XLog.Debug(string.format("白龙追逐系统: 开始追逐目标，目标UUID[%d]", self._curChasingTarUUID))
    end
end
--endregion

--region 核心战斗系统
--- 初始化：核心战斗系统
function XChar8056:InitCoreCombatSystem()
    self:InitCoreCombatStateControlSystem()
    self:InitCoreCombatSkillCastSystem()
    self:InitCoreCombatInSkillSystem()
    self:InitCoreCombatRectifySystem()
    self:InitCoreCombatCoolDownSystem()
    -- self:InitCoreCombatWrestleSystem()
end

--- 更新：核心战斗系统
--- @param dt number @ delta time
function XChar8056:UpdateCoreCombatSystem(dt)
    -- 特殊大招逻辑
    self:UltraRayUpdateLogic(dt)

    -- 循环轴为nil或长度为0则不执行后续逻辑
    if self._intendSkillSeqs == nil or #self._intendSkillSeqs <= 0 then
        return
    end

    -- 技能CD更新
    self:UpdateCoreCombatCoolDownSystem(dt)

    -- 状态控制系统更新
    --self:UpdateCoreCombatStateControlSystem()

    -- 技能中的话，阻断后续逻辑，并进行连招检定
    if self._proxy:CheckNpcFullActionState(self._uuid, 3, -1) then
        self:UpdateCoreCombatInSkillSystem()
        return
    end

    self:UpdateCoreCombatSkillCastSystem()
end
--endregion

--region 核心战斗系统：状态控制系统
function XChar8056:InitCoreCombatStateControlSystem()
    self._odBreakSkill = 8005524
    --- OD Break开始技能ID
    self._odBreakEnterSkill = 8005331
    --- OD Break循环技能ID
    self._odBreakLoopSkill = 8005332
    --- OD Break结束技能ID
    self._odBreakExitSkill = 8005333
    --- OD Break四方向受击
    self._odBreakGetHitActionsInfo = {
        { 8005514, 0.716, {{-45, 45}}},    -- 前
        { 8005516, 0.55, {{-135, -45}}},    -- 左
        { 8005517, 0.55, {{45, 135}}},    -- 右
        { 8005517, 0.55, {{-180, -135}, {135, 180}}},     -- 后
    }

    --- 破韧技能表-重版（适配多方位破韧受击）
    self._tenacityBreakSkillSeqHeavy = {
        8005124,    -- 前破
        8005128,    -- 左破
        8005132,    -- 右破
        8005136     -- 后破
    }
    --- 破韧技能表-轻版（适配多方位破韧受击）
    self._tenacityBreakSkillSeqLight = {
        8005311,    -- 前破
        8005314,    -- 左破
        8005313,    -- 右破
        8005312     -- 后破
    }
    --- 破韧不同角度受击动作的触发角度条件
    self._tenacityBreakAngleConds = {
        {{-45, 45}},
        {{-135, -45}},
        {{45, 135}},
        {{-180, -135}, {135, 180}}
    }

    --- 是否正在角力状态内
    self:InitSyncBool(self._syncKeys.isInWrestleState)

    --- 破韧状态的持续时间
    self._breakMagicId = 8005901
    self._immuUltraAbortMagicId = 8005906
    self._cancelImmuUltraAbortMagicId = 8005907

    -- 初始化韧性OD系统
    self._proxy:SetNpcBreakGaugeActive(self._uuid, true)
    self._proxy:SetNpcOverDriveActive(self._uuid, true)
end

--- 已弃用（转用状态机）
function XChar8056:UpdateCoreCombatStateControlSystem()
    -- OD Break序列逻辑
    --[[
    if self:GetIsODBreaking() then
        if self:GetIsODBreakLooping() then
            if self._proxy:CheckNpcCurrentAction(self._uuid, self._odBreakSkill) and self._skillTimer >= 4.13 then
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid, self._odBreakSkill, self._odBreakLoopTimeInterval.beginTime, self._odBreakLoopTimeInterval.endTime + 0.1)
            end
        else
            if self._proxy:CheckNpcCurrentAction(self._uuid, self._odBreakSkill) and self._skillTimer >= 1.6 then
                self:SetIsODBreakLooping(true)
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid, self._odBreakSkill, self._odBreakLoopTimeInterval.beginTime, self._odBreakLoopTimeInterval.endTime + 0.1)
            end
        end
    end
    ]]
end

--- 已弃用（转用状态机）
function XChar8056:ChangeState(nextState)
    --[[
    -- 自身状态濒死或死亡，则返回
    if self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Dying, -1) and self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Death, -1) then
        if self._isDebugBattleLogic then
            XLog.Debug("白龙核心战斗：已处于濒死或死亡状态，无法进入普通状态")
        end
        return
    end

    -- 如果AI没开启，不允许切换
    if not self:GetIsAiActivated() then
        return
    end

    -- 如果同状态，则不允许切换
    if self:GetCurBattleState() == nextState then
        return
    end

    -- 从OD变回普通时，设立战斗循环索引(如果循环轴为空，则设为0)
    if self:GetCurBattleState() == XChar8056.EBattleState.ODState and nextState == XChar8056.EBattleState.NormalState then
        local newBattleLoopIdx = self:GetBattleLoopIdx() + 1
        if #self._intendSkillSeqs > 0 then
            if newBattleLoopIdx > #self._intendSkillSeqs then
                newBattleLoopIdx = 1
            end
        else
            newBattleLoopIdx = 0
        end
        self:SetBattleLoopIdx(newBattleLoopIdx)
    end

    -- 设立状态
    local previousState = self:GetCurBattleState()
    self:SetCurBattleState(nextState)
    self:SetCurSeqIdx(0)
    self:SetNextSeqIdx(1)

    -- 设立技能轴
    if self:GetBattleLoopIdx() > 0 then
        XLog.Debug("白龙：设立技能轴")
        self._curSkillSeq = self._intendSkillSeqs[self:GetBattleLoopIdx()][self:GetCurBattleState()]
    end

    -- 如果转到Inactive则强制刷新所有CD，否则正常刷新
    self:RefreshSkillCD(nextState == XChar8056.EBattleState.Inactive)
    ]]
end

--- 根据伤害来源角色位置，播放对应的破韧动作
function XChar8056:CastTenaBreakSkillBySrcPos(srcId, isHeavy)
    -- 异常情况排除，nil和空table的情况
    if self._tenacityBreakSkillSeqHeavy == nil or self._tenacityBreakSkillSeqLight == nil or
            #self._tenacityBreakSkillSeqHeavy <= 0 or #self._tenacityBreakSkillSeqLight <= 0 or
            self._tenacityBreakAngleConds == nil or #self._tenacityBreakAngleConds <= 0 then
        return
    end

    -- 来源不存在
    if not self._proxy:CheckNpc(srcId) then return end

    -- 默认用第一个
    local resultSkillIdx = 1

    -- 根据角度细化选择破韧技，选不到就用默认的
    if #self._tenacityBreakSkillSeqHeavy == #self._tenacityBreakAngleConds then
        for i = 1, #self._tenacityBreakAngleConds do
            if self:IsTarSatisfyAngleCond(srcId, self._tenacityBreakAngleConds[i]) then
                resultSkillIdx = i
            end
        end
    end

    local resultSkillId = self._tenacityBreakSkillSeqLight[resultSkillIdx]
    if isHeavy then
        resultSkillId = self._tenacityBreakSkillSeqHeavy[resultSkillIdx]
    end

    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastAction(self._uuid, resultSkillId)
end

function XChar8056:CastBreakSkill(isQTE)
    self._proxy:AbortAction(self._uuid, true)
    if isQTE then
        self._proxy:CastAction(self._uuid, 8005522)
    else
        self._proxy:CastAction(self._uuid, 8005125)
    end
end

function XChar8056:CastODBreakHitActionBySrcPos(srcId)
    -- 来源不存在
    if not self._proxy:CheckNpc(srcId) then return end

    -- 默认用第一个
    local resultInfoIdx = 1

    -- 根据角度细化选择Hit动作，选不到就用默认的
    for i = 1, #self._odBreakGetHitActionsInfo do
        if self:IsTarSatisfyAngleCond(srcId, self._odBreakGetHitActionsInfo[i][3]) then
            resultInfoIdx = i
        end
    end

    self._proxy:AbortAction(self._uuid, true)
    XLog.Warning(self._odBreakGetHitActionsInfo[resultInfoIdx][1])
    self._proxy:CastAction(self._uuid, self._odBreakGetHitActionsInfo[resultInfoIdx][1])
end
--endregion

--region 核心战斗系统：技能释放系统
function XChar8056:InitCoreCombatSkillCastSystem()
    -- 战斗: 技能
    -- 关于修正：因为目前修正只考虑正向释放的攻击性技能，像例如吼叫或者背后攻击，是不会专门修正的
    -- 关于距离条件：格式为 { 最小距离，最大距离 }
    --- 存储技能信息，其中 [技能序号] = {CD, 转阶段是否重置CD, 是否允许修正, 距离条件, 角度条件}
    self._skillInfos =
    {
        [8005011] = {     -- OD吼
            math.huge,   true,    false,   {},   {}
        },
        [8005012] = {     -- 入战吼
            math.huge,   false,   false,   {},   {}
        },
        [8005013] = {     -- 入战吼·真
            math.huge,   false,   false,   {},   {}
        },
        [8005014] = {
            0,          true,    true,    {},   {}
        },
        [8005030] = {     -- 二连小前咬
            0,          true,    true,    {4, 10}, {{-60, 60}}
        },
        [8005031] = {     -- 右扫爪+拍地板
            0,          true,    true,    {6, 12}, {{-60, 60}}
        },
        [8005032] = {     -- 黄圈右扫爪
            0,          true,    true,    {4, 14}, {{-90, 60}}
        },
        [8005035] = {     -- 黄圈左扫爪
            0,           true,    true,    {6, 14}, {{-60, 90}}
        },
        [8005037] = {      -- 黄圈左扫爪 + 起飞砸地（占位）
            0,           true,    true,    {4, 14}, {{-60, 90}}
        },
        [8005033] = {      -- 身后二连甩尾
            0,           true,    false,    {6, 12}, {{-180, -120}, {120, 180}}
        },
        [8005034] = {      -- 后撤开炮
            0,           true,    true,    {4, 30}, {{-60, 60}}
        },
        [8005038] = {      -- 左刺
            0,           true,    true,    {8, 18}, {{-55, 55}}
        },
        [8005039] = {      -- 左右刺
            0,           true,    true,    {8, 17.5}, {{-55, 55}}
        },
        [8005036] = {      -- 龙车
            0,           true,    true,    {6, 30}, {{-55, 55}}
        },
        [8005040] = {      -- 龙车+起飞砸地
            0,           true,    true,    {6, 12}, {{-55, 55}}
        },
        [8005045] = {      -- 龙车+起飞失败
            0,           true,    true,    {6, 12}, {{-55, 55}}
        },
        [8005041] = {      -- 浮游炮射击
            0,           true,    true,    {0, 20}, {{-55, 55}}
        },
        [8005042] = {      -- 小喷火
            0,           true,    true,    {4, 10}, {{-45, 45}}
        },
        [8005043] = {      -- 大喷火
            0,           true,    true,    {8, 25}, {{-55, 55}}
        },
        [8005046] = {      -- 蓄力跳砸
            0,           true,    true,    {14, 35}, {{-55, 55}}
        },
        [8005047] = {      -- 喷气起飞冲地
            0,           true,    true,    {6, 25}, {{-55, 55}}
        },
        [8005048] = {      -- 演出落地招 - 临时
            0,           true,    true,    {}, {}
        },
        [8005051] = {      -- 横扫口爆
            0,           true,    true,    {7, 14}, {{-55, 55}}
        },
        [8005055] = {      -- 飞天轰炸
            math.huge,    true,    false,   {},   {}
        },
        [8005505] = {      -- 多人弹刀技能
            150,           true,    true,    {7, 14}, {{-55, 55}}
        },
        [8005514] = {
            0,           true,    true,    {14, 35}, {{-55, 55}}
        },
        [8005296] = {
            0,          true,    true,    {4, 14}, {{-60, 60}}
        },
        [8005298] = {
            math.huge,   true,    false,    {}, {}
        },
        [8005299] = {
            0,           true,    true,    {}, {}
        },
        [8005300] = {
            0,           true,    true,    {}, {}
        },
        [8005315] = {   -- 入场动作
            math.huge,   false,   false,   {}, {}
        },
        [8005518] = {   -- 全场喷火
            math.huge,   true,    false,    {}, {}
        },
        [8005301] = {
            math.huge,   true,    false,    {}, {}
        },
        [8005321] = {
            0, true, true, {4, 14}, {{-90, 60}}
        },
        [8005322] = {
            0, true, true, {4, 30}, {{-60, 60}}
        },
        [8005323] = {
            0, true, true, {6, 14}, {{-60, 90}}
        },
        [8005324] = {
            0, true, true, {6, 30}, {{-55, 55}}
        },
        [8005325] = {
            0, true, true, {8, 17.5}, {{-55, 55}}
        },
        [8005326] = {
            0, true, true, {0, 20}, {{-55, 55}}
        }
    }
    -- 每个技能组里存储多个技能，每个里面包含{技能索引, 释放权重, 优先级}
    -- 【释放权重】 在有多个技能可以释放时，权重决定选择哪个的概率高一些
    --- 技能并行群组
    self._skillGroup = {
        -- 1号轴普通阶段
        [1] = {{8005011, 1, 1}},             -- OD吼
        [2] = {{8005012, 1, 1}},             -- 入战吼
        [3] = {{8005030, 1, 1}},             -- 二连前咬
        [4] = {{8005031, 1, 1}},             -- 右扫爪+拍地板
        [5] = {{8005032, 1, 1}},             -- 黄圈右扫
        [6] = {{8005033, 1, 1}},             -- 身后二连甩尾
        [7] = {{8005034, 1, 1}},             -- 后撤开炮
        [8] = {{8005035, 1, 1}},             -- 黄圈左扫
        [9] = {{8005036, 1, 1}},             -- 龙车
        [10] = {{8005037, 1, 1}},            -- 黄圈扫+砸地
        [11] = {{8005038, 1, 1}},            -- 左刺
        [12] = {{8005039, 1, 1}},            -- 左右刺
        [13] = {{8005040, 1, 1}},            -- 龙车+起飞砸地
        [14] = {{8005041, 1, 1}},            -- 浮游炮射击
        [15] = {{8005042, 1, 1}},            -- 小喷火
        [16] = {{8005043, 1, 1}},            -- 大喷火
        [17] = {{8005046, 1, 1}},            -- 蓄力跳砸
        [18] = {{8005047, 1, 1}},            -- 喷气起飞冲地
        [19] = {{8005051, 1, 1}},            -- 横扫口爆
        [20] = {{8005055, 1, 1}},            -- 飞天轰
        [21] = {{8005505, 1, 1}},            -- ！多人弹刀技能！
        [22] = {{8005013, 1, 1}},            -- 入战吼·真
        [23] = {{8005036, 1, 1}, {8005033, 1, 1}}, -- 龙车(50%) or 二连前咬(50%)
        [24] = {{8005032, 1, 1}, {8005035, 1, 1}}, -- 黄圈左扫(50%) or 黄圈右扫(55%)
        [25] = {{8005046, 1, 1}, {8005039, 3, 1}}, -- 蓄力跳砸(25%) or 左右刺(75%)
        [26] = {{8005514, 1, 1}},
        [27] = {{8005298, 1, 1}},            -- DPS CHECK
        [28] = {{8005296, 1, 1}},            -- 小挥爪
        [29] = {{8005048, 1, 1}},            -- 演出落地招 - 临时
        [30] = {{8005518, 1, 1}},            -- 全场喷火
        [31] = {{8005315, 1, 1}},            -- 入场动作
        [32] = {{8005301, 1, 1}},            -- 临时喷火（直播素材）
        [33] = {{8005321, 1, 1}},
        [34] = {{8005322, 1, 1}},
        [35] = {{8005323, 1, 1}},
        [36] = {{8005324, 1, 1}},
        [37] = {{8005325, 1, 1}},
        [38] = {{8005326, 1, 1}},
    }
    -- 每个战斗循环里面细分为普通状态技能轴和OD状态技能轴，每个里面存储了技能组释放序列
    -- 格式为 { 技能组ID，点名概率 }
    --- 期望技能轴，按照顺序执行循环
    self._intendSkillSeqs = {
        --[[
        [1] = {
            [1] = {
                {21, 0}
            },
            [2] = {
                {1, 0},     -- OD吼
                {21, 0},
                {27, 0},
                {30, 0}
            }
        }
        ]]
        [1] = {
            [1] = {
                {23, 0},    -- 龙车(50%) or 二连前咬(50%)
                {24, 1},    -- 黄圈左扫(50%) or 黄圈右扫(55%)，点名率100%
                {28, 0},    -- 小挥爪
                {4, 0},     -- 右扫爪+拍地板
                {11, 0},    -- 左刺
                {19, 0.4},  -- 横扫扇形爆破, 点名率40%
                {7, 0}      -- 后撤开炮
            },
            [2] = {
                {1, 0},     -- OD吼
                {25, 0},    -- 蓄力跳砸(25%) or 左右刺(75%)
                {30, 0},    -- 全场三连喷火
                {14, 0},    -- 浮游炮射击
                {16, 0},    -- 大喷火
                {21, 0},    -- ！多人弹刀技能！
                {3, 0},     -- 二连前咬
                {28, 0},    -- 小挥爪
                {10, 0.5}   -- 黄圈扫+砸地
            }
        },
        [2] = {
            [1] = {
                {9, 0},     -- 龙车
                {24, 1},    -- 黄圈左扫(50%) or 黄圈右扫(55%)，点名率100%
                {15, 0},    -- 小喷火
                {19, 0},    -- 横扫扇形爆破
                {12, 0.5},  -- 左右刺，点名率50%
                {28, 0},    -- 小挥爪
                {4, 0},     -- 右扫爪+拍地板
            },
            [2] = {
                {1, 0},     -- OD吼
                {16, 0},    -- 大喷火
                {27, 0},    -- DPS检测
                {4, 0},     -- 右扫爪+拍地板
                {10, 0},    -- 黄圈扫+砸地
                {14, 0},    -- 浮游炮射击
                {21, 0},    -- ！多人弹刀技能！
                {3, 0},     -- 二连前咬
                {17, 0.5},  -- 蓄力跳砸，点名率50%
                {28, 0},    -- 小挥爪
            }
        }
    }

    --- 战斗循环索引
    self:InitSyncInt(self._syncKeys.battleLoopIdx)
    --- 当前技能轴
    self._curSkillSeq = nil
    --- 期望技能索引
    self:InitSyncInt(self._syncKeys.curSeqIdx)
    --- 下一个技能索引
    self:InitSyncInt(self._syncKeys.nextSeqIdx)
    --- 技能计时器
    self._skillTimer = 0

    -- 战斗：烦躁技能（一定次数放不出技能后强制执行的技能）
    --- 最大烦躁值
    self._maxRectifyIrritation = 10
    --- 当前耐心值
    self._curRectifyIrritation = 0
    --- 角度修正的烦躁增长值表
    self._angleRectifyCostTable = {
        [1] = 2,
        [2] = 2,
        [3] = 2,
        [4] = 2,
        [5] = 2,
        [6] = 2,
        [7] = 2
    }
    --- 距离修正的烦躁增长值表
    self._disRectifyCostTable = {
        [1] = 2,
        [2] = 2,
        [3] = 2
    }
    -- 无视除了CD以外的所有技能条件强制释放一个，如果全在CD就随机选一个放
    -- 里面基本放的都是全方位可用的技能，并且强力技能居多
    -- 如果玩家拉修正太多，就会触发这些技能，因为这些技能本来就在轴里，所以会导致一些乱轴（惩罚机制）
    --- 烦躁后的技能ID表
    self._irritationSkills = {
        8005034,
        8005036,
        8005037
    }

    --- 战斗中心
    self._battleSceneCenter = { x = 60, y = 2, z = 60 }
    --- 战斗安全范围X
    self._battlePosLimitX = { 30, 90 }
    --- 战斗安全范围Y
    self._battlePosLimitZ = { 30, 90 }

    -- 大招：随机激光（固定间隔刷出随机位置的激光）
    --- 大招激光频率随机间隔
    self._ultraRayIntervalRange = {1, 1.2}
    --- 大招激光频率
    self._ultraRayInterval = 0
    --- 大招激光频率计时器
    self._ultraRayIntervalTimer = 0
    --- 大招激光对于玩家的随机偏移
    self._ultraRayPosOffsetRange = {12, 12}
    --- 大招激光选择玩家为目标的概率（否则选择随机点）
    self._ultraRayPickPlayerPossibility = 0.9
    --- 大招激光随机点范围
    self._ultraRayRandomPosRange = {40, 40}
    --- 大招激光持续时间计时器
    self._ultraRayTimer = 0
    --- 大招激光开始延迟（从技能释放开始计算） 5.4
    self._ultraRayStartTime = 2.8
    --- 大招激光停止时间
    self._ultraRayStopTime = 10
    --- 是否在大招激光的流程中
    self._isUltraRayStart = false
    --- 大招激光子弹发射ID
    self._ultraRayMissileLaunchId = 8005072
    --- 大招激光子弹ID
    self._ultraRayMissileId = 8005072
    --- 是否中途拉过镜头了
    self._isUltraCameraModified = false
    --- 中途拉镜延迟
    self._ultraCameraModifyDelay = 4

    -- 大招：群集激光（同时出现大量落雷激光，同时落地）
    --- 浮游炮泊松盘采样
    self._ultraPoissonDiskTimer = 0
    self._ultraPoissonDiskInterval = 4.5
    self._ultraPoissonDiskPerTimer = 0
    self._ultraPoissonDiskPerInterval = 0
    self._ultraPoissonDiskPerCount = 0
    self._ultraPoissonDiskPoints = {}
    self._ultraPoissonDiskWidth = 60
    self._ultraPoissonDiskHeight = 60
    self._ultraPoissonDiskRadius = 14
    self._isUltraPoissonDiskValid = false

    -- DPS检测护盾受击频率控制
    --- DPS检测受击特效最小间隔
    self._ultraDpsCheckHitEffectMinInterval = 0.2
    --- DPS检测受击特效间隔计时器
    self._ultraDpsCheckHitEffectTimer = 0
end

function XChar8056:UpdateCoreCombatSkillCastSystem()
    -- 如果正在追逐，则不执行技能判断
    if self._isChasing then
        return
    end

    if self._curSkillSeq == nil then
        return
    end

    -- 如果技能轴为空，则不执行技能判断
    local skillSeqLength = #self._curSkillSeq
    if skillSeqLength <= 0 then
        return
    end

    -- 自定义技能逻辑，如果筛选出了技能，则不执行后续的筛选逻辑
    if self:CustomSelectSkillLogic() then
        return
    end

    -- 烦躁技能
    if #self._irritationSkills >= 0 and self._curRectifyIrritation >= self._maxRectifyIrritation then
        local validIrritationSkills = {}
        local idx = 1
        for k, skillId in ipairs(self._irritationSkills) do
            local curCdTimer = self._skillCdTimers[skillId]
            if curCdTimer <= 0 then
                validIrritationSkills[idx] = skillId
                idx = idx + 1
            end
        end

        if #validIrritationSkills == 0 then
            validIrritationSkills = self._irritationSkills
        end

        --math.randomseed(os.time())
        --local randomIdx = math.random(1, #validIrritationSkills)
        local randomSkillId = self:GetValueByListRandom(validIrritationSkills)

        -- 释放烦躁技能，重置烦躁值
        self:CastRegularSkill(randomSkillId)
        self._curRectifyIrritation = 0

        if self._isDebugRectifyLogic then
            XLog.Debug(string.format("白龙修正逻辑：烦躁值过高，释放烦躁技能[%d]", randomSkillId))
        end
        return
    end

    -- 顺轴选择技能组(索引计算用Clamp保险，防止OutOfIndex)
    local skillGroupIdx = self._curSkillSeq[self:GetNextSeqIdx()][1]

    local validSkillEleKeys, validSkillEleIdx = {}, 1
    local rotRecEleTotalWeight, rotRecEleKeys, rotRecEleIdx = 0, {}, 1
    local posRecEleTotalWeight, posRecEleKeys, posRecEleIdx = 0, {}, 1
    for key, skillGroupEle in ipairs(self._skillGroup[skillGroupIdx]) do
        local skillId, skillWeight = skillGroupEle[1], skillGroupEle[2]
        -- CD检测，如果还在冷却就不管了
        if self._skillCdTimers[skillId] <= 0 then
            local intendSkillInfo = self._skillInfos[skillId]
            local allowRectify = intendSkillInfo[3]
            local disCond = intendSkillInfo[4]
            local angleCond = intendSkillInfo[5]

            -- 角度检测，是否能释放当前技能(如果长度为0，则说明无视角度条件)
            local isSatisfyAngle = true
            if #angleCond ~= 0 then
                isSatisfyAngle = self:IsTarSatisfyAngleCond(self:GetSkillTarget(), angleCond)
            end

            -- 距离检测，是否能释放当前技能(如果长度为0，则说明无视距离条件)
            local isSatisfyDis = true
            if #disCond ~= 0 then
                local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self:GetSkillTarget())
                isSatisfyDis = curDisToTar >= disCond[1] and curDisToTar <= disCond[2]
            end
            if isSatisfyAngle then
                if isSatisfyDis then
                    validSkillEleKeys[validSkillEleIdx] = key
                    validSkillEleIdx = validSkillEleIdx + 1
                else
                    if allowRectify then
                        posRecEleKeys[posRecEleIdx] = key
                        posRecEleIdx = posRecEleIdx + 1
                        posRecEleTotalWeight = posRecEleTotalWeight + skillWeight
                    end
                end
            else
                if allowRectify then
                    rotRecEleKeys[rotRecEleIdx] = key
                    rotRecEleIdx = rotRecEleIdx + 1
                    rotRecEleTotalWeight = rotRecEleTotalWeight + skillWeight
                end
            end
        end
    end

    --math.randomseed(os.time())
    -- 获取0-1的随机数，设立公用的权重计数器，权重锚点
    local randomFloat = self._proxy:Random(1, 100) / 100
    local weightSum = 0
    local weightAnchor = 0

    -- 有可以释放的技能
    if #validSkillEleKeys > 0 then
        -- 提取其中优先级最高的列表
        local highPrioritySkillEleKeys = {}
        local curHighestPriority = -99999
        local curHighPrioritySkillEleKeyIdx = 1
        local highPriorityTotalWeight = 0
        for idx, key in ipairs(validSkillEleKeys) do
            local skillGroupEle = self._skillGroup[skillGroupIdx][key]
            if skillGroupEle[3] >= curHighestPriority then
                if skillGroupEle[3] > curHighestPriority then
                    highPrioritySkillEleKeys = {}
                    curHighestPriority = skillGroupEle[3]
                end
                highPrioritySkillEleKeys[curHighPrioritySkillEleKeyIdx] = key
                curHighPrioritySkillEleKeyIdx = curHighPrioritySkillEleKeyIdx + 1
                highPriorityTotalWeight = highPriorityTotalWeight + skillGroupEle[2]
            end
        end

        weightAnchor = randomFloat * highPriorityTotalWeight
        -- 遍历所有可释放技能
        for idx, key in ipairs(highPrioritySkillEleKeys) do
            local skillGroupEle = self._skillGroup[skillGroupIdx][key]
            -- 每次遍历更新权重计数器
            weightSum = weightSum + skillGroupEle[2]
            -- 当权重计数器超过锚点时，说明是目标技能，开始释放
            if weightSum >= weightAnchor then
                local skillId = skillGroupEle[1]

                -- 更新索引，释放技能，更新冷却
                self:SetCurSeqIdx(self:GetNextSeqIdx())
                self:CastRegularSkill(skillId)

                self:IncreNextSqrIdx(skillSeqLength)

                if self._isDebugBattleLogic then
                    XLog.Debug(string.format("白龙核心战斗：[普通形态]顺轴释放技能[%d]", skillId))
                end
                -- 跳出循环
                break
            end
        end
        -- 返回，流程结束
        return
    end

    -- 有可以修正角度的技能
    if #rotRecEleKeys > 0 then
        --XLog.Debug("可以修正角度")
        -- TODO: 目前由于修正逻辑只针对正向修正，不会根据技能参数而改变修正逻辑，所以这里其实没必要记录哪些技能要修正
        -- TODO: 但如果后面有空做的话就做（比如，向背后甩尾，就会故意调整成背朝玩家），这里先留一个口子出来
        self:TryRectifyRot()
        return
    end
    if #posRecEleKeys > 0 then
        --XLog.Debug("可以修正距离")
        -- 类似上面按照权重选技能，这里用权重选一个技能来修正距离
        -- TODO: 后面有空考虑加一个修正优先级的系统，优先挑选一个最容易修正的技能
        weightAnchor = randomFloat * posRecEleTotalWeight
        -- 遍历所有可释放技能
        for i = 1, #posRecEleKeys do
            local skillGroupEle = self._skillGroup[skillGroupIdx][i]
            -- 每次遍历更新权重计数器
            weightSum = weightSum + skillGroupEle[2]

            -- 当权重计数器超过锚点时，说明是目标技能，选择它的参数进行修正
            if weightSum >= weightAnchor then
                local intendSkillInfo = self._skillInfos[skillGroupEle[1]]
                local disCond = intendSkillInfo[4]

                -- 看看是不是距离过近，传参修正
                local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self:GetSkillTarget())
                local isTooClose = curDisToTar <= disCond[1]
                self:TryRectifyPos(isTooClose, curDisToTar, disCond[1], disCond[2])
            end
        end
        return
    end

    -- 剩下来的说明在CD里，没救了，啥都不放直接跳过这个技能
    --XLog.Debug(string.format("当前索引[%d], 下一索引[%d], 可放技能[%d], 可修正角度[%d], 可修正距离[%d]", self._curSeqIdx, nextSeqIdx,
    --        #validSkillEleKeys, #rotRecEleKeys, #posRecEleKeys))
    self:IncreNextSqrIdx(skillSeqLength)
end

--- 推进至下一个技能序号
function XChar8056:IncreNextSqrIdx(seqLength)
    self:SetNextSeqIdx(self:GetNextSeqIdx() + 1)
    if self:GetNextSeqIdx() > seqLength then
        self:SetNextSeqIdx(1)
    end

    -- 处理点名
    local pickPossibility = self._curSkillSeq[self:GetNextSeqIdx()][2]
    local isPick = (self._proxy:Random(0, 100) / 100) < pickPossibility
    if isPick then
        -- TODO: 考虑根据体验添加条件点名
        -- 对仇恨目标外随机点名
        --local playerIds = self:GetNonAggroPlayerList()
        local playerIds = self._proxy:GetPlayerNpcList()
        --or #playerIds == 1
        if #playerIds == 0 then
            self._curPickingTarUUID = nil
        else
            self._curPickingTarUUID = self:GetValueByListRandom(playerIds)
            XLog.Warning(string.format("点名：目标为[%d]", self._curPickingTarUUID))
        end
    else
        -- 取消点名
        self._curPickingTarUUID = nil
    end
end

function XChar8056:CustomSelectSkillLogic()
    local pos = self._proxy:GetNpcPosition(self._uuid)

    -- 防卡死角，被卡了且面向外侧就跳出来，根据玩家相对位置决定咋跳
    local isOutSideX = pos.x <= self._battlePosLimitX[1] or pos.x >= self._battlePosLimitX[2]
    local isOutSideZ = pos.z <= self._battlePosLimitZ[1] or pos.z >= self._battlePosLimitZ[2]
    local isFacingOutside = self:CheckPosInAngle(self._battleSceneCenter, -75, 75)
    if (isOutSideX or isOutSideZ) and isFacingOutside then
        if not self._proxy:CheckNpc(self:GetSkillTarget()) then
            return false
        end

        local isFacingTarget = self:CheckTargetInAngle(self:GetSkillTarget(), -60, 60)
        local isInDis = self._proxy:CheckNpcDistance(self._uuid, self:GetSkillTarget(), 14)

        if isFacingTarget and isInDis then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005014, self:GetSkillTarget())
            self._curRectifyIrritation = self._curRectifyIrritation + 2
            return true
        end
    end

    return false
end

--- 释放常规技能（常规流程释放的技能，破防，破OD，修正，连招等等均不算常规技能）
function XChar8056:CastRegularSkill(skillId)
    if skillId == 8005055 then
        self._proxy:CastActionToPosition(self._uuid, skillId, self._battleSceneCenter)
    else
        self._proxy:CastActionToTarget(self._uuid, skillId, self:GetSkillTarget())
    end

    self._skillCdTimers[skillId] = self._skillInfos[skillId][1]
    -- 刷新连招序号和当前释放的技能索引
    self:SetCurComboId(0)
    self:SetCurSkillId(skillId)

    XLog.Debug("白龙测试：AI释放技能" .. tostring(skillId))
end
--endregion

--region 核心战斗系统：技能中系统
function XChar8056:InitCoreCombatInSkillSystem()
    -- 连招系统
    -- 每个对应的【技能Id】会配备一个【连招信息表】，表内每一个元素存储的内容为：
    --            [连招序号] = {前连招序号，连招技能Id，连接时间区间，开始时间，结束时间，连招触发概率(0-1浮点)，连招距离要求，连招角度要求}
    --                      如果前招式序号为0，则表示前招式为起手招
    --- 连招配置表
    self._comboTable = {
        -- 后撤开炮 -> 开炮 -> 开炮
        [8005034] = {
            [1] = {0, 8005034, {2, 2.1}, 1.03, 3.46, 1, {10, 35}, {{-75, 75}}, XChar8056.EFightState.OD},
            [2] = {1, 8005034, {2, 2.1}, 1.03, 3.46, 1, {10, 35}, {{-75, 75}}, XChar8056.EFightState.OD}
        },
        -- 龙车 -> 蓄力跳砸
        [8005036] = {
            [1] = {0, 8005046, {2.16, 2.2}, 0, 5, 1, {8, 40}, {{-120, 120}}, XChar8056.EFightState.OD}
        }
    }

    --- 当前技能索引（这个技能索引只有正常放技能会更新，连招不会更新）
    self:InitSyncInt(self._syncKeys.curSkillId)
    --- 当前连招序号
    self:InitSyncInt(self._syncKeys.curComboId)

    --- DPS大招开始Action
    self._ultraBeginActionId = 8005298
    --- DPS大招开始Action结束时间
    self._ultraBeginActionEndTime = 2.7
    --- DPS大招循环Action
    self._ultraLoopActionId = 8005299
    --- DPS大招循环Action结束时间
    self._ultraLoopActionEndTime = 30
    --- DPS大招结束Action
    self._ultraEndActionId = 8005300
    --- DPS大招击破（即，玩家成功通过DPS Check）Action
    self._ultraBreakActionId = nil
    --- DPS大招内，相机是否解除锁定
    self._isUltraEndCameraUnlocked = false
    --- DPS大招内，相机解除锁定的时间点
    self._ultraEndCameraUnlockTime = 0
    --- DPS大招内，相机是否重新锁定
    self._isUltraEndCameraReLocked = false
    --- DPS大招内，相机重新锁定的时间点
    self._ultraEndCameraReLockTime = 7.5
    --- DPS大招后相机重新锁定的部位ID
    self._ultraEndCameraReLockPartId = 8001001
    --- DPS大招内，落地激光镜头是否已经应用
    self._isUltraEndLaserCameraApplied = false
    self._ultraEndLaserCameraTime = 0.2
    self._ultraEndLaserCameraMagic = { 8005462, 8005463 }
    --- DPS大招内，全场爆炸镜头是否已经应用
    self._isUltraEndExplodeCameraApplied = false
    self._ultraEndExplodeCameraTime = 7.6
    self._ultraEndExplodeCameraMagic = { 8005464, 8005465 }

    --- 全场火前置动作是否被打断
    self._isFireUltraPreActionAborted = false
end

--- 更新：核心战斗系统 - 技能中系统
function XChar8056:UpdateCoreCombatInSkillSystem()
    -- 更新技能时间
    local isSuccess, t = self._proxy:TryGetNpcCurrentActionElapsedTime(self._uuid)
    if isSuccess then
        self._skillTimer = t
    end

    -- 自定义技能中逻辑
    local isCustomLogicValid = self:CustomInSkillLogic()
    if isCustomLogicValid then
        return
    end

    -- 检测当前技能是否有连招
    local hasCombo = rawget(self._comboTable, self:GetCurSkillId()) ~= nil
    -- 寻找合适的连招
    if hasCombo then
        local comboInfos = self._comboTable[self:GetCurSkillId()]
        for i = 1, #comboInfos do
            local info = comboInfos[i]
            local foreComboId = info[1]
            local comboSkillId = info[2]
            local comboInterval = info[3]
            local comboBeginTime = info[4]
            local comboEndTime = info[5]
            local comboPossibility = info[6]
            local comboDisCond = info[7]
            local comboAngleCond = info[8]
            local comboStateCond = info[9]

            if self:GetCurComboId() == foreComboId                  -- 连招序号检定
                    and self._skillTimer >= comboInterval[1]    -- 时间区间检定
                    and self._skillTimer <= comboInterval[2]
            then
                -- 角度检定
                local isAngleSatisfy = true
                if #comboAngleCond ~= 0 then
                    isAngleSatisfy = self:IsTarSatisfyAngleCond(self:GetSkillTarget(), comboAngleCond)
                end

                -- 距离检定
                local isDisSatisfy = true
                if #comboDisCond ~= 0 then
                    local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self:GetSkillTarget())
                    isDisSatisfy = curDisToTar >= comboDisCond[1] and curDisToTar <= comboDisCond[2]
                end

                -- 状态检定
                local isStateSatisfy = true
                if comboStateCond ~= nil then
                    local curStateId = self._fightSM:GetCurStateId()
                    isStateSatisfy = curStateId ~= nil and curStateId == comboStateCond
                end

                -- 随机数选取
                --math.randomseed(os.time())
                local randomFloat = self._proxy:Random(1, 100) / 100
                -- XLog.Debug(string.format("随机数检定 - 随机值[%f]，概率[%f]", randomFloat, comboPossibility))

                -- 同时满足，释放连招
                if isAngleSatisfy and isDisSatisfy and isStateSatisfy and randomFloat <= comboPossibility then
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastActionToTargetEx(self._uuid, comboSkillId, self:GetSkillTarget(), comboBeginTime, comboEndTime)
                    self:SetCurComboId(i)
                    break
                end
            end
        end
    end

    -- 打断部分技能
    self:TryBreakSkill()
end

function XChar8056:CustomInSkillLogic()
    if self._proxy:CheckNpcCurrentAction(self._uuid, self._ultraBeginActionId) and self._skillTimer >= self._ultraBeginActionEndTime then
        self._proxy:CastAction(self._uuid, self._ultraLoopActionId)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid, self._ultraEndActionId) then
        -- 解锁，回到自由镜头
        if not self._isUltraEndCameraUnlocked and self._skillTimer >= self._ultraEndCameraUnlockTime then
            --self._proxy:CancelHardLockTarget()
            --self._proxy:CancelSoftLockTarget()
            --XLog.Debug("锁定：取消硬锁")
            self._isUltraEndCameraUnlocked = true
        end

        -- 重新锁定
        if not self._isUltraEndCameraReLocked and self._skillTimer >= self._ultraEndCameraReLockTime then
            self._proxy:SetHardLockToPart(self._uuid, self._ultraEndCameraReLockPartId)
            for k, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
                self._proxy:SetNpcFocusTarget(playerId, self._uuid)
            end
            self._isUltraEndCameraReLocked = true
        end

        -- 激光镜头
        if not self._isUltraEndLaserCameraApplied and self._skillTimer >= self._ultraEndLaserCameraTime then
            self:ApplyMagicToPlayers(self._ultraEndLaserCameraMagic, 1)
            self._isUltraEndLaserCameraApplied = true
        end

        -- 爆炸镜头
        if not self._isUltraEndExplodeCameraApplied and self._skillTimer >= self._ultraEndExplodeCameraTime then
            self:ApplyMagicToPlayers(self._ultraEndExplodeCameraMagic, 1)
            self._isUltraEndExplodeCameraApplied = true
        end
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005518) and not self._isFireUltraPreActionAborted and self._skillTimer >= 0.05 then
        self._proxy:AbortAction(self._uuid, true)
        if(self._proxy:CheckNpcPositionDistance(self._uuid, self._battleSceneCenter, 10, true)) then
            -- 距场中小于10米，直接释放
            self._proxy:CastActionToPosition(self._uuid, 8005301, self._battleSceneCenter)
        else
            -- 距离场中大于10米，先位移再释放
            self._proxy:CastActionToPosition(self._uuid, 8005519, self._battleSceneCenter)
        end
        self._isFireUltraPreActionAborted = true
    end


    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005519) and self._skillTimer >= 2.16 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToPosition(self._uuid, 8005301, self._battleSceneCenter)
    end


    -- 破韧开始 衔接 破韧起身
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005125) and self._skillTimer >= 1.3 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 8005127)
    end

    -- 破韧开始(QTE) 衔接 破韧起身
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005522) and self._skillTimer >= 1.3 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 8005127)
    end
end

function XChar8056:LiveTest()
    -- 临时给C大量的仇恨
    for k, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
        if self:IsPlayerCarry(playerId) then
            self._proxy:ApplyMagic(self._uuid, playerId, 8005353, 1)
        end
    end
end

--- 尝试提前打断部分技能
function XChar8056:TryBreakSkill()
    -- 对白龙的一些修正技能进行提前打断，很多动作有些拖沓，验证过后可以让美术微调
    -- 打断大翻身
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005014) and self._skillTimer >= 1.567 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断小后跳
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005015) and self._skillTimer >= 1.4 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断小后跳
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005017) and self._skillTimer >= 0.6 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断小后撤
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005056) and self._skillTimer >= 0.867 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断右转45
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005003) and self._skillTimer >= 0.833 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断左转45
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005004) and self._skillTimer >= 0.833 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断右转90
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005005) and self._skillTimer >= 1.333 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断左转90
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005006) and self._skillTimer >= 1.333 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断右转135
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005007) and self._skillTimer >= 1.167 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断左转135
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005008) and self._skillTimer >= 1.167 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断后转180
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005009) and self._skillTimer >= 1.267 then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 打断入战吼叫
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005013) and self._skillTimer >= 4 then
        self._proxy:AbortAction(self._uuid, true)
    end
end
--endregion

--region 核心战斗系统：身位修正系统
function XChar8056:InitCoreCombatRectifySystem()
    -- 战斗: 角度和距离修正
    --- 修正角度的技能ID
    self._angleRectifySkills = {
        [1] = 8005003,      -- 右45度
        [2] = 8005004,      -- 左45度
        [3] = 8005005,      -- 右90度
        [4] = 8005006,      -- 左90度
        [5] = 8005007,      -- 右135度
        [6] = 8005008,      -- 左135度
        [7] = 8005009       -- 180度
    }
    --- 角度修正的区间（180度转特殊处理）
    self._angleRectifyConds ={
        [1] = {{45, 50}},
        [2] = {{-50, -45}},
        [3] = {{50, 105}},
        [4] = {{-105, -50}},
        [5] = {{105, 150}},
        [6] = {{-150, -105}},
        [7] = {{150, 180}, {-180, -150}}
    }
    --- 修正距离的技能
    self._disRectifySkills = {
        [1] = 8005015,      -- 小后跳
        [2] = 8005056,       -- 小后撤
        [3] = 8005017       -- 小前跳
    }
    --- 距离修正技能的修正距离（负数代表向前修正拉近距离，正数代表向后修正拉远距离）
    self._disRectifyConds = {
        [1] = 8,
        [2] = 4,
        [3] = -8,
    }
end

--- 尝试通过转向动作来转向目标
function XChar8056:TryRectifyRot()
    if self._isDebugRectifyLogic then
        XLog.Debug("白龙修正逻辑：开始修正角度！")
    end
    local arSkills = self._angleRectifySkills
    local arRanges = self._angleRectifyConds

    -- 修正技能或者修正范围为空，不允许修正
    if arSkills == nil or arRanges == nil then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：角度修正参数有nil存在，修正中止！")
        end
        return
    end

    -- 修正技能或者修正范围任意长度为0，或者两者长度不相等，则不允许修正
    if #arSkills == 0 or #arRanges == 0 or #arSkills ~= #arRanges then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：角度修正参数有不合法内容存在，修正中止！")
        end
        return
    end

    -- 遍历所有修正技能，查找一个符合条件的，随后释放
    for i = 1, #self._angleRectifySkills do
        local isSatisfy = self:IsTarSatisfyAngleCond(self:GetSkillTarget(), arRanges[i], false)
        if isSatisfy then
            self._proxy:CastActionToTarget(self._uuid, arSkills[i], self:GetSkillTarget())

            -- 烦躁值增长
            local cost = self._angleRectifyCostTable[i]
            if cost == nil then cost = 0 end
            self._curRectifyIrritation = self._curRectifyIrritation + cost

            if self._isDebugRectifyLogic then
                XLog.Debug(string.format("白龙修正逻辑：找到合适的修正技能[%q]，烦躁值[%f / %f]",
                        arSkills[i], self._curRectifyIrritation, self._maxRectifyIrritation))
            end
            break
        end
    end
end

--- 尝试通过位移动作来接近或远离目标
--- @param isTooClose @ 是否距离过近，false则代表距离过远（调用这个函数，默认有距离问题）
--- @param disMin @ 最小距离
--- @param disMax @ 最大距离
function XChar8056:TryRectifyPos(isTooClose, curDis, disMin, disMax)
    if self._isDebugRectifyLogic then
        XLog.Debug("白龙修正逻辑：开始修正距离！")
    end

    local drSkills = self._disRectifySkills
    local drLengths = self._disRectifyConds

    --TODO: 距离修正技能
    -- 修正技能或者修正范围为空，不允许修正
    if drSkills == nil or drLengths == nil then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：距离修正参数有nil存在，修正中止！")
        end
        return
    end

    -- 修正技能或者修正范围任意长度为0，或者两者长度不相等，则不允许修正
    if #drSkills == 0 or #drLengths == 0 or #drSkills ~= #drLengths then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：距离修正参数有不合法内容存在，修正中止！")
        end
        return
    end

    -- 寻找修正长度绝对值最小的修正技能
    local drSkillIdx = -1
    local curMinAbsLength = math.huge
    for i = 1, #drSkills do
        local rectifyPredictDis = curDis + drLengths[i]
        local isPredictDisInRange = rectifyPredictDis >= disMin and rectifyPredictDis <= disMax
        local curAbsLength = math.abs(drLengths[i])
        if isPredictDisInRange and curAbsLength < curMinAbsLength then
            drSkillIdx = i
            curMinAbsLength = curAbsLength
        end
    end

    -- 如果有合适的直接释放
    if drSkillIdx > 0 then
        self._proxy:CastActionToTarget(self._uuid, drSkills[drSkillIdx], self:GetSkillTarget())

        -- 烦躁值增长
        local cost = self._disRectifyCostTable[drSkillIdx]
        if cost == nil then cost = 0 end
        self._curRectifyIrritation = self._curRectifyIrritation + cost

        if self._isDebugRectifyLogic then
            XLog.Debug(string.format(
                    "白龙修正逻辑: 选择技能[%d]进行修正，修正前距离[%f]，修正长度[%f]，修正后预测距离[%f]，烦躁值[%f / %f]",
                    drSkills[drSkillIdx], curDis, drLengths[drSkillIdx], curDis + drLengths[drSkillIdx],
                    self._curRectifyIrritation, self._maxRectifyIrritation))
        end
        return
    end

    -- 如果没有合适的修正技能，直接走过去，目前只能前走
    if isTooClose then
        -- 距离过近，触发向后走？
    else
        -- 距离过远，走过去！
        -- 追逐停止距离 = 最小距离 +（最大距离 - 最小距离）/ 1.3
        local stopDis = disMin + (disMax - disMin) / 1.3
        -- 开始追逐，停止追逐距离会被自动修正确保距离合法
        self:ChasingAggroTarget(stopDis)
    end
end
--endregion

--region 核心战斗系统：技能冷却系统
function XChar8056:InitCoreCombatCoolDownSystem()
    --- 技能冷却时间计时器
    self._skillCdTimers = {}
    for skillId, info in pairs(self._skillInfos) do
        self._skillCdTimers[skillId] = 0
    end
end

--- 更新：核心战斗系统 - 技能冷却系统
function XChar8056:UpdateCoreCombatCoolDownSystem(dt)
    for id, t in pairs(self._skillCdTimers) do
        self._skillCdTimers[id] = self._skillCdTimers[id] - dt
        --XLog.Debug(string.format("技能[%d]冷却[%f]", id, self._skillCdTimers[id]))
    end
end

--- 根据重置规则，重置所有技能CD
--- @param forceRefresh @ 无视重置规则
function XChar8056:RefreshSkillCD(forceRefresh)
    for skillId, info in pairs(self._skillInfos) do
        if forceRefresh or info[2] then
            self._skillCdTimers[skillId] = 0
        end
    end
end
--endregion

--region 核心战斗系统：多人弹刀系统(Obsolete，现已移植为程序功能)
--[[ DEMO 临时处理
function XChar8056:InitCoreCombatWrestleSystem()
    -- 多人弹刀/角力
    --- 是否在角力过程中
    self._isWrestling = false
    --- 多人弹刀/角力的交互目标
    self._multiDeflectTarget = 0
    --- 默认角力持续时间
    self._defaultWrestleHoldDuration = 5;
    --- 当前角力持续时间，超出这个时间的话角力视为失败
    self._curWrestleHoldDuration = 5;
    --- 角力期间，每次攻击延长的角力持续时间
    self._wrestleDurationExtendPerHit = 0.25;
    --- 多人弹刀计时器
    self._wrestleTimer = 0
    --- 角力开始的技能ID
    self._wrestleStartSkillId = 8005506
    --- 角力开始技能时长（决定何时开始衔接维持）
    self._wrestleStartEndTime = 1.433
    --- 角力维持技能ID
    self._wrestleHoldSkillId = 8005507
    --- 角力维持技能时长（决定何时开始再次播放，模拟Loop）
    self._wrestleHoldEndTime = 1.3
    --- 角力失败技能ID
    self._wrestleFailSkillId = 8005511
    --- 角力成功技能ID
    self._wrestleSuccessSkillId = 8005512

    self._deflectState = 0;
    --- 是否模拟角力（false则表示模拟弹刀，现在没法判断角色职业，只能切换模拟的内容）
    self._useWrestleLogic = true

    -- 模拟B和C支援状态
    self._canSimulateMultiDeflectSuccess = false
    self._isMultiDeflectSimulated = false
    self._canSimulateSup = false
    --- 模拟B和C支援状态，0表示未开始，1表示开始，2表示B完成支援
    self._testWrestleSupState = 0
    self._testWrestleTimer = 0
    self._testWrestleReactTime = 3
    self._testWrestleBSupTime = 2
    self._testWrestleCSupTime = 2.5

    -- 模拟角力延长
    self._canSimulateExtend = false
    self._testStartExtend = false
    self._testExtendTimer = 0
    self._testExtendInterval = 1.5

    -- 注册黑板键：角力位置
    self._proxy:RegisterBBSync(1, self._uuid, 800501)
    self._proxy:RegisterBBSync(1, self._uuid, 800502)
    self._proxy:RegisterBBSync(1, self._uuid, 800503)

    -- 调用SetNpcPosition模拟插值平移效果，用计时器控制频率防止服务器频繁同步
    -- 这个等正式功能做好后会删掉，现在仅用于快速出demo效果
    --- 插值移动更新频率
    self._lerpMoveInterval = 0.0165
    --- 插值移动更新频率计时器
    self._lerpMoveIntervalTimer = 0
    --- 是否在插值移动
    self._isLerpMoving = false
    --- 插值移动时间
    self._lerpMoveTime = 0
    --- 插值移动计时器
    self._lerpMoveTimer = 0
    -- 插值移动起始位置xyz
    self._lerpMoveStartPosX = 0
    self._lerpMoveStartPosY = 0
    self._lerpMoveStartPosZ = 0
    -- 插值移动结束位置xyz
    self._lerpMoveEndPosX = 0
    self._lerpMoveEndPosY = 0
    self._lerpMoveEndPosZ = 0
    --- 当前插值移动位置
    self._curLerpMovePos = nil
end
]]

--[[ DEMO 临时处理
--- 更新：核心战斗系统 - 多人弹刀角力
function XChar8056:UpdateCoreCombatMultiDeflectSystem(dt)
    -- 插值移动
    if self._isLerpMoving then
        if self._lerpMoveIntervalTimer <= 0 then
            self._lerpMoveIntervalTimer = self._lerpMoveInterval

            -- 插值位置
            local t = self:Clamp(self._lerpMoveTimer / self._lerpMoveTime, 0, 1)
            self._curLerpMovePos.x = self:InterpFloat(self._lerpMoveStartPosX, self._lerpMoveEndPosX, t, XChar8056.EInterpMode.EaseOutCubic)
            self._curLerpMovePos.y = self:InterpFloat(self._lerpMoveStartPosY, self._lerpMoveEndPosY, t, XChar8056.EInterpMode.EaseOutCubic)
            self._curLerpMovePos.z = self:InterpFloat(self._lerpMoveStartPosZ, self._lerpMoveEndPosZ, t, XChar8056.EInterpMode.EaseOutCubic)
            self._proxy:SetNpcPosition(self._multiDeflectTarget, self._curLerpMovePos)
        end

        -- 更新计时器，们
        self._lerpMoveIntervalTimer = self._lerpMoveIntervalTimer - dt
        self._lerpMoveTimer = self._lerpMoveTimer + dt

        -- 计时器到头了，结束
        if self._lerpMoveTimer >= self._lerpMoveTime then
            self._isLerpMoving = false
        end
    end

    -- 处理空中支援受击开始 -> 受击结束的逻辑
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005509) then
        if self._skillTimer >= 1.4 then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastAction(self._uuid, 8005510)
        end
    end

    -- 模拟B和C支援
    if self._testWrestleSupState ~= 0 then
        if self._testWrestleSupState == 1 and self._testWrestleTimer > self._testWrestleBSupTime then
            self._proxy:ApplyMagic(self._multiDeflectTarget, self._uuid, 1052024, 1)
            self._testWrestleSupState = 2
        end

        if self._testWrestleSupState == 2 and self._testWrestleTimer > self._testWrestleCSupTime then
            self._proxy:ApplyMagic(self._multiDeflectTarget, self._uuid, 1052025, 1)
            self._testWrestleSupState = 0
        end

        self._testWrestleTimer = self._testWrestleTimer + dt
    end

    -- 处理角力开始 -> 角力循环的逻辑
    if self._proxy:CheckNpcCurrentAction(self._uuid, self._wrestleStartSkillId) then
        if self._skillTimer >= self._wrestleStartEndTime then
            if self._deflectState == 1 then
                -- 播放角力循环
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToTarget(self._uuid, self._wrestleHoldSkillId, self._multiDeflectTarget)

                -- 撞击震屏幕
                self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 8005109)
                self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 8005110)

                -- 通知玩家也开始播循环
                self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 1000462, 1)

                -- 计算B玩家位置
                local rotatedPosOffsetForPlayerB = self:RotateVector2({ -4, 7 }, self._proxy:GetNpcRotation(self._uuid).y)
                local targetPosForPlayerB = self._proxy:GetNpcPosition(self._uuid)
                targetPosForPlayerB.x = targetPosForPlayerB.x + rotatedPosOffsetForPlayerB[1]
                targetPosForPlayerB.z = targetPosForPlayerB.z + rotatedPosOffsetForPlayerB[2]
                self._proxy:SetBBVector3(1, self._uuid, 800502, targetPosForPlayerB)

                -- 计算C玩家位置
                local rotatedPosOffsetForPlayerC = self:RotateVector2({ 3, 7 }, self._proxy:GetNpcRotation(self._uuid).y)
                local targetPosForPlayerC = self._proxy:GetNpcPosition(self._uuid)
                targetPosForPlayerC.x = targetPosForPlayerC.x + rotatedPosOffsetForPlayerC[1]
                targetPosForPlayerC.z = targetPosForPlayerC.z + rotatedPosOffsetForPlayerC[2]
                targetPosForPlayerC.y = targetPosForPlayerC.y + 5
                self._proxy:SetBBVector3(1, self._uuid, 800503, targetPosForPlayerC)

                -- 给其他玩家添加可QTE支援buff
                local players = self._proxy:GetPlayerNpcList()
                for k, player in ipairs(players) do
                    -- 排除正在角力的主目标
                    if player ~= self._multiDeflectTarget then
                        self._proxy:ApplyMagic(self._uuid, player, 1000452, 1)
                    end
                end

                self._wrestleTimer = 0
                self._curWrestleHoldDuration = self._defaultWrestleHoldDuration
                self._isWrestling = true
            elseif self._deflectState == 2 then

            end
        end
        return
    end

    -- 多人弹刀 多人弹刀成功 且 在反击动作种 且 到达攻击点
    if self._proxy:CheckBuffByKind(self._uuid, 1000454) and self._proxy:CheckNpcCurrentAction(self._uuid, 8005513) and self._skillTimer >= 3.767 then
        -- 移除BOSS角力成功标记
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000460, 1)
        -- 添加角力成功硬直时间buff
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005903, 1)
        -- 弹开硬直
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 8005504)
        -- slomo和镜头fov
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
        for i, player in ipairs(self._proxy:GetPlayerNpcList()) do
            if self._proxy:CheckNpcDistance(self._uuid, player, 16) then
                self._proxy:ApplyMagic(self._uuid, player, self._heavyReflectSlomo, 1)
                self._proxy:ApplyMagic(self._uuid, player, 8005402, 1)
            end
        end
        -- 解锁状态
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)

        -- 模拟B和C支援开始
        if self._canSimulateSup then
            self._testWrestleSupState = 1
            self._testWrestleTimer = 0
        end
    end

    if not self._isMultiDeflectSimulated and self._proxy:CheckNpcCurrentAction(self._uuid, 8005513) and self._skillTimer >= 2.8 and self._canSimulateMultiDeflectSuccess then
        self._proxy:ApplyMagic(self._multiDeflectTarget, self._uuid, 1000454, 1)

        local tarPos = self._proxy:GetNpcPosition(self._multiDeflectTarget)
        local tarRot = self._proxy:GetNpcRotation(self._multiDeflectTarget)
        local posOffset = self:RotateVector2({0, 3.5}, tarRot.y)
        tarPos.x = tarPos.x + posOffset[1]
        tarPos.z = tarPos.z + posOffset[2]
        self._proxy:GenerateNpc(1051, 1, tarPos, tarRot)
        self._isMultiDeflectSimulated = true
    end

    -- 角力期间逻辑
    if self._isWrestling then
        -- 角力期间，模拟延长效果
        if self._canSimulateExtend then
            if self._testExtendTimer >= self._testExtendInterval then
                self._testExtendTimer = 0
                self._proxy:ApplyMagic(self._multiDeflectTarget, self._uuid, 1052023, 1)
            end
            self._testExtendTimer = self._testExtendTimer + dt
        end

        -- 角力失败检测
        if self._wrestleTimer >= self._curWrestleHoldDuration then
            self._proxy:AbortAction(self._uuid, true)
            -- TODO: 这里适配白龙临时动作，从中途开始播了，以后应该是用不上这个的
            self._proxy:CastActionToTarget(self._uuid, self._wrestleFailSkillId, self._multiDeflectTarget)
            -- 移除：角力接收方标记
            self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 1000456, 1)
            -- 添加：角力失败标记
            self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 1000455, 1)
            -- 移除：角力发起方标记
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000457, 1)

            -- 移除所有人的可支援标记
            self:ApplyMagicToPlayers({1000458}, 1)

            -- 解锁状态
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)

            self._multiDeflectTarget = 0
            self._isWrestling = false
            return
        end

        -- 模拟3秒后有人响应
        if self._canSimulateMultiDeflectSuccess and self._wrestleTimer >= self._testWrestleReactTime and not self._proxy:CheckBuffByKind(self._uuid, 1000454) then
            self._proxy:ApplyMagic(self._multiDeflectTarget, self._uuid, 1000454, 1)
            return
        end

        -- 角力动作的循环播放
        if self._skillTimer >= self._wrestleHoldEndTime then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, self._wrestleHoldSkillId, self._multiDeflectTarget)
        end

        self._wrestleTimer = self._wrestleTimer + dt
    end
end
]]

--[[ DEMO 临时处理
---角力持续时间延长的逻辑，在受到伤害时调用
---@param magicId number @ 伤害magicId
function XChar8056:OnDamagedDuringWrestle(magicId, targetId)
    -- 角力流程里
    if self._isWrestling and magicId == 1052023 then
        -- 延长角力持续时间
        self._curWrestleHoldDuration = self._curWrestleHoldDuration + self._wrestleDurationExtendPerHit
        return
    end

    local isWrestlingSuccess = self._proxy:CheckBuffByKind(self._uuid, 1000454)
    if isWrestlingSuccess and magicId == 1052024 and self._useWrestleLogic then
        -- 移除BOSS角力成功标记
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000460, 1)
        -- 添加角力成功硬直时间buff
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005903, 1)
        -- 受击硬直
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, self._wrestleSuccessSkillId)

        -- 解锁状态
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)

        -- 模拟B和C支援开始
        if self._canSimulateSup then
            self._testWrestleSupState = 1
            self._testWrestleTimer = 0
        end
        return
    end

    local isInWrestleWeakState = self._proxy:CheckBuffByKind(self._uuid, 8005903)
    if isInWrestleWeakState then
        if magicId == 1052024 then
            -- B支援受击硬直
            --self:CastTenaBreakSkillBySrcPos(targetId, false)
            --XLog.Debug("B支援")
        end
        if magicId == 1052025 then
            -- C空中支援硬直
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastAction(self._uuid, 8005509)
            XLog.Debug("C支援")
        end
    end
end
]]

--[[ DEMO 临时处理
function XChar8056:MultiDeflectLogic(magicId, target)
    local hasGuardBuff = self._proxy:CheckBuffByKind(target, 105234)
    local hasGuardPointBuff = self._proxy:CheckBuffByKind(target, 105233)
    --- 0代表失败，1代表角力，2代表弹刀
    self._deflectState = 0

    -- 临时用七实防御buff作弹反条件
    if hasGuardPointBuff or hasGuardBuff then
        -- 伤害magic为多人弹刀magic, 开始角力流程
        if magicId == 8005039 then
            if self._useWrestleLogic then
                self._deflectState = 1
            else
                self._deflectState = 2
            end
        end
    end

    if self._deflectState ~= 0 then
        -- 设立目标为弹刀主交互目标
        self._multiDeflectTarget = target

        -- TODO: 锁状态
        if self._deflectState == 1 then
            -- 播放角力开始动作
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTargetEx(self._uuid, self._wrestleStartSkillId, self._multiDeflectTarget, 0, 2.067)

            -- 震屏
            self:DeflectScreenShakeEffect(self._multiDeflectTarget)

            -- 角力玩家插值移动
            local posOffset = { -1, 8.5 }
            local rotatedPosOffset = self:RotateVector2(posOffset, self._proxy:GetNpcRotation(self._uuid).y)
            local targetPos = self._proxy:GetNpcPosition(self._uuid)
            targetPos.x = targetPos.x + rotatedPosOffset[1]
            targetPos.z = targetPos.z + rotatedPosOffset[2]
            self._proxy:SetBBVector3(1, self._uuid, 800501, targetPos)
            self:StartLerpMoveMultiDeflectTarget(targetPos, 1)

        elseif self._deflectState == 2 then
            -- 弹刀特效
            self._proxy:LaunchMissile(self._uuid, target, 800500013, 1)

            -- 播放弹刀追击动作
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTargetEx(self._uuid, 8005513, self._multiDeflectTarget, 1.333, 4.633)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005904)

            -- 震屏
            self:DeflectScreenShakeEffect(self._multiDeflectTarget)

            -- 临时拉镜看效果
            --self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 8005451, 1)
            --self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 8005453, 1)

            -- 弹刀玩家插值移动
            local posOffset = { 0, 25 }
            local rotatedPosOffset = self:RotateVector2(posOffset, self._proxy:GetNpcRotation(self._uuid).y)
            local targetPos = self._proxy:GetNpcPosition(self._uuid)
            targetPos.x = targetPos.x + rotatedPosOffset[1]
            targetPos.z = targetPos.z + rotatedPosOffset[2]
            self._proxy:SetBBVector3(1, self._uuid, 800501, targetPos)
            self:StartLerpMoveMultiDeflectTarget(targetPos, 1.5)

            -- 计算B玩家位置
            local rotatedPosOffsetForPlayerB = self:RotateVector2({ 0, 12.5 }, self._proxy:GetNpcRotation(self._uuid).y)
            local targetPosForPlayerB = self._proxy:GetNpcPosition(self._uuid)
            targetPosForPlayerB.x = targetPosForPlayerB.x + rotatedPosOffsetForPlayerB[1]
            targetPosForPlayerB.z = targetPosForPlayerB.z + rotatedPosOffsetForPlayerB[2]
            self._proxy:SetBBVector3(1, self._uuid, 800502, targetPosForPlayerB)

            -- 计算C玩家位置
            local rotatedPosOffsetForPlayerC = self:RotateVector2({ 3, 10 }, self._proxy:GetNpcRotation(self._uuid).y)
            local targetPosForPlayerC = self._proxy:GetNpcPosition(self._uuid)
            targetPosForPlayerC.x = targetPosForPlayerC.x + rotatedPosOffsetForPlayerC[1]
            targetPosForPlayerC.z = targetPosForPlayerC.z + rotatedPosOffsetForPlayerC[2]
            targetPosForPlayerC.y = targetPosForPlayerC.y + 5
            self._proxy:SetBBVector3(1, self._uuid, 800503, targetPosForPlayerC)

            -- 给其他玩家添加可QTE支援buff
            local players = self._proxy:GetPlayerNpcList()
            for k, player in ipairs(players) do
                -- 排除正在角力的主目标
                if player ~= self._multiDeflectTarget then
                    self._proxy:ApplyMagic(self._uuid, player, 1000471, 1)
                end
            end
        else

        end

        -- 给目标加多人弹刀接收方buff
        self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 1000450, 1)
        -- 给自己加多人弹刀发起方buff
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000451, 1)

        -- 锁状态
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1)

        self._isMultiDeflectSimulated = false
        end
end
]]

--[[ DEMO 临时处理
function XChar8056:DeflectLogic(magicId, target)
    -- 临时用七实防御buff作弹反条件

    local hasGuardBuff = self._proxy:CheckBuffByKind(target, 105234)
    local hasGuardPointBuff = self._proxy:CheckBuffByKind(target, 105233)
    --XLog.Debug("目标ID: " .. tostring(target) ..  " 是否拥有弹刀buff: " .. tostring(hasGuardBuff or hasGuardPointBuff))
    local deflectSuccess = false
    if hasGuardPointBuff or hasGuardBuff then
        -- 右扫爪弹刀
        if magicId == 8005025 then
            self._proxy:LaunchMissile(self._uuid, target, 8005013, 8005013, 1)
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005503, target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._heavyReflectSlomo, 1)
            deflectSuccess = true
        end

        -- 左扫爪弹刀
        if magicId == 8005026 then
            self._proxy:LaunchMissile(self._uuid, target, 8005012, 8005012,  1)
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005502, target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._heavyReflectSlomo, 1)
            deflectSuccess = true
        end

        -- 左扫+起飞砸地
        if magicId == 8005028 then
            -- 左扫
            self._proxy:LaunchMissile(self._uuid, target, 8005012, 8005012,  1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lHandReflectParticle, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lightReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._lightReflectSlomo, 1)
            deflectSuccess = true
        end
        if magicId == 8005029 then
            -- 起飞砸地
            --self._proxy:LaunchMissile(self._uuid, target, 800500013, 1)
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005504, target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, 8005402, 1)
            deflectSuccess = true
        end

        -- 左刺弹刀
        if magicId == 8005030 then
            self._proxy:LaunchMissile(self._uuid, target, 8005012, 8005012, 1)
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005502, target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._heavyReflectSlomo, 1)
            deflectSuccess = true
        end

        -- 左右刺弹刀
        if magicId == 8005031 then
            -- 左刺
            self._proxy:LaunchMissile(self._uuid, target, 8005012, 8005012,  1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lHandReflectParticle, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lightReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._lightReflectSlomo, 1)
            deflectSuccess = true
        end
        if magicId == 8005032 then
            -- 右刺
            self._proxy:LaunchMissile(self._uuid, target, 8005013, 8005013,  1)
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005503, target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._heavyReflectSlomo, 1)
            deflectSuccess = true
        end

        -- 蓄力跳砸弹刀
        if magicId == 8005035 then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 8005504, target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, target, 8005402, 1)
            deflectSuccess = true
        end
    end

    -- 临时给玩家添加一个弹刀通知buff
    if deflectSuccess then
        self._proxy:ApplyMagic(self._uuid, target, 8005501, 1)

        -- 弹刀震屏效果
        self:DelayCall("DeflectScreenShakeEffect", 0.2, target)
    end
end
]]

--[[ DEMO 临时处理
function XChar8056:DeflectScreenShakeEffect(target)
    -- 弹刀震屏效果
    self._proxy:ApplyMagic(self._uuid, target, 8005107, 1)
    self._proxy:ApplyMagic(self._uuid, target, 8005108, 1)
end
]]

--[[ DEMO 临时处理
function XChar8056:StartLerpMoveMultiDeflectTarget(targetPos, totalTime)
    if not self._proxy:CheckNpc(self._multiDeflectTarget) then
        return
    end

    self._curLerpMovePos = self._proxy:GetNpcPosition(self._multiDeflectTarget)
    self._lerpMoveStartPosX = self._curLerpMovePos.x
    self._lerpMoveStartPosY = self._curLerpMovePos.y
    self._lerpMoveStartPosZ = self._curLerpMovePos.z
    self._lerpMoveEndPosX = targetPos.x
    self._lerpMoveEndPosY = targetPos.y
    self._lerpMoveEndPosZ = targetPos.z

    self._lerpMoveTimer = 0
    self._lerpMoveTime = totalTime

    self._lerpMoveIntervalTimer = 0

    self._isLerpMoving = true;
end
]]
--endregion

--region Debug系统
function XChar8056:InitDebugSystem()
    -- 测试用tick（开始运行后，以固定频率调用的测试函数）
    --- 测试用tick更新频率
    self._testTickInterval = 4
    --- 测试用tick计时器
    self._testTickTimer = 0
    -- 测试用delay（开始运行后，固定延迟一定时间后执行一次的函数）
    --- 测试用delay延迟时间
    self._testDelayTime = 2
    --- 测试用delay计时器
    self._testDelayTimer = 0
    --- 测试用delay是否已经触发
    self._hasTestDelayTriggered = false

    -- 调试参, true为开启
    --- 是否调试核心战斗逻辑
    self._isDebugBattleLogic = false
    --- 是否调试修正逻辑
    self._isDebugRectifyLogic = false
    --- 是否调试追逐逻辑
    self._isDebugChasingLogic = false
    --- 是否调试OD值
    self._isDebugODValue = false
    --- 是否调试韧性值
    self._isDebugTenacity = false
end

function XChar8056:UpdateDebugSystem(dt)
    if self._testTickTimer >= self._testTickInterval then
        -- 具体测试逻辑
        self:DebugTickLogic()
        self._testTickTimer = 0
    end
    self._testTickTimer = self._testTickTimer + dt


    -- 测试用delay
    if not self._hasTestDelayTriggered then
        if self._testDelayTimer >= self._testDelayTime then
            self:DebugDelayLogic()
            self._hasTestDelayTriggered = true
        end
        self._testDelayTimer = self._testDelayTimer + dt
    end
end

function XChar8056:DebugTickLogic()
    --local player = self._proxy:GetPlayerNpcList()[1]
    --self._proxy:LaunchMissile(self._uuid, player, 8005118, 8005102)
end

---开始运行后，固定延迟一定时间后执行一次的函数
function XChar8056:DebugDelayLogic()
end
--endregion

--region Unity事件
function XChar8056:HandleLuaEvent(eventType, eventArgs)
    if eventType == EFightLuaEvent.RelinkSetAIActivate then
        if eventArgs.NpcUUid == self._uuid then
            self:SetIsAiActivated(eventArgs.IsActivated)
        end
    end
end

function XChar8056:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- OD吼锁韧性
    if skillId == 8005011 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000467, 1) -- 锁韧性
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断
    end

    -- 老大招解锁韧性 和 OD
    if skillId == 8005055 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1) -- 锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断

        -- 大招镜头
        self:ApplyMagicToPlayers({8005455}, 1)
        --[[
        for index, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
            self._proxy:ApplyMagic(self._uuid, playerId, 8005455, 1) -- 镜头拉远
        end
        ]]

        -- 大招激光激活
        self._ultraRayTimer = 0
        self._isUltraCameraModified = false
        self._isUltraRayStart = true
    end

    -- DPS检测
    if skillId == self._ultraBeginActionId then
        self:ApplyMagicToPlayers({8005466}, 1) -- 临时镜头

        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1) -- 锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断
    end

    if skillId == self._ultraEndActionId then
        self._isUltraEndCameraUnlocked = false
        self._isUltraEndCameraReLocked = false
        self._isUltraEndLaserCameraApplied = false
        self._isUltraEndExplodeCameraApplied = false

        -- 大招激光激活
        self._ultraRayTimer = 0
        self._isUltraCameraModified = false
        self._isUltraRayStart = true
    end

    -- 召唤浮游炮镜头
    if skillId == 8005041 then
        self:ApplyMagicToPlayers({8005460, 8005461}, 1)
    end

    -- 全场喷火
    if skillId == 8005518 then
        self._isFireUltraPreActionAborted = false

        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1) -- 锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断
    end

    self._skillTimer = 0
end

function XChar8056:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then return end

    -- OD吼解锁韧性
    if skillId == 8005011 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1) -- 解锁韧性
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断
    end

    -- 老大招解锁韧性 和 OD
    if skillId == 8005055 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断
    end

    -- DPS检测锁OD锁削韧
    if skillId == self._ultraEndActionId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断
    end

    if skillId == 8005301 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断
    end

    if skillId == 8005053 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断
    end

    self._skillTimer = 0
end

function XChar8056:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        return
    end

    -- OD Break Loop期间受击
    --[[
    if self:GetIsODBreakLooping() then
        self:CastODBreakHitActionBySrcPos(launcherId)
    end
    ]]

    -- DPS期间受击逻辑
    if self._proxy:CheckBuffByKind(self._uuid, 8005070) then
        -- 受击特效
        self._proxy:LaunchMissile(self._uuid, self._uuid, 8005112, 8005105)

        -- 检测护盾值
        if self._proxy:GetNpcProtector(self._uuid) <= 0 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005082, 1)
            self:ApplyMagicToPlayers({8005467}, 1) -- 移除临时镜头
        end
    end

    -- 特殊受击
    if GameplayTag.CSMatchAnyTag(magicTags, {EGameplayTag.Magic_RelinkDamage_HitType_Ultra}) then
        if not self._proxy:CheckBuffByKind(self._uuid, self._immuUltraAbortMagicId) then
            self:CastTenaBreakSkillBySrcPos(launcherId, false)
        end
    end
    if GameplayTag.CSMatchAnyTag(magicTags, {EGameplayTag.Magic_RelinkDamage_HitType_Break}) then
        if self._proxy:CheckBuffByKind(self._uuid, self._breakMagicId) then
            self:CastBreakSkill(true)
        end
    end
end

function XChar8056:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end

    if buffId == 1052306 then
        self._proxy:ApplyMagic(self._uuid, casterNpcUUID, 1052255, 1)
    end
    if buffId == 1052307 then
        self._proxy:ApplyMagic(self._uuid, casterNpcUUID, 1052256, 1)
    end

    -- 角力停止逻辑
    if buffId == 1000454 then
        -- 停止角力
        self._isWrestling = false
    end

    -- 重置韧性
    if buffId == 8005040 then
        self._proxy:SetNpcBreakGauge(self._uuid, 2000, ENpcBreakStateCondition.Break)
    end
end

function XChar8056:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end

    if buffId == 8005903 then
        -- 结束角力流程

        -- 移除：角力接收方标记
        self._proxy:ApplyMagic(self._uuid, self._multiDeflectTarget, 1000456, 1)
        -- 移除：角力发起方标记
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000457, 1)
        self._multiDeflectTarget = 0
    end

    -- 多人弹刀伤害点
    if buffId == 8005904 then
        if not self._proxy:CheckNpcCurrentAction(self._uuid, 8005513) then
            return
        end

        if self._proxy:CheckBuffByKind(self._uuid, 1000454) then
            -- 移除BOSS角力成功标记
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000460, 1)
            -- 添加角力成功硬直时间buff
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005903, 1)
            -- 取消拉镜
            self._proxy:ApplyMagic(self._multiDeflectTarget, self._multiDeflectTarget, 8005452)
            self._proxy:ApplyMagic(self._multiDeflectTarget, self._multiDeflectTarget, 8005454)
            -- 受击硬直
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastAction(self._uuid, self._wrestleSuccessSkillId)
        end
    end

    -- 决定DPS检测是否通过
    if buffId == 8005070 then
        if self._proxy:GetNpcProtector(self._uuid) > 0 then
            -- 没通过，惩罚技能，启动！
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToPosition(self._uuid, self._ultraEndActionId, self._battleSceneCenter)
        else
            -- 通过了直接Break
            -- TODO：直接Break没功能，先放个特殊动作
            self._proxy:DestroyAllMissileDependOnLauncher(self._uuid)

            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastAction(self._uuid, 8005053)

            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005313, 1)
            self:ApplyMagicToPlayers({8005313}, 1)

            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        end
        self._proxy:LaunchMissile(self._uuid, self._uuid, 8005113, 8005106)
    end
end

function XChar8056:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    -- 确保自身破韧
    if targetUUID ~= self._uuid then
        return
    end

    -- 根据目标位置播破韧动作
    -- self:CastTenaBreakSkillBySrcPos(launcherUUID, false)
    self:CastBreakSkill(false)
    -- 破韧持续时间，临时用buff做
    self._proxy:ApplyMagic(self._uuid, self._uuid, 8005901, 1)
    -- 传递可放破韧技的通知(暂时给所有人上)
    self:ApplyMagicToPlayers({8005902}, 1)

    -- 调试打印
    if self._isDebugBattleLogic then
        XLog.Debug("白龙核心战斗：触发破韧技！")
    end
end

function XChar8056:OnNpcOverDriveFull(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end

    --self:ChangeState(XChar8056.EBattleState.ODState)
end

function XChar8056:OnNpcODBreakAfter(targetUUID)
    if self._isDebugBattleLogic then
        XLog.Debug("白龙核心战斗：OD Break！")
    end

    -- 状态机触发
    XLog.Debug("测试状态机：Break触发")
    self._fightSM:SetTrigger(self._fightSMTriggers.enterBreak)
end

function XChar8056:OnNpcODExitBreakAfter(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end

    -- 状态机触发
    self._fightSM:SetTrigger(self._fightSMTriggers.exitBreak)
end

function XChar8056:BeforeDamageCalc(eventArgs)
    Base.BeforeDamageCalc(self, eventArgs)
    if self._uuid ~= eventArgs.Launcher or self._uuid == eventArgs.Target then
        return
    end

    -- 扫爪+拍地，扫爪卡肉
    if eventArgs.Id == 8005023 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005301, 1)
    end

    if eventArgs.Id == 8005030 then
        for k, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
            if self:IsPlayerSup(playerId) then
                self._proxy:ApplyMagic(self._uuid, playerId, 8005908, 1)
            end
        end
    end
end

function XChar8056:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    Base.OnNpcBeforeTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    -- 非技能目标不能弹刀
    if counterNpcUUID ~= self:GetSkillTarget() then
        return
    end

    local isSustain = GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_Sustain}) or GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Light})
    -- 不打断拼刀(触发盒为sustain或反制盒为light)
    if isSustain then
        -- 通用逻辑部分
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._lightReflectSlomo, 1)    -- 弱顿帧（对自己）
        self._proxy:ApplyMagic(self._uuid, counterNpcUUID, self._lightReflectSlomo, 1)-- 弱顿帧（对目标）

        -- 根据子弹ID的定制化表现
        -- 弹刀特效
        if triggerMissileTemplateId == 8005064 or triggerMissileTemplateId == 8005067 then
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005012,  1)
        end
        return
    end

    -- 打断拼刀(触发盒为interrupt)
    local isInterrupt = GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_Interrupt})
    if isInterrupt then
        -- 根据子弹ID的定制化表现
        -- 正面弹
        if triggerMissileTemplateId == 8005065 or triggerMissileTemplateId == 8005069 then
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005403, 1)     -- FOV
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005458, 1)     -- 镜头抬升
            self._proxy:AbortAction(self._uuid, true)                                   -- 打断动作
            self._proxy:CastActionToTarget(self._uuid, 8005504, counterNpcUUID)   -- 弹刀动作
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005317, 1)     -- 自身缓速
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005318, 1)     -- 目标缓速
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005118, 8005159,  1)
            -- 左弹
        elseif triggerMissileTemplateId == 8005063 or triggerMissileTemplateId == 8005066 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005307, 1)      -- 强顿帧（对自己）
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005308, 1)  -- 强顿帧（对目标）
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005490, 1)  -- FOV
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005459, 1)  -- 镜头抬升
            self:DelayCall("ForceCastActionToTarget", 0.3, 8005502, counterNpcUUID)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005012,  1)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005158,  1)
            -- 右弹
        elseif triggerMissileTemplateId == 8005062 or triggerMissileTemplateId == 8005068 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005307, 1)      -- 强顿帧（对自己）
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005308, 1)  -- 强顿帧（对目标）
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005490, 1)  -- FOV
            self._proxy:ApplyMagic(self._uuid, counterNpcUUID, 8005459, 1)  -- 镜头抬升
            self:DelayCall("ForceCastActionToTarget", 0.3, 8005503, counterNpcUUID)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005013, 8005013,  1)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005158,  1)
        end
        return
    end

    local isMulti = GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_MultiInteract}) and GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Heavy})
    if isMulti then
        -- 角力逻辑 & 多人弹刀逻辑
        self._proxy:AbortAction(self._uuid, true)
        if self:IsPlayerTank(counterNpcUUID) then
            self:SetIsInWrestleState(true)

            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1) -- 锁OD
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断

            -- 移除所有角力前攻击镜头
            self:ApplyMagicToPlayers({8005481}, 1)
            -- 角力
            self._proxy:CastWrestle(self._uuid, counterNpcUUID, 800501)
        else
            -- 移除所有角力前攻击镜头
            self:ApplyMagicToPlayers({8005481}, 1)
            -- 多人弹刀
            self._proxy:CastMultiParry(self._uuid, counterNpcUUID, 800501)
            return
        end
    end
end

function XChar8056:OnNpcAfterTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcAfterTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end

function XChar8056:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID, succeed)
    Base.OnNpcWrestleStart(self, launcherNpcUUID, targetNpcUUID, succeed)

    if launcherNpcUUID == self._uuid and not succeed then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断

        -- 移除手发光
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005207, 1)

        self:SetIsInWrestleState(false)
    end
end

function XChar8056:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self, launcherNpcUUID, targetNpcUUID)
    if launcherNpcUUID == self._uuid then
        self:SetIsInWrestleState(false)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断

        -- 移除手发光
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005207, 1)
    end
end

function XChar8056:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self, launcherNpcUUID, targetNpcUUID)
    if launcherNpcUUID == self._uuid then
        self:SetIsInWrestleState(false)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断

        -- 移除手发光
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005207, 1)
    end
end

function XChar8056:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
end
--endregion

--region 工具函数
function XChar8056:IsPosSatisfyAngleCond(targetPos, angleCond)
    -- 如果条件为空则直接满足
    if #angleCond == 0 then
        return true
    end

    local isSatisfy = false
    -- 便利所有条件，只要满足任意一个角度条件就算成功
    for k, angleSet in ipairs(angleCond) do
        if #angleSet >= 2 then
            local from = angleSet[1]
            local to = angleSet[2]
            isSatisfy = isSatisfy or self:CheckPosInAngle(targetPos, from, to)
        end

        -- 满足条件直接跳出
        if isSatisfy then
            break
        end
    end

    return isSatisfy
end

--- 目标与自身夹角是否满足角度条件table（[角度条件table]为一个数组，其中每一个[角度条件]的结构为{[起始角度from]，[到达角度to]}的区间）
--- @param targetUUID number @目标UUID
--- @param angleCond @角度条件table
--- @return boolean @是否满足角度条件
function XChar8056:IsTarSatisfyAngleCond(targetUUID, angleCond)
    local targetPos = self._proxy:GetNpcPosition(targetUUID)
    return self:IsPosSatisfyAngleCond(targetPos, angleCond)
end

--- 给所有玩家添加效果
--- @param magicIds table @ magicId数组
--- @param level number @ level等级
function XChar8056:ApplyMagicToPlayers(magicIds, level)
    for k, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
        for idx, magicId in ipairs(magicIds) do
            self._proxy:ApplyMagic(self._uuid, playerId, magicId, level)
        end
    end
end

--- 获取仇恨列表内，除了当前仇恨目标以外的所有玩家
function XChar8056:GetNonAggroPlayerList()
    local players = self._proxy:GetPlayerNpcList()
    local results = {}
    for k, player in ipairs(players) do
        if self._proxy:CheckNpcInThreatList(self._uuid, player) and player ~= self._curAggroTarUUID then
            table.insert(results, player)
        end
    end
    return results
end

--- 检测玩家是否为坦克位
function XChar8056:IsPlayerTank(playerId)
    return self._proxy:CheckBuffByKind(playerId, 1000487)
end

--- 检测玩家是否为输出位
function XChar8056:IsPlayerCarry(playerId)
    return self._proxy:CheckBuffByKind(playerId, 1000486)
end

--- 检测玩家是否为奶/支援位
function XChar8056:IsPlayerSup(playerId)
    return self._proxy:CheckBuffByKind(playerId, 1000488)
end

function XChar8056:ForceCastActionToTarget(actionId, counterNpcUUID)
    self._proxy:AbortAction(self._uuid, true)                                   -- 打断动作
    self._proxy:CastActionToTarget(self._uuid, actionId, counterNpcUUID)   -- 动作
end
--endregion

--region 数学
--- 将val的值限制在min和max之间，随后返回
--- @param val number @ 需要限制的值
--- @param min number @ 区间最小值
--- @param max number @ 区间最大值
--- @return number @ 限制后的值
function XChar8056:Clamp(val, min, max)
    -- 任意参数不为数字类型，则直接返回原值
    if type(val) ~= "number" or type(min) ~= "number" or type(max) ~= "number" then
        return val
    end

    -- min 如果大于 max，则直接返回原值
    if min > max then
        return val
    end

    -- 限制值后返回
    if val < min then
        return min
    elseif val > max then
        return max
    else
        return val
    end
end

function XChar8056:CheckPosInAngle(pos, from, to)
    -- 角度参数合法性检测
    if from > to then
        return false
    end
    if math.abs(from) > 180 or math.abs(to) > 180 then
        return false
    end

    -- 如果差大于360度，则直接返回true
    if (to - from) >= 360 then
        return true
    end

    -- 对于from小于0，to大于0的进行区间拆分
    local angleList
    if from < 0 and to > 0 then
        angleList = {{from, 0}, {0, to}}
    else
        angleList = {{from, to}}
    end

    -- 获取自身位置和目标位置
    local sourcePosVec3 = self._proxy:GetNpcPosition(self._uuid)
    local targetPos = { pos.x, pos.z }
    local sourcePos = { sourcePosVec3.x, sourcePosVec3.z }

    -- 计算前方和右方的方向向量，以及指向目标的方向向量
    local forwardDir = self:NormalizeVector2(self:RotateVector2({ 0, 1 }, self._proxy:GetNpcRotation(self._uuid).y))
    local rightDir = self:NormalizeVector2(self:RotateVector2(forwardDir, 90))
    local targetDir = self:NormalizeVector2(self:SubtractVector2(targetPos, sourcePos))

    -- 检测左右
    local isIn = false
    for k, v in ipairs(angleList) do
        -- 点乘
        local forwardDot = self:DotProduct(forwardDir, targetDir)
        local rightDot = self:DotProduct(rightDir, targetDir)
        --XLog.Debug(string.format("是否在右侧: [%q]", rightDot > 0))

        -- 检测是否满足左右条件
        if (v[2] <= 0 and rightDot <= 0) or (v[1] >= 0 and rightDot >= 0) then
            local absAngleMin = math.abs(v[1])
            local absAngleMax = math.abs(v[2])

            -- 如果为左侧的话，负数绝对值对调
            if v[2] <= 0 then
                absAngleMin, absAngleMax = absAngleMax, absAngleMin
            end

            -- 判断夹角是否在区间内
            local angleBtw = math.deg(math.acos(forwardDot))
            if angleBtw >= absAngleMin and angleBtw <= absAngleMax then
                isIn = true
                break
            end
        end
    end

    return isIn
end

--- 计算目标是否在角度区间内（判断背后扇形时拆开判断，例如背后60度夹角，则调用两次，第一次-180 -150, 第二次150 180）
--- @param targetUUID @ 目标UUID
--- @param from number @ 最小值，合法参数区间[-180, 180]
--- @param to number @ 最大值，合法参数区间[-180, 180]
function XChar8056:CheckTargetInAngle(targetUUID, from, to)
    local targetPos = self._proxy:GetNpcPosition(targetUUID)
    return self:CheckPosInAngle(targetPos, from, to)
end

--- 旋转一个二维向量（这里用于计算XZ平面的旋转，即Y轴旋转）
--- @param vector @ 二维向量table
--- @param deg @ 旋转角度
--- @return @ 旋转后的向量
function XChar8056:RotateVector2(vector, deg)
    -- 构建旋转矩阵
    -- unity为顺时针旋转，这里角度取反
    local radian = math.rad(-deg)
    local cos = math.cos(radian)
    local sin = math.sin(radian)

    -- z = forward backward纵轴，x = left right横轴
    local x = vector[1]
    local z = vector[2]

    -- 应用旋转矩阵
    local rotatedX = x * cos - z * sin
    local rotatedZ = x * sin + z * cos

    return {rotatedX, rotatedZ}
end

--- 二维向量取模（长度）
function XChar8056:GetVector2Magnitude(vector)
    return math.sqrt(vector[1]^2 + vector[2]^2)
end

--- 二维向量归一化
function XChar8056:NormalizeVector2(vector)
    local mag = self:GetVector2Magnitude(vector)
    return { vector[1] / mag, vector[2] / mag }
end

--- 二维向量点乘
function XChar8056:DotProduct(vectorA, vectorB)
    return vectorA[1] * vectorB[1] + vectorA[2] * vectorB[2]
end

--- 二维向量减法
function XChar8056:SubtractVector2(vectorA, vectorB)
    return { vectorA[1] - vectorB[1], vectorA[2] - vectorB[2] }
end

--- 二维向量加法
function XChar8056:AddVector2(vectorA, vectorB)
    return { vectorA[1] + vectorB[1], vectorA[2] + vectorB[2] }
end

--- 浮点数插值
--- @param u number @ 起始值
--- @param v number @ 最终值
--- @param t number @ 插值位置（0 - 1之间）
--- @param interpMode @ 插值类型
function XChar8056:InterpFloat(u, v, t, interpMode)
    if interpMode == XChar8056.EInterpMode.EaseOutCubic then
        t = 1 - (1 - t)^3
    end

    return u * (1 - t) + v * t
end
--endregion

--region 技能表现相关杂项
function XChar8056:ForceShowAllFinFunnel()
    local removeFunnelMagicTable = {8005043, 8005044, 8005045, 8005046, 8005047, 8005048, 8005051, 8005051 }
    for index, magicId in ipairs(removeFunnelMagicTable) do
        self._proxy:ApplyMagic(self._uuid, self._uuid, magicId)
    end
end

--- 大招激光更新逻辑
function XChar8056:UltraRayUpdateLogic(dt)
    -- 逻辑阻断
    if not self._isUltraRayStart then
        return
    end

    -- 更新计时器
    self._ultraRayTimer = self._ultraRayTimer + dt

    -- 逻辑结束
    if self._ultraRayTimer >= self._ultraRayStopTime then
        self._isUltraRayStart = false
        return
    end

    -- 开始延迟
    if self._ultraRayTimer <= self._ultraRayStartTime then
        return
    end


    self._ultraRayIntervalTimer = self._ultraRayIntervalTimer - dt
    -- 小于0则执行一次子弹逻辑
    if self._ultraRayIntervalTimer <= 0 then
        -- 确定是否对玩家释放，计算目标点
        local isCastToPlayer = self._proxy:Random(1, 100) < (self._ultraRayPickPlayerPossibility * 100)
        local isCastToPlayerSuccess = true
        local launchPos = nil
        local rndXOffset, rndZOffset = 0, 0
        local targetPos = nil
        if isCastToPlayer then
            local rndPlayerId = self:GetValueByListRandom(self._proxy:GetPlayerNpcList())
            -- 玩家不合法的话标记为释放失败，本次更改为对随机位置释放
            if rndPlayerId == nil or rndPlayerId == 0 or not self._proxy:CheckNpc(rndPlayerId) then
                isCastToPlayerSuccess = false
            else
                rndXOffset = self._proxy:Random(-100, 100) * self._ultraRayPosOffsetRange[1] / 100
                rndZOffset = self._proxy:Random(-100, 100) * self._ultraRayPosOffsetRange[2] / 100
                targetPos = self._proxy:GetNpcPosition(rndPlayerId)
                targetPos.x = targetPos.x + rndXOffset
                targetPos.y = self._battleSceneCenter.y
                targetPos.z = targetPos.z + rndZOffset
            end
        end

        -- 朝随机位置，计算目标点
        if not isCastToPlayer or not isCastToPlayerSuccess then
            rndXOffset = self._proxy:Random(-100, 100) * self._ultraRayRandomPosRange[1] / 100
            rndZOffset = self._proxy:Random(-100, 100) * self._ultraRayRandomPosRange[2] / 100
            targetPos = {x = self._battleSceneCenter.x + rndXOffset, y = self._battleSceneCenter.y, z = self._battleSceneCenter.z + rndZOffset }
        end

        targetPos.y = targetPos.y + 0.2
        launchPos = targetPos

        -- 发射子弹
        self._proxy:LaunchMissileFromPosToPos(self._uuid, self._ultraRayMissileLaunchId, self._ultraRayMissileId, launchPos, targetPos, 1)

        -- 刷新计时器
        local rndIntervalVariant = self._proxy:Random(1, 100) / 100 * (self._ultraRayIntervalRange[2] - self._ultraRayIntervalRange[1])
        self._ultraRayIntervalTimer = self._ultraRayIntervalRange[1] + rndIntervalVariant
    end


    self._ultraPoissonDiskTimer = self._ultraPoissonDiskTimer - dt
    if self._ultraPoissonDiskTimer <= 0 then
        local poissonDiskPoints = self._proxy:PoissonDiscPoints(self._ultraPoissonDiskWidth, self._ultraPoissonDiskHeight, self._ultraPoissonDiskRadius)
        -- 有效性检测
        local isValid = poissonDiskPoints ~= nil and
                #poissonDiskPoints > 0 and
                #poissonDiskPoints % 2 == 0

        if isValid then
            --[[
            local xFixedOffset = self._ultraPoissonDiskWidth / 2
            local zFixedOffset = self._ultraPoissonDiskHeight / 2
            for xIndex = 1, #poissonDiskPoints, 2 do
                local zIndex = xIndex + 1

                local targetPos = { x = self._battleSceneCenter.x + poissonDiskPoints[xIndex] - xFixedOffset,
                y = self._battleSceneCenter.y,
                z = self._battleSceneCenter.z + poissonDiskPoints[zIndex] - zFixedOffset}
                targetPos.y = targetPos.y + 0.2

                -- 发射子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid, self._ultraRayMissileLaunchId, self._ultraRayMissileId, targetPos, targetPos, 1)
            end
            ]]
            self._ultraPoissonDiskPerInterval = self._ultraPoissonDiskInterval / #poissonDiskPoints
            self._ultraPoissonDiskPerCount = 0
            self._ultraPoissonDiskPoints = poissonDiskPoints
        end

        -- 刷新计时器
        self._ultraPoissonDiskTimer = self._ultraPoissonDiskInterval
    end

    self._ultraPoissonDiskPerTimer = self._ultraPoissonDiskPerTimer - dt
    if self._ultraPoissonDiskPerTimer <= 0 and self._ultraPoissonDiskPoints ~= nil then
        if self._ultraPoissonDiskPerCount < #self._ultraPoissonDiskPoints - 1 then
            local xFixedOffset = self._ultraPoissonDiskWidth / 2
            local zFixedOffset = self._ultraPoissonDiskHeight / 2
            local xIndex = self._ultraPoissonDiskPerCount * 2 + 1
            local zIndex = xIndex + 1

            local targetPos = { x = self._battleSceneCenter.x + self._ultraPoissonDiskPoints[xIndex] - xFixedOffset,
                                y = self._battleSceneCenter.y,
                                z = self._battleSceneCenter.z + self._ultraPoissonDiskPoints[zIndex] - zFixedOffset}
            targetPos.y = targetPos.y + 0.2

            -- 发射子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid, self._ultraRayMissileLaunchId, self._ultraRayMissileId, targetPos, targetPos, 1)

            self._ultraPoissonDiskPerCount = self._ultraPoissonDiskPerCount + 1
            self._ultraPoissonDiskPerTimer = self._ultraPoissonDiskPerInterval
        end
    end
end
--endregion

--region 黑板变量网络同步
--- 将同步变量键注册至黑板
function XChar8056:RegSyncVar(key)
    self._proxy:RegisterBBSync(self._syncDomain, self._uuid, key)
end

--- 将同步变量键从黑板取消注册
function XChar8056:UnregSyncVar(key)
    self._proxy:UnregisterBBSync(self._syncDomain, self._uuid, key)
end

--- 初始化同步布尔，如果已经存在于服务器，则更新本端值，否则将本端值同步至服务器
--- @param key number @ 黑板键
--- @return bool @ 是否已经存在于服务器
function XChar8056:InitSyncBool(key)
    local hasSyncVar, syncVal = self:GetSyncBool(key)
    if hasSyncVar then
        self._syncVarLocalVals[key] = syncVal
        return true
    else
        -- 没黑板键，执行注册
        local localVal = self._syncVarLocalVals[key]
        self:RegSyncVar(key)
        self:SetSyncBool(key, localVal)
        return false
    end
end

--- 初始化同步整数，如果已经存在于服务器，则更新本端值，否则将本端值同步至服务器
--- @param key number @ 黑板键
--- @return bool @ 是否已经存在于服务器
function XChar8056:InitSyncInt(key)
    local hasSyncVar, syncVal = self:GetSyncInt(key)
    if hasSyncVar then
        self._syncVarLocalVals[key] = syncVal
        return true
    else
        -- 没黑板键，执行注册
        local localVal = self._syncVarLocalVals[key]
        self:RegSyncVar(key)
        self:SetSyncInt(key, localVal)
        return false
    end
end

--- 获取同步布尔
function XChar8056:GetSyncBool(key)
    local hasSyncVar, val = self._proxy:TryGetBBBoolean(self._syncDomain, self._uuid, key)
    return hasSyncVar, val
end

--- 设置同步布尔
function XChar8056:SetSyncBool(key, val)
    self._proxy:SetBBBoolean(self._syncDomain, self._uuid, key, val)
end

--- 获取同步整数
function XChar8056:GetSyncInt(key)
    local hasSyncVar, val = self._proxy:TryGetBBInt(self._syncDomain, self._uuid, key)
    return hasSyncVar, val
end

--- 设置同步整数
function XChar8056:SetSyncInt(key, val)
    self._proxy:SetBBInt(self._syncDomain, self._uuid, key, val)
end
--endregion

--region 快速get和set本地网络同步变量, get本端获取，set时同步至服务器
function XChar8056:GetIsAiActivated()
    return self._syncVarLocalVals[self._syncKeys.isAiActivated]
end

function XChar8056:SetIsAiActivated(val)
    local key = self._syncKeys.isAiActivated
    self._syncVarLocalVals[key] = val
    self:SetSyncBool(key, val)
end

function XChar8056:GetIsInWrestleState()
    return self._syncVarLocalVals[self._syncKeys.isInWrestleState]
end

function XChar8056:SetIsInWrestleState(val)
    local key = self._syncKeys.isInWrestleState
    self._syncVarLocalVals[key] = val
    self:SetSyncBool(key, val)
end

function XChar8056:GetBattleLoopIdx()
    return self._syncVarLocalVals[self._syncKeys.battleLoopIdx]
end

function XChar8056:SetBattleLoopIdx(val)
    local key = self._syncKeys.battleLoopIdx
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end

function XChar8056:GetCurSeqIdx()
    return self._syncVarLocalVals[self._syncKeys.curSeqIdx]
end

function XChar8056:SetCurSeqIdx(val)
    local key = self._syncKeys.curSeqIdx
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end

function XChar8056:GetNextSeqIdx()
    return self._syncVarLocalVals[self._syncKeys.nextSeqIdx]
end

function XChar8056:SetNextSeqIdx(val)
    local key = self._syncKeys.nextSeqIdx
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end

function XChar8056:GetCurSkillId()
    return self._syncVarLocalVals[self._syncKeys.curSkillId]
end

function XChar8056:SetCurSkillId(val)
    local key = self._syncKeys.curSkillId
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end

function XChar8056:GetCurComboId()
    return self._syncVarLocalVals[self._syncKeys.curComboId]
end

function XChar8056:SetCurComboId(val)
    local key = self._syncKeys.curComboId
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end

function XChar8056:GetFightStateId(val)
    local key = self._syncKeys.fightStateId
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end

function XChar8056:SetFightStateId(val)
    local key = self._syncKeys.fightStateId
    self._syncVarLocalVals[key] = val
    self:SetSyncInt(key, val)
end
--endregion

--region 状态机
function XChar8056:InitFightStateMachine()
    -- 状态机
    self:InitSyncInt(self._syncKeys.fightStateId)

    self._fightSMTriggers =
    {
        activate = 0,
        enterBreak = 1,
        exitBreak = 2
    }

    self._fightSM = RelinkStateMachine.New("白龙战斗状态机")
    self._fightSM:AddState(XChar8056.EFightState.Inactive, "未激活", nil, nil, nil, math.huge)
    local enterNormal = function()
        -- 重置技能轴
        local newBattleLoopIdx = self:GetBattleLoopIdx() + 1
        if #self._intendSkillSeqs > 0 then
            if newBattleLoopIdx > #self._intendSkillSeqs then
                newBattleLoopIdx = 1
            end
        else
            newBattleLoopIdx = 0
        end
        self:SetBattleLoopIdx(newBattleLoopIdx)

        -- 技能索引刷新
        self:SetCurSeqIdx(0)
        self:SetNextSeqIdx(1)

        -- 设立技能轴
        if self:GetBattleLoopIdx() > 0 then
            self._curSkillSeq = self._intendSkillSeqs[self:GetBattleLoopIdx()][1]
        end

        -- 刷新CD
        self:RefreshSkillCD(false)
    end
    self._fightSM:AddState(XChar8056.EFightState.Normal, "常规", enterNormal, nil, nil, math.huge)
    local enterOD = function()
        -- 技能索引刷新
        self:SetCurSeqIdx(0)
        self:SetNextSeqIdx(1)

        -- 设立技能轴
        if self:GetBattleLoopIdx() > 0 then
            self._curSkillSeq = self._intendSkillSeqs[self:GetBattleLoopIdx()][2]
        end

        -- 刷新CD
        self:RefreshSkillCD(false)
    end
    self._fightSM:AddState(XChar8056.EFightState.OD, "OD", enterOD, nil, nil, math.huge)
    local enterODBreak = function()
        -- 播放进入OD Break动作
        self._proxy:AbortAction(self._uuid, true)
        local isSuccess = self._proxy:CastAction(self._uuid, self._odBreakEnterSkill)
        XLog.Debug("测试状态机：是否成功" .. tostring(isSuccess))

        -- 状态更新
        --self:ChangeState(XChar8056.EBattleState.NormalState)

        -- Break期间不能破韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000467, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断

        -- 移除绑定特效buff
        self._proxy:RemoveBuff(self._uuid, 8005012)
        self._proxy:RemoveBuff(self._uuid, 8005013)
        self._proxy:RemoveBuff(self._uuid, 8005014)
        self._proxy:RemoveBuff(self._uuid, 8005015)
        self._proxy:RemoveBuff(self._uuid, 8005016)
        self._proxy:RemoveBuff(self._uuid, 8005017)
        self._proxy:RemoveBuff(self._uuid, 8005018)
        self._proxy:RemoveBuff(self._uuid, 8005019)
        self._proxy:RemoveBuff(self._uuid, 8005020)

        -- 确保隐藏浮游炮的buff全部移除
        self:ForceShowAllFinFunnel()

        -- 自身时停
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005302, 100)

        -- 易伤
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005556, 100)

        local players = self._proxy:GetPlayerNpcList()
        local hasGiveEnergy = false
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 8005302, 100) -- 时停
            self._proxy:ApplyMagic(self._uuid, playerID, 8005201, 100) -- 碎屏特效
            self._proxy:ApplyMagic(self._uuid, playerID, 8005401, 100) -- 镜头拉近

            if not hasGiveEnergy and (playerID ~= nil and playerID ~= 0 and self._proxy:CheckNpc(playerID)) then
                self._proxy:AddTeamWorkEnergy(playerID, 50)                        -- 给50能量
                hasGiveEnergy = true
            end
        end
    end
    self._fightSM:AddState(XChar8056.EFightState.ODBreakStart, "ODBreak开始", enterODBreak, nil, nil, 1.733)
    local enterODBreaking = function()
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionEx(self._uuid, self._odBreakLoopSkill)
    end
    local exitODBreaking = function()
        -- 退出OD Break状态
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionEx(self._uuid, self._odBreakExitSkill)

        -- 移除锁破韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断

        -- 移除易伤
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005556, 100)
    end
    self._fightSM:AddState(XChar8056.EFightState.ODBreaking, "ODBreak中", enterODBreaking, nil, exitODBreaking, math.huge)

    self._fightSM:AddTrigger(self._fightSMTriggers.activate)
    self._fightSM:AddTrigger(self._fightSMTriggers.enterBreak)
    self._fightSM:AddTrigger(self._fightSMTriggers.exitBreak)

    local inactiveToNormal = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.activate)
    end
    self._fightSM:AddTransition(XChar8056.EFightState.Inactive, XChar8056.EFightState.Normal, inactiveToNormal, 0, 0)
    local normalToOD = function()
        return self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.OverDrive) >= self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.OverDrive)
    end
    self._fightSM:AddTransition(XChar8056.EFightState.Normal, XChar8056.EFightState.OD, normalToOD, 0, 0)
    local odToODBreakStart = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.enterBreak)
    end
    self._fightSM:AddTransition(XChar8056.EFightState.OD, XChar8056.EFightState.ODBreakStart, odToODBreakStart, 0, 0)
    self._fightSM:AddTransition(XChar8056.EFightState.ODBreakStart, XChar8056.EFightState.ODBreaking, nil, 0, 1)
    local odBreakingToNormal = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.exitBreak)
    end
    self._fightSM:AddTransition(XChar8056.EFightState.ODBreaking, XChar8056.EFightState.Normal, odBreakingToNormal, 0, 0)

    local OnStateChangedHandler = function(previousStateId, nextStateId)
        local previousState = self._fightSM:GetState(previousStateId)
        XLog.Debug("状态机：退出" .. tostring(previousState.name))
        local nextState = self._fightSM:GetState(nextStateId)
        XLog.Debug("状态机：进入" .. tostring(nextState.name))

        -- 初始进入战斗状态时，给全场玩家加仇恨值(T+5000, 非T+1), 强制刷一遍CD
        if previousStateId == XChar8056.EFightState.Inactive and nextStateId == XChar8056.EFightState.Normal then
            local players = self._proxy:GetPlayerNpcList()
            for key, playerId in ipairs(players) do
                if self:IsPlayerTank(playerId) then
                    self._proxy:ApplyMagic(self._uuid, playerId, 8005352, 1)
                else
                    self._proxy:ApplyMagic(self._uuid, playerId, 8005351, 1)
                end
            end

            self:RefreshSkillCD(true)
        end

        self:SetFightStateId(nextStateId)
    end
    self._fightSM:RegisterOnStateChanged(OnStateChangedHandler)
end
--endregion

return XChar8056
