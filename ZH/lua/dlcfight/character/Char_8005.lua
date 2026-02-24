local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")
local XFastBlackboard = require("Tools/Blackboard/XFastBlackboard")

---白龙
---@class XChar8005 : XFightBase
local XChar8005 = XDlcScriptManager.RegCharScript(8005, "XChar8005", Base)

XChar8005.EInterpMode =
{
    Linear = 0,
    EaseOutCubic = 1
}

XChar8005.EFightState = {
    Inactive = 0,
    Normal = 1,
    OD = 2,
    ODBreakStart = 3,
    ODBreaking = 4
}

XChar8005.ESyncVarType = {
    Boolean = 0,
    Integer = 1
}

--region 函数: 脚本生命周期
function XChar8005:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    ---@type XFastBlackboard
    self._bb = XFastBlackboard.New(self._proxy, self._uuid, "光煌龙", XVarDomain.Npc, true)

    -- !! syncKeys与syncVarLocalVals必须最早被初始化
    --- 参与网络变量同步的变量键值
    self._syncKeys =
    {
        isAiActivated = 8005001,
        IsInQTEInteract = 8005002,
        battleLoopIdx = 8005003,
        curSeqIdx = 8005004,
        nextSeqIdx = 8005005,
        curSkillId = 8005006,
        curComboId = 8005007,
        fightStateId = 8005008,
        isFury = 8005009,
        curActionId = 8005010
    }

    self._syncVarConfig = {
        [8005001] = { XFastBlackboard.ESyncVarType.Boolean, true },
        [8005002] = { XFastBlackboard.ESyncVarType.Boolean, false },
        [8005003] = { XFastBlackboard.ESyncVarType.Integer, 0 },
        [8005004] = { XFastBlackboard.ESyncVarType.Integer, 0 },
        [8005005] = { XFastBlackboard.ESyncVarType.Integer, 0 },
        [8005006] = { XFastBlackboard.ESyncVarType.Integer, 0 },
        [8005007] = { XFastBlackboard.ESyncVarType.Integer, 0 },
        [8005008] = { XFastBlackboard.ESyncVarType.Integer, XChar8005.EFightState.Inactive },
        [8005009] = { XFastBlackboard.ESyncVarType.Boolean, false },
        [8005010] = { XFastBlackboard.ESyncVarType.Integer, 0 }
    }

    for keyName, key in pairs(self._syncKeys) do
        self._bb:InitBBSyncVar(key, self._syncVarConfig[key][1], self._syncVarConfig[key][2])
    end

    self:InitAggroSystem()
    self:InitChasingSystem()
    self:InitCoreCombatSystem()
    self:InitDelayCallSystem()
    self:InitAudioSystem()

    -- 换主控保底内容
    --- 换主控流程是否处理完成
    self._isGainControlFullyHandled = true
    --- 换主控后需要立即释放的技能
    self._gainControlActionToCast = nil
    --- 换主控后技能释放的目标位置
    self._gainControlActionPos = nil
    --- 换主控后释放的Action是否要等待仇恨目标更新完成再释放
    self._gainControlActionWaitSkillTarget = false
    --- 是否采用标注技能释放途径（标准释放途径会触发冷却，并触发连招系统）
    self._gainControlUseRegularSkill = false

    -- 状态机
    self:InitFightStateMachine()

    if isGainControl then
        local stateId = self._bb:GetSyncVarLocal(self._syncKeys.fightStateId)
        self._fightSM:SyncState(stateId)

        -- 同步技能轴
        local battleLoopIdx = self._bb:GetSyncVarLocal(self._syncKeys.battleLoopIdx)
        if stateId == XChar8005.EFightState.Normal then
            self._curSkillSeq = self._intendSkillSeqs[battleLoopIdx][1]
        end
        if stateId == XChar8005.EFightState.OD then
            self._curSkillSeq = self._intendSkillSeqs[battleLoopIdx][2]
        end

        -- 处理动作流程恢复
        self:GainControlActionRecoverHandler()

        -- 如果未激活，则立即激活
        if self._fightSM:GetCurStateId() == XChar8005.EFightState.Inactive then
            self._fightSM:ChangeState(XChar8005.EFightState.Normal)
        end
        -- 继续运行状态机
        self._fightSM:Enable()

    else
        -- 开始运行AI
        self._fightSM:Activate()
        self._fightSM:ChangeState(XChar8005.EFightState.Normal)
    end
end

--- 换主控后，对于特殊Action的一些恢复操作（包括状态解锁）
function XChar8005:GainControlActionRecoverHandler()
    local actionId = self._bb:GetSyncVarLocal(self._syncKeys.curActionId)
    local stateId = self._bb:GetSyncVarLocal(self._syncKeys.fightStateId)

    -- 清除当前ActionId
    self._bb:SetSyncVar(self._syncKeys.curActionId, 0)

    -- 取消看向
    self._proxy:DisableNpcLookAt(self._uuid)

    -- Break恢复
    if stateId == XChar8005.EFightState.ODBreakStart then
        -- 强制转入循环
        self._fightSM:SetTrigger(self._fightSMTriggers.enterBreaking)
    end

    -- Breaking恢复
    if stateId == XChar8005.EFightState.ODBreaking then
        -- 恢复Breaking
        self._isGainControlFullyHandled = false
        self._gainControlActionToCast = self._odBreakLoopSkill
    end

    -- DPS检测进入动作 或 循环动作恢复
    if actionId == 8005298 or actionId == 8005299 then
        -- 直接进入DPS检测循环动作
        self._isGainControlFullyHandled = false
        self._gainControlActionToCast = 8005299
    end

    -- DPS检测惩罚动作恢复
    if actionId == 8005300 then
        -- 闪现到场中
        self._proxy:SetNpcPosition(self._uuid, self._battleSceneCenter, true)
        self._isGainControlFullyHandled = false
        self._gainControlActionToCast = 8005300
        self._gainControlActionPos = self._battleSceneCenter
        -- 移除所有缓速
        self:ApplyMagicsToSelf({8005326, 8005327}, 1)
        -- 移除狂暴标记，会再加的
        self:ApplyMagicsToSelf({1000498}, 1)
    end

    -- 全场喷火恢复
    if actionId == 8005518 or actionId == 8005519 or actionId == 8005301 then
        self._isGainControlFullyHandled = false
        self._gainControlActionToCast = 8005518
        self._gainControlActionWaitSkillTarget = true
        self._gainControlUseRegularSkill = true
        if actionId == 8005301 then
            -- 移除狂暴标记，会再加的
            self:ApplyMagicsToSelf({1000498}, 1)
        end
    end

    -- 角力联弹触发攻击恢复
    if actionId == 8005505 and not self._bb:GetSyncVarLocal(self._syncKeys.IsInQTEInteract) then
        self._isGainControlFullyHandled = false
        self._gainControlActionToCast = 8005505
        self._gainControlActionWaitSkillTarget = true
    end

    -- 角力/多人弹刀状态，强制解锁各种状态锁定
    if self._bb:GetSyncVarLocal(self._syncKeys.IsInQTEInteract) then
        self:ExitQTEInteract()
    end
end

---@param dt number @ delta time
function XChar8005:Update(dt)
    Base.Update(self, dt)

    -- 技能保底
    self:UpdateComboSkillSafeProtection()

    -- 延迟调用
    self:UpdateDelayCallSystem(dt)

    -- 同步是否启动AI
    if not self._bb:GetSyncVarLocal(self._syncKeys.isAiActivated) then
        return
    end

    -- 状态更新
    self._fightSM:Update(dt)

    -- 软狂暴设定
    if self._enableSoftFury then
        local fightTime = self._proxy:GetFightTime()
        if not self._bb:GetSyncVarLocal(self._syncKeys.isFury) and fightTime > self._softFuryTime then
            local curStateId = self._fightSM:GetCurStateId()
            if curStateId == XChar8005.EFightState.Normal or curStateId == XChar8005.EFightState.OD then
                self._bb:SetSyncVar(self._syncKeys.isFury, true)

                -- 增加烦躁值上限，不希望在狂暴期间放补位技能
                self._maxRectifyIrritation = 50
                -- 施加狂暴所需的效果
                self:ApplyMagicsToSelf(self._softFuryMagics, 1)
                -- 延迟开始放落雷
                self._softFuryDropMissileTimer = self._softFuryDropMissileStartDelay

                if curStateId == XChar8005.EFightState.OD then
                    self._curSkillSeq = self._intendSkillSeqs[3][2]

                    if self._proxy:CheckBuffByKind(self._uuid, self._odMarkMagic) then
                        -- OD状态且有OD技能标记，说明已经实际在OD状态内，直接从第二个技能开始进入OD技能列表
                        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 1)
                        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 2)
                    else
                        -- OD状态且没有实际OD标记，则为OD吼前，从第一个技能开始进OD技能列表
                        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
                        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
                    end
                    -- 刷新CD
                    self:RefreshSkillCD(false)
                else
                    self._curSkillSeq = self._intendSkillSeqs[3][1]
                    -- 技能索引刷新
                    self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
                    self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
                    -- 刷新CD
                    self:RefreshSkillCD(false)
                end
            end
        end
    end

    -- 固定频率更新仇恨目标
    self:UpdateAggroSystem(dt)

    -- Break时阻断后续逻辑，并确保在break loop动作内(保底逻辑)
    if self._fightSM:GetCurStateId() == XChar8005.EFightState.ODBreakStart or self._fightSM:GetCurStateId() == XChar8005.EFightState.ODBreaking then
        local curActionId = self._bb:GetSyncVarLocal(self._syncKeys.curActionId)

        if curActionId ~= self._odBreakEnterSkillSkill or curActionId ~= self._odBreakLoopSkill or curActionId ~= self._odBreakExitSkill then
            self._proxy:CastAction(self._uuid, self._odBreakLoopSkill)
            return
        end
    end

    -- 角力/多人弹刀状态阻断后续逻辑
    if self._bb:GetSyncVarLocal(self._syncKeys.IsInQTEInteract) then
        return
    end

    -- 换主控流程未处理完成，打断后续逻辑
    if not self._isGainControlFullyHandled then
        if self._gainControlActionToCast == nil then
            self._isGainControlFullyHandled = true
        else
            if not self._proxy:CheckNpcCurrentAction(self._uuid, self._gainControlActionToCast) then
                if self._gainControlActionPos ~= nil then
                    self._proxy:CastActionToPosition(self._uuid, self._gainControlActionToCast, self._gainControlActionPos)
                elseif self._gainControlActionWaitSkillTarget then
                    if self:GetSkillTarget() == nil or self:GetSkillTarget() == 0 then
                        return
                    end
                    if self._gainControlUseRegularSkill then
                        self:CastRegularSkill(self._gainControlActionToCast)
                    else
                        self._proxy:CastActionToTarget(self._uuid, self._gainControlActionToCast, self:GetSkillTarget())
                    end
                else
                    self._proxy:CastAction(self._uuid, self._gainControlActionToCast)
                end
                return
            else
                self._isGainControlFullyHandled = true
            end
        end
    end

    -- 追逐逻辑
    self:UpdateChasingSystem(dt)

    -- 战斗核心逻辑
    self:UpdateCoreCombatSystem(dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8005:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8005:InitEventCallBackRegister()
    -- 事件绑定
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:RegisterEvent(EWorldEvent.NpcMultiParryStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcMultiParrySucceed)
    self._proxy:RegisterEvent(EWorldEvent.NpcMultiParryFail)
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)

    -- 指定目标事件绑定
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess, self._uuid)

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkAIBorn)
end

function XChar8005:Terminate()
    -- 追逐系统注销
    self._proxy:SetNpcStopFollow(self._uuid)

    -- 战斗状态机注销
    self._fightSM:Terminate()

    -- 事件解绑
    self._proxy:UnregisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:UnregisterEvent(EWorldEvent.NpcDamage)
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcEnterOverDrive)
    self._proxy:UnregisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcODExitBreakAfter)
    self._proxy:UnregisterEvent(EWorldEvent.NpcWrestleStart)
    self._proxy:UnregisterEvent(EWorldEvent.NpcWrestlePursuit)
    self._proxy:UnregisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:UnregisterEvent(EWorldEvent.NpcMultiParryStart)
    self._proxy:UnregisterEvent(EWorldEvent.NpcMultiParrySucceed)
    self._proxy:UnregisterEvent(EWorldEvent.NpcMultiParryFail)
    self._proxy:UnregisterEvent(EWorldEvent.NpcDodge)
    self._proxy:UnregisterEvent(EWorldEvent.NpcDie)

    -- 指定目标事件解绑
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCounterSuccess, self._uuid)

    -- 解绑lua事件
    self._proxy:UnregisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)
    self._proxy:UnregisterLuaEvent(EFightLuaEvent.RelinkAIBorn)

    -- 注销所有同步变量
    self._bb:Terminate()

    Base.Terminate(self)
end
--endregion

--region 连招类技能究极大保底
function XChar8005:UpdateComboSkillSafeProtection()
    local curActionId = self._bb:GetSyncVarLocal(self._syncKeys.curActionId)

    -- 角力和多人弹刀为程序控制的状态，必然存在进入和退出，不做保底处理
    if self._bb:GetSyncVarLocal(self._syncKeys.IsInQTEInteract) then
        return
    end

    -- 狂暴技magic保底
    self:ProtectComboSkill(curActionId, 1000497, 1000498,
            {8005300, 8005301, 8005518, 8055519}, false)
    -- 锁OD保底
    self:ProtectComboSkill(curActionId, 1000465, 1000466,
            {8005298, 8005299, 8005300, 8005301, 8005505, 8005518, 8005519}, false)
    -- 锁破韧保底
    self:ProtectComboSkill(curActionId, 1000467, 1000468,
            {8005298, 8005299, 8005300, 8005301, 8005505, 8005518, 8005519, self._odBreakEnterSkill, self._odBreakLoopSkill, self._odBreakExitSkill}, false)
    -- 锁韧性保底
    self:ProtectComboSkill(curActionId, 1000469, 1000470,
            {8005298, 8005299, 8005300, 8005301, 8005505, 8005518, 8005519, self._odBreakEnterSkill, self._odBreakLoopSkill, self._odBreakExitSkill}, false)
    -- 防打断保底
    self:ProtectComboSkill(curActionId, self._immuUltraAbortMagicId, self._cancelImmuUltraAbortMagicId,
            {8005298, 8005299, 8005300, 8005301, 8005505, 8005518, 8005519, self._odBreakEnterSkill, self._odBreakLoopSkill, self._odBreakExitSkill}, false)
    -- DPS检测护盾保底
    self:ProtectComboSkill(curActionId, 8005070, 8005082, {8005298, 8005299}, true)
    -- 锁血保底
    self:ProtectComboSkill(curActionId, 1000446, 1000447, {8005298, 8005299, 8005300}, false)
end

function XChar8005:ProtectComboSkill(curActionId, buffTemplateId, removeBuffTemplateId, actionIds, onlyCareRemove)
    local isInAnyAction = false

    -- 检测是否在任意一个连招action内
    for index, actionId in ipairs(actionIds) do
        if actionId == curActionId then
            isInAnyAction = true
            break
        end
    end

    -- 如果在任意连招内，则确保该效果存在，否则移除该效果
    local hasBuff = self._proxy:CheckBuffByKind(self._uuid, buffTemplateId)
    if isInAnyAction then
        if not hasBuff and not onlyCareRemove then
            self._proxy:ApplyMagic(self._uuid, self._uuid, buffTemplateId, 1)
        end
    else
        if hasBuff then
            self._proxy:ApplyMagic(self._uuid, self._uuid, removeBuffTemplateId, 1)
        end
    end
end
--endregion

--region 延迟调用系统
--- 延迟调用函数：参数1：函数名，参数2：延迟，后续参数：函数参
function XChar8005:DelayCall(...)
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
function XChar8005:InitDelayCallSystem()
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
function XChar8005:UpdateDelayCallSystem(dt)
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
function XChar8005:InitAggroSystem()
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
function XChar8005:UpdateAggroSystem(dt)
    if self._aggroUpdateTimer >= self._aggroUpdateInterval then
        -- 如果有点名目标，则设置为点名目标，否则基于仇恨系统获取
        local targetNpc = nil
        if self._curPickingTarUUID ~= nil then
            targetNpc = self._curPickingTarUUID
        else
            targetNpc = self._proxy:GetMaxThreatNpc(self._uuid)
        end

        --设置为仇恨目标
        if targetNpc ~= nil and targetNpc ~= 0 then
            -- 如果和当前不同则替换
            if targetNpc ~= self._curAggroTarUUID then
                self._curAggroTarUUID = targetNpc

                -- 转仇恨，销毁玩家连线特效，创建连线特效给新仇恨目标（目前对于点名也使用这个效果，等点名效果制作完再替换）
                for i, player in ipairs(self._proxy:GetPlayerNpcList()) do
                    self._proxy:RemoveBuff(player, 8052119)
                end
                self._proxy:ApplyMagic(self._uuid, self._curAggroTarUUID, 8052119, 1)
            end
            -- 计算距离
            self._curDisToAggroTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
        end

        -- 对于非仇恨列表的目标，强制拉入仇恨列表
        local players = self._proxy:GetPlayerNpcList()
        for i, player in ipairs(players) do
            if not self._proxy:CheckNpcInThreatList(self._uuid, player) and
                    not self._proxy:CheckNpcIsDisconnect(player) and
                    not self._proxy:CheckNpcFullActionState(player, ENpcAction.Death, -1) and
                    not self._proxy:CheckNpcFullActionState(player, ENpcAction.Reboot, -1) and
                    not self._proxy:CheckNpcFullActionState(player, ENpcAction.Dying, -1) then
                if self:IsPlayerTank(player) then
                    self._proxy:AddThreat(self._uuid, player, 0, 1000)
                else
                    self._proxy:AddThreat(self._uuid, player, 0, 100)
                end
            end
        end

        self._aggroUpdateTimer = 0
    end

    --[[
    -- 是否有目标存在？目标如果不合法就强制更新一次
    if self._curAggroTarUUID == nil or (not self._proxy:CheckNpc(self._curAggroTarUUID)) or self._proxy:IsNpcDead(self._curAggroTarUUID) then
        self:ForceSetNearestAlivePlayerAsAggroTarget()
    end
    ]]

    -- 点名目标消失处理
    if self._curPickingTarUUID ~= nil then
        if not self._proxy:CheckNpc(self._curPickingTarUUID) or self._proxy:IsNpcDead(self._curPickingTarUUID) then
            self._curPickingTarUUID = nil
        end
    end

    self._aggroUpdateTimer = self._aggroUpdateTimer + dt
end

--- 强制让距离最近的玩家成为仇恨目标，目前临时用作仇恨系统出问题的保底对策
function XChar8005:ForceSetNearestAlivePlayerAsAggroTarget()
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
        -- 更新距离
        self._curDisToAggroTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
    end
end

--- 获取当前技能目标，有点名选点名，没点名选仇恨
function XChar8005:GetSkillTarget()
    if self._curPickingTarUUID == nil then
        return self._curAggroTarUUID
    else
        return self._curPickingTarUUID
    end
end
--endregion

--region 追逐系统
--- 初始化：追逐系统
function XChar8005:InitChasingSystem()
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
function XChar8005:UpdateChasingSystem(dt)
    -- 追逐未开始，不执行后续逻辑
    if not self._isChasing then
        return
    end

    -- 追逐停止的条件检测，为了方便debug停止原因，这里分开单独判断
    local isAggroTargetNull = self:GetSkillTarget() == nil or self:GetSkillTarget() == 0
    local isAggroTargetChange = self:GetSkillTarget() ~= self._curChasingTarUUID
    local isInStopDis = self._curDisToAggroTar <= self._curChaseStopDis

    -- 追逐流程停止
    if isAggroTargetNull or isAggroTargetChange or isInStopDis then
        self._proxy:SetNpcStopFollow(self._uuid)
        self._proxy:DisableNpcLookAt(self._uuid)
        self._isChasing = false
        return
    end
end

--- 追逐仇恨目标
---@param stopDis number @ 停止追逐距离
function XChar8005:ChasingAggroTarget(stopDis)
    -- 仇恨目标是否为空
    if self:GetSkillTarget() == nil or self:GetSkillTarget() == 0 then
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
        self._proxy:SetNpcStopFollow(self._uuid)
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

    -- 开始时看向追击目标
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._removeLookAtIKMagic, 1)
    self._proxy:DisableNpcLookAt(self._uuid)
    self._proxy:EnableNpcLookAt(self._uuid, self._curChasingTarUUID, "HitCase")
end
--endregion

--region 核心战斗系统
--- 初始化：核心战斗系统
function XChar8005:InitCoreCombatSystem()
    self:InitCoreCombatStateControlSystem()
    self:InitCoreCombatSkillCastSystem()
    self:InitCoreCombatInSkillSystem()
    self:InitCoreCombatRectifySystem()
    self:InitCoreCombatCoolDownSystem()

    self._ultraRayLastNpcTime = 0
end

--- 更新：核心战斗系统
--- @param dt number @ delta time
function XChar8005:UpdateCoreCombatSystem(dt)
    -- 特殊大招逻辑
    self:UltraRayUpdateLogic()

    -- 循环轴为nil或长度为0则不执行后续逻辑
    if self._intendSkillSeqs == nil or #self._intendSkillSeqs <= 0 then
        return
    end

    -- 技能CD更新
    self:UpdateCoreCombatCoolDownSystem(dt)

    -- 状态控制系统更新
    self:UpdateCoreCombatStateControlSystem(dt)

    -- Break状态，阻断后续逻辑，防止换端导致Break动作被中断
    local curStateId = self._fightSM:GetCurStateId()
    if curStateId == XChar8005.EFightState.ODBreakStart or curStateId == XChar8005.EFightState.ODBreaking then
        return
    end

    -- 技能目标不存在，则不允许后续技能筛选逻辑
    if self:GetSkillTarget() == nil or not self._proxy:CheckNpc(self:GetSkillTarget()) then
        return
    end

    -- 检测能否放技能，分情况，如果在技能中，则走连招逻辑，其他状态则直接阻断
    local internalCanCastCheck = self._proxy:CheckCanCastSkill(self._uuid)
    local isInAction = self._proxy:CheckNpcFullActionState(self._uuid, 3, -1)
    if not internalCanCastCheck or isInAction then
        if isInAction then
            self:UpdateCoreCombatInSkillSystem()
        end
        return
    end

    self:UpdateCoreCombatSkillCastSystem()
end
--endregion

--region 核心战斗系统：状态控制系统
function XChar8005:InitCoreCombatStateControlSystem()
    self._odBreakSkill = 8005524
    --- OD Break开始技能ID
    self._odBreakEnterSkill = 8005331
    --- OD Break循环技能ID
    self._odBreakLoopSkill = 8005332
    --- OD Break结束技能ID
    self._odBreakExitSkill = 8005333

    --- OD状态标记
    self._odMarkMagic = 8005911
    --- 移除OD状态标记
    self._odMarkRemoveMagic = 8005912

    --- 破韧技能表-重版（适配多方位破韧受击）
    self._ultraHitSkillSeqHeavy = {
        8005124,    -- 前破
        8005128,    -- 左破
        8005132,    -- 右破
        8005136     -- 后破
    }
    --- 破韧技能表-轻版（适配多方位破韧受击）
    self._ultraHitSkillSeqLight = {
        8005311,    -- 前破
        8005314,    -- 左破
        8005313,    -- 右破
        8005312     -- 后破
    }
    --- 破韧不同角度受击动作的触发角度条件
    self._ultraHitAngleConds = {
        {{-45, 45}},
        {{-135, -45}},
        {{45, 135}},
        {{-180, -135}, {135, 180}}
    }

    --- 破韧状态的持续时间
    self._breakMagicId = 1000494
    --- 破韧时物理抗性降低的效果
    self._breakPhyDefDownMagic = 8005566
    --- 阻止玩家大招打断BOSS动作的标记buff
    self._immuUltraAbortMagicId = 8005906
    --- 移除：阻止玩家大招打断BOSS动作的标记buff
    self._cancelImmuUltraAbortMagicId = 8005907

    -- 软狂暴机制
    --- 是否启用软狂暴内容
    self._enableSoftFury = false
    --- 战斗时长多少秒后进入软狂暴状态
    self._softFuryTime = 330
    --- 软狂暴时施加给自身的效果表
    self._softFuryMagics =
    {
    }
    --- 软狂暴死亡时移除的效果表
    self._softFuryDeadRemoveMagics = {
        8005914
    }
    --- 软狂暴点名子弹Id
    self._softFuryDropMissileId = 8005181
    --- 软狂暴点名子弹发射Id
    self._softFuryDropMissileLaunchId = 8005072
    --- 软狂暴点名子弹随机offset范围
    self._softFuryDropMissileOffset = {0, 1.5}
    --- 软狂暴点名子弹点名频率区间
    self._softFuryDropMissileRate = {5, 7}
    --- 软狂暴点名子弹计时器
    self._softFuryDropMissileTimer = 0
    --- 软狂暴点名子弹开始生成延迟
    self._softFuryDropMissileStartDelay = 10

    --- 当前Action释放目标
    self._curActionTarget = nil

    -- 角力/多人弹刀修正
    --- 是否启用特殊交互（角力/多人弹刀）修正
    self._enableQTEInteractFix = true
    --- 角力修正半径范围
    self._wrestleSafeRadius = 16
    --- 多人弹刀修正半径范围
    self._multiParrySafeRadius = 19

    -- 一些通用的效果ID
    self._rHandReflectParticle = 8005003
    self._lHandReflectParticle = 8005002
    self._lightReflectSlomo = 8005004
    self._heavyReflectSlomo = 8005005
    self._lookAtIKMagic = 8005965
    self._removeLookAtIKMagic = 8005966

    -- 初始化韧性OD系统
    self._proxy:SetNpcBreakGaugeActive(self._uuid, true)
    self._proxy:SetNpcOverDriveActive(self._uuid, true)
end

function XChar8005:UpdateCoreCombatStateControlSystem(dt)
    -- 狂暴点名子弹逻辑
    local isFury = self._bb:GetSyncVarLocal(self._syncKeys.isFury)
    if isFury then

        -- Break期间不落雷
        if self._fightSM:GetCurStateId() == XChar8005.EFightState.ODBreakStart or self._fightSM:GetCurStateId() == XChar8005.EFightState.ODBreaking then
            return
        end

        if self._softFuryDropMissileTimer <= 0 and self:GetSkillTarget() ~= nil then
            -- 重置计时器
            self._softFuryDropMissileTimer = self._proxy:RandomFloat(self._softFuryDropMissileRate[1], self._softFuryDropMissileRate[2])

            -- 随机落点后发射
            for k, player in ipairs(self._proxy:GetPlayerNpcList()) do
                local targetPos = self._proxy:GetNpcPosition(player)
                local xOffset = self._proxy:Random(-100, 100) * self._softFuryDropMissileOffset[1] / 100
                local zOffset = self._proxy:Random(-100, 100) * self._softFuryDropMissileOffset[2] / 100
                targetPos = {x = targetPos.x + xOffset, y = targetPos.y + 0.2, z = targetPos.z + zOffset }
                self._proxy:LaunchMissileFromPosToPos(self._uuid, self._softFuryDropMissileLaunchId, self._softFuryDropMissileId, targetPos, targetPos, 1)
            end
        end
        self._softFuryDropMissileTimer = self._softFuryDropMissileTimer - dt
    end
end

--- 根据伤害来源角色位置，播放对应的破韧动作
function XChar8005:CastUltraHitBySrcPos(srcId, isHeavy)
    -- 异常情况排除，nil和空table的情况
    if self._ultraHitSkillSeqHeavy == nil or self._ultraHitSkillSeqLight == nil or
            #self._ultraHitSkillSeqHeavy <= 0 or #self._ultraHitSkillSeqLight <= 0 or
            self._ultraHitAngleConds == nil or #self._ultraHitAngleConds <= 0 then
        return
    end

    -- 来源不存在
    if not self._proxy:CheckNpc(srcId) then return end

    -- 默认用第一个
    local resultSkillIdx = 1

    -- 根据角度细化选择破韧技，选不到就用默认的
    if #self._ultraHitSkillSeqHeavy == #self._ultraHitAngleConds then
        for i = 1, #self._ultraHitAngleConds do
            if self:IsTarSatisfyAngleCond(srcId, self._ultraHitAngleConds[i]) then
                resultSkillIdx = i
            end
        end
    end

    local resultSkillId = self._ultraHitSkillSeqLight[resultSkillIdx]
    if isHeavy then
        resultSkillId = self._ultraHitSkillSeqHeavy[resultSkillIdx]
    end

    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastAction(self._uuid, resultSkillId)
end

function XChar8005:CastBreakSkill(isQTE)
    self._proxy:AbortAction(self._uuid, true)
    if isQTE then
        self._proxy:CastAction(self._uuid, 8005522)
    else
        self._proxy:CastAction(self._uuid, 8005125)
    end
end
--endregion

--region 核心战斗系统：技能释放系统
function XChar8005:InitCoreCombatSkillCastSystem()
    --- @class SkillInfo
    -- 战斗: 技能
    -- 关于修正：因为目前修正只考虑正向释放的攻击性技能，像例如吼叫或者背后攻击，是不会专门修正的
    -- 关于距离条件：格式为 { 最小距离，最大距离 }
    --- 存储技能信息，其中 [技能序号] = {CD, 转阶段是否重置CD, 是否允许修正, 距离条件, 角度条件, CD黑板键}
    self._skillInfos =
    {
        [8005011] = {     -- OD吼
            math.huge,   true,    false,   {},   {}, 8005501
        },
        [8005012] = {     -- 入战吼
            math.huge,   false,   false,   {},   {}, 8005502
        },
        [8005013] = {     -- 入战吼·真
            math.huge,   false,   false,   {},   {}, 8005503
        },
        [8005014] = {
            0,          true,    true,    {},   {}, 8005504
        },
        [8005030] = {     -- 二连小前咬
            0,          true,    true,    {8, 12}, {{-60, 60}}, 8005505
        },
        [8005031] = {     -- 右扫爪+拍地板
            0,          true,    true,    {8, 12}, {{-60, 60}}, 8005506
        },
        [8005032] = {     -- 黄圈右扫爪
            0,          true,    true,    {8, 14}, {{-90, 60}}, 8005507
        },
        [8005035] = {     -- 黄圈左扫爪
            0,           true,    true,    {8, 14}, {{-60, 90}}, 8005508
        },
        [8005037] = {      -- 黄圈左扫爪 + 起飞砸地（占位）
            0,           true,    true,    {4, 14}, {{-60, 90}}, 8005509
        },
        [8005033] = {      -- 身后二连甩尾
            0,           true,    false,    {6, 12}, {{-180, -120}, {120, 180}}, 8005510
        },
        [8005034] = {      -- 后撤开炮
            0,           true,    true,    {4, 14}, {{-60, 60}}, 8005511
        },
        [8005038] = {      -- 左刺
            0,           true,    true,    {8, 18}, {{-55, 55}}, 8005512
        },
        [8005039] = {      -- 左右刺
            0,           true,    true,    {8, 17.5}, {{-55, 55}}, 8005513
        },
        [8005036] = {      -- 龙车
            0,           true,    true,    {6, 30}, {{-55, 55}}, 8005514
        },
        [8005040] = {      -- 龙车+起飞砸地
            0,           true,    true,    {6, 12}, {{-55, 55}}, 8005515
        },
        [8005045] = {      -- 龙车+起飞失败
            0,           true,    true,    {6, 12}, {{-55, 55}}, 8005516
        },
        [8005041] = {      -- 浮游炮射击
            0,           true,    true,    {0, 20}, {{-55, 55}}, 8005517
        },
        [8005042] = {      -- 小喷火
            0,           true,    true,    {8, 12}, {{-45, 45}}, 8005518
        },
        [8005043] = {      -- 大喷火
            0,           true,    true,    {8, 25}, {{-55, 55}}, 8005519
        },
        [8005046] = {      -- 蓄力跳砸
            0,           true,    true,    {14, 35}, {{-55, 55}}, 8005520
        },
        [8005047] = {      -- 喷气起飞冲地
            0,           true,    true,    {6, 25}, {{-55, 55}}, 8005521
        },
        [8005048] = {      -- 演出落地招 - 临时
            0,           true,    true,    {}, {}, 8005522
        },
        [8005051] = {      -- 横扫口爆
            0,           true,    true,    {7, 14}, {{-55, 55}}, 8005523
        },
        [8005055] = {      -- 飞天轰炸
            math.huge,    true,    false,   {},   {}, 8005524
        },
        [8005505] = {      -- 多人弹刀技能
            160,           false,    true,    {7, 14}, {{-55, 55}}, 8005525
        },
        [8005514] = {
            0,           true,    true,    {14, 35}, {{-55, 55}}, 8005526
        },
        [8005296] = {
            0,          true,    true,    {4, 14}, {{-60, 60}}, 8005527
        },
        [8005298] = {   -- DPS Check
            math.huge,   true,    false,    {}, {}, 8005528
        },
        [8005299] = {
            0,           true,    true,    {}, {}, 8005529
        },
        [8005300] = {
            0,           true,    true,    {}, {}, 8005530
        },
        [8005315] = {   -- 入场动作
            math.huge,   false,   false,   {}, {}, 8005531
        },
        [8005518] = {   -- 全场喷火
            math.huge,   true,    false,    {}, {}, 8005532
        },
        [8005301] = {
            math.huge,   true,    false,    {}, {}, 8005533
        },
        [8005321] = {
            0, true, true, {4, 14}, {{-90, 60}}, 8005534
        },
        [8005322] = {
            0, true, true, {14, 30}, {{-60, 60}}, 8005535
        },
        [8005323] = {
            0, true, true, {6, 14}, {{-60, 90}}, 8005536
        },
        [8005324] = {
            0, true, true, {6, 30}, {{-55, 55}}, 8005537
        },
        [8005325] = {
            0, true, true, {8, 17.5}, {{-55, 55}}, 8005538
        },
        [8005326] = {
            0, true, true, {0, 20}, {{-55, 55}}, 8005539
        },
        [8005525] = {
            0,          true,    true,    {7, 14}, {{-90, 60}}, 8005540
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
        [7] = {{8005034, 1, 1}, {8005322, 1, 1}},             -- 开炮（近距离后撤喷，远距离原地喷）
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
        [22] = {{8005013, 1, 1}},            -- 软狂暴吼
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
        [34] = {{8005322, 1, 1}},            -- 原地火球
        [35] = {{8005323, 1, 1}},
        [36] = {{8005324, 1, 1}},            -- 长前摇龙车
        [37] = {{8005325, 1, 1}},
        [38] = {{8005326, 1, 1}},
        [39] = {{8005525, 1, 1}}
    }
    -- 每个战斗循环里面细分为普通状态技能轴和OD状态技能轴，每个里面存储了技能组释放序列
    -- 格式为 { 技能组ID，点名概率 }
    --- 期望技能轴，按照顺序执行循环
    self._intendSkillSeqs = {
        [1] = {
            [1] = {
                {9, 0},     -- 龙车
                {3, 0},     -- 二连前咬
                {24, 0},    -- 黄圈左扫(50%) or 黄圈右扫(50%)
                {28, 0},    -- 小挥爪
                {4, 0},     -- 右扫爪+拍地板
                {21, 0},    -- ！多人弹刀技能！
                {19, 0},    -- 横扫扇形爆破
                {11, 0},    -- 左刺
                {7, 0}      --  吐火球
            },
            [2] = {
                {1, 0},     -- OD吼
                {9, 0},     -- 龙车
                {12, 0},    -- 左右刺
                {30, 0},    -- 全场三连喷火
                {14, 0},    -- 浮游炮射击
                {16, 0},    -- 大喷火
                {21, 0},    -- ！多人弹刀技能！
                {28, 0},    -- 小挥爪
                {10, 0},   -- 黄圈扫+砸地
                {7, 0}      --  吐火球
            }
        },
        [2] = {
            [1] = {
                { 3, 0 },     -- 二连前咬
                { 24, 0 },  -- 黄圈左扫(50%) or 黄圈右扫(50%)
                { 15, 0 }, -- 小喷火
                { 21, 0 },    -- ！多人弹刀技能！
                { 19, 0 }, -- 横扫扇形爆破
                { 12, 0 }, -- 左右刺
                { 28, 0 }, -- 小挥爪
                { 4, 0 }, -- 右扫爪+拍地板
            },
            [2] = {
                { 1, 0 }, -- OD吼
                { 16, 0 }, -- 大喷火
                { 27, 0 }, -- DPS检测
                { 4, 0 }, -- 右扫爪+拍地板
                { 10, 0 }, -- 黄圈扫+砸地
                { 14, 0 }, -- 浮游炮射击
                { 21, 0 }, -- ！多人弹刀技能！
                { 3, 0 }, -- 二连前咬
                { 7, 0 },      --  吐火球
                { 17, 0 }, -- 蓄力跳砸
                { 28, 0 }, -- 小挥爪
            }
        },
        [3] = {
            [1] = {
                { 22, 0 },
                { 9, 0 },  -- 龙车长连段
                { 30, 0 }, -- 全场三连喷火
                { 16, 0 }, -- 大喷火
                { 15, 0 }, -- 小喷火
                { 16, 0 }, -- 大喷火
                { 19, 0 } -- 横扫扇形爆破
            },
            [2] = {
                { 1, 0 },
                { 22, 0 },
                { 30, 0 }, -- 全场三连喷火
                { 16, 0 }, -- 大喷火
                { 15, 0 }, -- 小喷火
                { 9, 0 },  -- 龙车长连段
                { 16, 0 }, -- 大喷火
                { 19, 0 },  --  横扫扇形爆破
            }
        }
    }
    --- 循环轴列表（不在该列表内的轴不会循环执行，例如软狂暴所使用的[3]号轴不在该表，则不会在正常战斗循环时出现）
    self._skillSeqLoopKeys = {
        [1] = 1,
        [2] = 2
    }

    --- 当前技能轴
    self._curSkillSeq = nil
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
    --- 战斗场景大小
    self._battleAreaHalfSize = { x = 50, y = 0, z = 50 }


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
    --- 浮游炮泊松盘采样计时器
    self._ultraPoissonDiskTimer = 0
    --- 执行一次泊松盘采样的时间
    self._ultraPoissonDiskInterval = 4.5
    self._ultraPoissonDiskPerTimer = 0
    self._ultraPoissonDiskPerInterval = 0
    self._ultraPoissonDiskPerCount = 0
    self._ultraPoissonDiskPoints = {}
    self._ultraPoissonDiskWidth = 80
    self._ultraPoissonDiskHeight = 80
    self._ultraPoissonDiskRadius = 22
    self._isUltraPoissonDiskValid = false

    -- DPS检测护盾受击频率控制
    --- DPS检测受击特效最小间隔
    self._ultraDpsCheckHitEffectMinInterval = 0.2
    --- DPS检测受击特效间隔计时器
    self._ultraDpsCheckHitEffectTimer = 0
    --- DPS检测护盾值magic
    self._ultraDpsCheckProtectorMagic = 8005551

    -- 弹刀技能列表
    self._counterSkills = {
        8005032,
        8005035,
        8005037,
        8005038,
        8005039,
        8005046
    }
    -- 常规危险技能列表
    self._powerfulSkills = {
        8005041,
        8005043,
        8005051
    }
    -- 角力联弹技能列表
    self._multiQTESkills = {
        8005505
    }
end

function XChar8005:UpdateCoreCombatSkillCastSystem()
    -- 如果正在追逐，则不执行技能判断
    if self._isChasing then
        return
    end

    if self._curSkillSeq == nil or #self._curSkillSeq <= 0 then
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
            local curCdTimer = 0
            if self._skillInfos[skillId][1] > 0 then
                curCdTimer = self._bb:GetSyncVarLocal(self._skillInfos[skillId][6])
            end
            if curCdTimer == nil then
                curCdTimer = 0
            end
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

        return
    end

    -- 顺轴选择技能组(索引计算用Clamp保险，防止OutOfIndex)
    local skillGroupIdx = self._curSkillSeq[self._bb:GetSyncVarLocal(self._syncKeys.nextSeqIdx)][1]

    local validSkillEleKeys, validSkillEleIdx = {}, 1
    local rotRecEleTotalWeight, rotRecEleKeys, rotRecEleIdx = 0, {}, 1
    local posRecEleTotalWeight, posRecEleKeys, posRecEleIdx = 0, {}, 1
    for key, skillGroupEle in ipairs(self._skillGroup[skillGroupIdx]) do
        local skillId, skillWeight = skillGroupEle[1], skillGroupEle[2]
        local intendSkillInfo = self._skillInfos[skillId]
        local cd = intendSkillInfo[1]
        local allowRectify = intendSkillInfo[3]
        local disCond = intendSkillInfo[4]
        local angleCond = intendSkillInfo[5]
        local syncKey = intendSkillInfo[6]
        -- CD检测，如果还在冷却就不管了

        local curCDTimer = 0
        if cd > 0 then
            curCDTimer = self._bb:GetSyncVarLocal(syncKey)
        end
        if curCDTimer == nil then
            curCDTimer = 0
        end
        if curCDTimer <= 0 then
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
                self._bb:SetSyncVar(self._syncKeys.curSeqIdx, self._bb:GetSyncVarLocal(self._syncKeys.nextSeqIdx))
                self:CastRegularSkill(skillId)

                self:IncreNextSqrIdx(#self._curSkillSeq)
                -- 跳出循环
                break
            end
        end
        -- 返回，流程结束
        return
    end

    -- 有可以修正角度的技能
    if #rotRecEleKeys > 0 then
        -- TODO: 目前由于修正逻辑只针对正向修正，不会根据技能参数而改变修正逻辑，所以这里其实没必要记录哪些技能要修正
        -- TODO: 但如果后面有空做的话就做（比如，向背后甩尾，就会故意调整成背朝玩家），这里先留一个口子出来
        self:TryRectifyRot()
        return
    end
    if #posRecEleKeys > 0 then
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
    self:IncreNextSqrIdx(#self._curSkillSeq)
end

--- 推进至下一个技能序号
function XChar8005:IncreNextSqrIdx(seqLength)
    local newNextSeqIdx = self._bb:GetSyncVarLocal(self._syncKeys.nextSeqIdx) + 1
    if newNextSeqIdx > seqLength then
        newNextSeqIdx = 1
    end
    self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, newNextSeqIdx)

    -- 处理点名
    local pickPossibility = self._curSkillSeq[newNextSeqIdx][2]
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
        end
    else
        -- 取消点名
        self._curPickingTarUUID = nil
    end
end

function XChar8005:CustomSelectSkillLogic()
    local pos = self._proxy:GetNpcPosition(self._uuid)

    -- 防卡死角，被卡了且面向外侧就跳出来，根据玩家相对位置决定咋跳
    local isOutSideX = pos.x <= self._battlePosLimitX[1] or pos.x >= self._battlePosLimitX[2]
    local isOutSideZ = pos.z <= self._battlePosLimitZ[1] or pos.z >= self._battlePosLimitZ[2]
    local isFacingOutside = self:CheckPosInAngle(self._battleSceneCenter, -75, 75)
    if (isOutSideX or isOutSideZ) and isFacingOutside then
        if not self._proxy:CheckNpc(self:GetSkillTarget()) then
            return false
        end

        local isFacingTarget = self:CheckTargetInAngle(self:GetSkillTarget(), -35, 35)
        local isInDis = self._proxy:CheckNpcDistance(self._uuid, self:GetSkillTarget(), 14)

        if isFacingTarget and isInDis then
            self._proxy:AbortAction(self._uuid, true)
            self:CastActionToTarget(8005014, self:GetSkillTarget())
            self._curRectifyIrritation = self._curRectifyIrritation + 2
            return true
        end
    end

    return false
end

--- 释放常规技能（常规流程释放的技能，破防，破OD，修正，连招等等均不算常规技能）
function XChar8005:CastRegularSkill(skillId)
    self:CastActionToTarget(skillId, self:GetSkillTarget())

    local syncKey = self._skillInfos[skillId][6]
    self._bb:SetSyncVar(syncKey, self._skillInfos[skillId][1])
    -- 刷新连招序号和当前释放的技能索引
    self._bb:SetSyncVar(self._syncKeys.curComboId, 0)
    self._bb:SetSyncVar(self._syncKeys.curSkillId, skillId)
end
--endregion

--region 核心战斗系统：技能中系统
function XChar8005:InitCoreCombatInSkillSystem()
    -- 连招系统
    --- @class ComboInfo
    --- @field preComboIdx int
    --- @field actionId int
    --- @field catchInterval
    --- @field beginTime number
    --- @field endTime number
    --- @field possibility number
    --- @field disCondition number[]
    --- @field angleCondition
    --- @field customCondition function
    --- @field actionTargetFunc function
    --- @field actionPosFunc function

    --region 连招自定义条件
    self._comboCondInOD = function()
        local curStateId = self._fightSM:GetCurStateId()
        return curStateId ~= nil and curStateId == XChar8005.EFightState.OD
    end
    self._comboCond518Index01 = function()
        return self._proxy:CheckNpcPositionDistance(self._uuid, self._battleSceneCenter, 10, true)
    end
    self._comboCond518Index02 = function()
        return not self._proxy:CheckNpcPositionDistance(self._uuid, self._battleSceneCenter, 10, true)
    end
    self._comboCondInSoftFury = function()
        return self._bb:GetSyncVarLocal(self._syncKeys.isFury)
    end
    --endregion

    --region 连招目标选取函数
    self._comboTargetDefault = function()
        return self:GetSkillTarget()
    end
    --endregion

    --region 连招位置选取函数
    self._comboPosSceneCenter = function()
        return self._battleSceneCenter
    end

    self._comboPos518BackJump = function()
        local centerVec2 = { self._battleSceneCenter.x, self._battleSceneCenter.z }
        local myPos = self._proxy:GetNpcPosition(self._uuid)
        local myPosVec2 = { myPos.x, myPos.z }
        local moveDir = self:NormalizeVector2(self:SubtractVector2(myPosVec2, centerVec2))
        local targetPosVec2 = self:AddVector2(self:ScaleVector2(moveDir, 3), myPosVec2)

        return { x = targetPosVec2[1], y = myPos.y, z = targetPosVec2[2] }
    end
    --endregion


    -- 如果前招式序号为0，则表示前招式为起手招
    --- @type table<int, table<int, ComboInfo>>
    self._comboTable = {
        -- 后撤开炮 -> 开炮 -> 开炮
        [8005034] = {
            [1] = {preComboIdx = 0, actionId = 8005034, catchInterval = {2, 2.1}, beginTime = 1.03, endTime = 3.46,
                   possibility = 1, disCondition = {10, 35}, angleCondition = {{-75, 75}}, customCondition = self._comboCondInOD,
                   actionTargetFunc = self._comboTargetDefault, actionPosFunc = nil},
            [2] = {preComboIdx = 1, actionId = 8005034, catchInterval = {2, 2.1}, beginTime = 1.03, endTime = 3.46,
                   possibility = 1, disCondition = {10, 35}, angleCondition = {{-75, 75}}, customCondition = self._comboCondInOD,
                   actionTargetFunc = self._comboTargetDefault, actionPosFunc = nil}
        },
        -- 龙车 -> 蓄力跳砸
        [8005036] = {
            [1] = {preComboIdx = 0, actionId = 8005046, catchInterval = {2.16, 2.2}, beginTime = 0, endTime = 5,
                   possibility = 1, disCondition = {8, 40}, angleCondition = {{-120, 120}}, customCondition = self._comboCondInOD,
                   actionTargetFunc = self._comboTargetDefault, actionPosFunc = nil},
            [2] = {preComboIdx = 0, actionId = 8005036, catchInterval = {2.15, 2.3}, beginTime = 0, endTime = 2.96,
                   possibility = 1, disCondition = {7, 40}, angleCondition = {{-150, 150}}, customCondition = self._comboCondInSoftFury,
                   actionTargetFunc = self._comboTargetDefault, actionPosFunc = nil},
            [3] = {preComboIdx = 2, actionId = 8005036, catchInterval = {2.15, 2.3}, beginTime = 0, endTime = 2.96,
                   possibility = 1, disCondition = {7, 40}, angleCondition = {{-150, 150}}, customCondition = self._comboCondInSoftFury,
                   actionTargetFunc = self._comboTargetDefault, actionPosFunc = nil},
            [4] = {preComboIdx = 3, actionId = 8005046, catchInterval = {2.15, 2.3}, beginTime = 0, endTime = 5,
                   possibility = 1, disCondition = {7, 40}, angleCondition = {{-150, 150}}, customCondition = self._comboCondInSoftFury,
                   actionTargetFunc = self._comboTargetDefault, actionPosFunc = nil},
        },
        -- DPS检测开始 -> DPS检测循环
        [8005298] = {
            [1] = {preComboIdx = 0, actionId = 8005299, catchInterval = {2.7, 2.8}, beginTime = 0, endTime = math.huge,
                   possibility = 1, disCondition = {}, angleCondition = {}, customCondition = nil,
                   actionTargetFunc = nil, actionPosFunc = nil}
        },
        -- 全场喷火完整修正连段
        [8005518] = {
            [1] = {preComboIdx = 0, actionId = 8005301, catchInterval = {0, 0.5}, beginTime = 0, endTime = 17.566,
                    possibility = 1, disCondition = {}, angleCondition = {}, customCondition = self._comboCond518Index01,
                    actionTargetFunc = nil, actionPosFunc = self._comboPos518BackJump},
            [2] = {preComboIdx = 0, actionId = 8005519, catchInterval = {0, 0.5}, beginTime = 0, endTime = 2.96,
                   possibility = 1, disCondition = {}, angleCondition = {}, customCondition = self._comboCond518Index02,
                   actionTargetFunc = nil, actionPosFunc = self._comboPosSceneCenter},
            [3] = {preComboIdx = 2, actionId = 8005301, catchInterval = {2.16, 2.66}, beginTime = 0, endTime = 17.566,
                   possibility = 1, disCondition = {}, angleCondition = {}, customCondition = nil,
                   actionTargetFunc = nil, actionPosFunc = self._comboPos518BackJump}
        }
    }

    --- DPS大招开始Action
    self._ultraBeginActionId = 8005298
    --- DPS大招开始Action结束时间
    self._ultraBeginActionEndTime = 2.7
    --- DPS大招循环Action结束时间
    self._ultraLoopActionEndTime = 30
    --- DPS大招结束Action
    self._ultraEndActionId = 8005300

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
    self._ultraCameraRemoveMagics = { 8005492, 8005493, 8005494, 8005495 }

    --- 全场火前置动作是否被打断
    self._isFireUltraPreActionAborted = false
end

--- 更新：核心战斗系统 - 技能中系统
function XChar8005:UpdateCoreCombatInSkillSystem()
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
    local curSkillId = self._bb:GetSyncVarLocal(self._syncKeys.curSkillId)
    local hasCombo = rawget(self._comboTable, curSkillId) ~= nil
    -- 寻找合适的连招
    if hasCombo then
        local comboInfos = self._comboTable[curSkillId]
        for i = 1, #comboInfos do
            local info = comboInfos[i]

            if self._bb:GetSyncVarLocal(self._syncKeys.curComboId) == info.preComboIdx                  -- 连招序号检定
                    and self._skillTimer >= info.catchInterval[1]    -- 时间区间检定
                    and self._skillTimer <= info.catchInterval[2]
            then
                -- 角度检定
                local isAngleSatisfy = true
                if #info.angleCondition ~= 0 then
                    isAngleSatisfy = self:IsTarSatisfyAngleCond(self:GetSkillTarget(), info.angleCondition)
                end

                -- 距离检定
                local isDisSatisfy = true
                if #info.disCondition ~= 0 then
                    local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self:GetSkillTarget())
                    isDisSatisfy = curDisToTar >= info.disCondition[1] and curDisToTar <= info.disCondition[2]
                end

                -- 自定义条件检定
                local isCustomSatisfy = true
                if info.customCondition ~= nil then
                    isCustomSatisfy = info.customCondition()
                end

                -- 随机数选取
                local randomFloat = self._proxy:Random(1, 100) / 100

                -- 同时满足，释放连招
                if isAngleSatisfy and isDisSatisfy and isCustomSatisfy and randomFloat <= info.possibility then
                    self._proxy:AbortAction(self._uuid, true)

                    if info.actionTargetFunc ~= nil then
                        local target = info.actionTargetFunc()
                        self._proxy:CastActionToTargetEx(self._uuid, info.actionId, target, info.beginTime, info.endTime)
                    elseif info.actionPosFunc ~= nil then
                        local pos = info.actionPosFunc()
                        self._proxy:CastActionToPositionEx(self._uuid, info.actionId, pos, info.beginTime, info.endTime)
                    else
                        self._proxy:CastActionEx(self._uuid, info.actionId, info.beginTime, info.endTime)
                    end

                    self._bb:SetSyncVar(self._syncKeys.curComboId, i)
                    break
                end
            end
        end
    end

    -- 打断部分技能
    self:TryBreakSkill()
end

function XChar8005:CustomInSkillLogic()
    if self._proxy:CheckNpcCurrentAction(self._uuid, self._ultraEndActionId) then
        -- 解锁，回到自由镜头
        if not self._isUltraEndCameraUnlocked and self._skillTimer >= self._ultraEndCameraUnlockTime then
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
            self:ApplyMagicsToAllPlayers(self._ultraEndLaserCameraMagic, 1)
            self._isUltraEndLaserCameraApplied = true
        end

        -- 爆炸镜头
        if not self._isUltraEndExplodeCameraApplied and self._skillTimer >= self._ultraEndExplodeCameraTime then
            self:ApplyMagicsToAllPlayers(self._ultraEndExplodeCameraMagic, 1)
            self._isUltraEndExplodeCameraApplied = true
        end
    end

    -- 破韧开始(触发击倒) 衔接 破韧起身
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005125) and self._skillTimer >= 1.3 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 8005127)
    end

    -- 破韧开始(QTE击倒) 衔接 破韧起身
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005522) and self._skillTimer >= 1.3 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 8005127)
    end
end

function XChar8005:LiveTest()
    -- 临时给C大量的仇恨
    for k, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
        if self:IsPlayerCarry(playerId) then
            self._proxy:ApplyMagic(self._uuid, playerId, 8005353, 1)
        end
    end
end

--- 尝试提前打断部分技能
function XChar8005:TryBreakSkill()
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

    -- 打断OD吼叫
    if self._proxy:CheckNpcCurrentAction(self._uuid, 8005011) and self._skillTimer >= 2.33 then
        self._proxy:AbortAction(self._uuid, true)
    end
end
--endregion

--region 核心战斗系统：身位修正系统
function XChar8005:InitCoreCombatRectifySystem()
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
function XChar8005:TryRectifyRot()
    local arSkills = self._angleRectifySkills
    local arRanges = self._angleRectifyConds

    -- 修正技能或者修正范围为空，不允许修正
    if arSkills == nil or arRanges == nil then
        return
    end

    -- 修正技能或者修正范围任意长度为0，或者两者长度不相等，则不允许修正
    if #arSkills == 0 or #arRanges == 0 or #arSkills ~= #arRanges then
        return
    end

    -- 遍历所有修正技能，查找一个符合条件的，随后释放
    for i = 1, #self._angleRectifySkills do
        local isSatisfy = self:IsTarSatisfyAngleCond(self:GetSkillTarget(), arRanges[i], false)
        if isSatisfy then
            --self._proxy:CastActionToTarget(self._uuid, arSkills[i], self:GetSkillTarget())
            self:CastActionToTarget(arSkills[i], self:GetSkillTarget())


            -- 烦躁值增长
            local cost = self._angleRectifyCostTable[i]
            if cost == nil then cost = 0 end
            self._curRectifyIrritation = self._curRectifyIrritation + cost
            break
        end
    end
end

--- 尝试通过位移动作来接近或远离目标
--- @param isTooClose @ 是否距离过近，false则代表距离过远（调用这个函数，默认有距离问题）
--- @param disMin @ 最小距离
--- @param disMax @ 最大距离
function XChar8005:TryRectifyPos(isTooClose, curDis, disMin, disMax)
    local drSkills = self._disRectifySkills
    local drLengths = self._disRectifyConds

    --TODO: 距离修正技能
    -- 修正技能或者修正范围为空，不允许修正
    if drSkills == nil or drLengths == nil then
        return
    end

    -- 修正技能或者修正范围任意长度为0，或者两者长度不相等，则不允许修正
    if #drSkills == 0 or #drLengths == 0 or #drSkills ~= #drLengths then
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
        --self._proxy:CastActionToTarget(self._uuid, drSkills[drSkillIdx], self:GetSkillTarget())
        self:CastActionToTarget(drSkills[drSkillIdx], self:GetSkillTarget())

        -- 烦躁值增长
        local cost = self._disRectifyCostTable[drSkillIdx]
        if cost == nil then cost = 0 end
        self._curRectifyIrritation = self._curRectifyIrritation + cost
        return
    end

    -- 如果没有合适的修正技能，直接走过去，目前只能前走
    if isTooClose then
        -- 距离过近，触发向后走？
    else
        -- 距离过远，走过去！
        -- 追逐停止距离 = 最小距离 +（最大距离 - 最小距离）* 0.6
        local stopDis = disMin + (disMax - disMin) * 0.6
        -- 开始追逐，停止追逐距离会被自动修正确保距离合法
        self:ChasingAggroTarget(stopDis)
    end
end
--endregion

--region 核心战斗系统：技能冷却系统
function XChar8005:InitCoreCombatCoolDownSystem()
    --- 每0.5秒给一次请求，CD不要高频的更新
    self._skillCdSyncInterval = 0.5
    self._skillCdSyncTimer = 0
    self._canSyncSkillCD = false

    for skillId, info in pairs(self._skillInfos) do
        local syncKey = info[6]
        local cd = info[1]

        if cd > 0 then
            self._bb:InitBBSyncVar(syncKey, XFastBlackboard.ESyncVarType.Float, 0)
        end
    end
end

--- 更新：核心战斗系统 - 技能冷却系统
function XChar8005:UpdateCoreCombatCoolDownSystem(dt)
    if self._skillCdSyncTimer <= 0 then
        self._canSyncSkillCD = true
        self._skillCdSyncTimer = self._skillCdSyncInterval
    end
    self._skillCdSyncTimer = self._skillCdSyncTimer - dt


    for skillId, info in pairs(self._skillInfos) do
        local syncKey = info[6]
        local cd = info[1]

        if cd > 0 then
            local newTime = self._bb:GetSyncVarLocal(syncKey) - dt
            if self._canSyncSkillCD then
                self._bb:SetSyncVar(syncKey, newTime)
            else
                self._bb:SetSyncVarLocal(syncKey, newTime)
            end
        end
    end

    self._canSyncSkillCD = false
end

--- 根据重置规则，重置所有技能CD
--- @param forceRefresh @ 无视重置规则
function XChar8005:RefreshSkillCD(forceRefresh)
    for skillId, info in pairs(self._skillInfos) do
        local syncKey = info[6]
        local cd = info[1]

        if cd > 0 then
            if forceRefresh or info[2] then
                self._bb:SetSyncVar(syncKey, 0)
            end
        end
    end
end
--endregion

--region 音效
--- 初始化音效系统
function XChar8005:InitAudioSystem()
    -- 音效事件magics
    self._cvEventMagics = {
        CastMultiQTESkill = 1000505,
        MultiQTESuccess = 1000506,
        CastCounterSkill = 1000507,
        CastHighDmgSkill = 1000508
    }

    self._cvMagics = {
        EnterScene = 8005751,
        DPSCheckStart = 8005752,
        DPSCheckSuccess = 8005753,
        DPSCheckFail = 8005754
    }
end
--endregion

--region Unity事件
function XChar8005:HandleLuaEvent(eventType, eventArgs)
    -- 响应AI开启和停止
    if eventType == EFightLuaEvent.RelinkSetAIActivate then
        if eventArgs.NpcUUid == self._uuid then
            self._bb:SetSyncVar(self._syncKeys.isAiActivated, eventArgs.IsActivated)
        end
    end

    -- 相应AI出生
    if eventType == EFightLuaEvent.RelinkAIBorn then
        if eventArgs.NpcUUid ~= self._uuid then
            return
        end

        -- 播放入场动作
        self._proxy:CastAction(self._uuid, 8005315)
    end
end

function XChar8005:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- 设立技能目标
    if targetId ~= nil and targetId ~= 0 then
        self._curActionTarget = targetId
    end
    -- 同步当前技能Id
    self._bb:SetSyncVar(self._syncKeys.curActionId, skillId)
    -- 刷新技能计时器
    self._skillTimer = 0

    -- OD吼锁韧性
    if skillId == 8005011 then
        self:LockGameplayState(false, true, true, true, false, false)
    end

    -- DPS检测开始
    if skillId == self._ultraBeginActionId then
        self:ApplyMagicsToAllPlayers({ 8005466}, 1) -- 临时镜头
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005961, 1) -- 开护盾部位
        self:LockGameplayState(true, true, true, true, true, false)
        -- DPS检测语音
        self:ApplyMagicsToAllPlayers({ self._cvMagics.DPSCheckStart }, 1)
    end

    -- DPS检测失败终结技
    if skillId == self._ultraEndActionId then
        self._isUltraEndCameraUnlocked = false
        self._isUltraEndCameraReLocked = false
        self._isUltraEndLaserCameraApplied = false
        self._isUltraEndExplodeCameraApplied = false

        -- 大招激光激活
        self._ultraRayTimer = 0
        self._isUltraCameraModified = false
        self._isUltraRayStart = true
        self._ultraRayLastNpcTime = self._proxy:GetNpcTime(self._uuid)

        -- 狂爆技标记
        self:ApplyMagicsToSelf({1000497}, 1)
    end

    -- 召唤浮游炮镜头
    if skillId == 8005041 then
        self:ApplyMagicsToAllPlayers({ 8005460, 8005461}, 1)
    end

    -- 全场喷火
    if skillId == 8005518 then
        self._isFireUltraPreActionAborted = false
        self:LockGameplayState(true, true, true, true, false, false)

        -- 狂爆技标记
        self:ApplyMagicsToSelf({1000497}, 1)
    end

    -- 软狂暴吼免疫打断
    if skillId == 8005013 then
        self:LockGameplayState(false, true, true, true, false, false)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000512, 1)
    end

    -- 入场动画
    if skillId == 8005315 then
        -- 入场语音
        self:ApplyMagicsToAllPlayers({ self._cvMagics.EnterScene }, 1)
    end

    -- 角力联弹触发攻击 锁状态
    if skillId == 8005505 then
        self:LockGameplayState(true, true, true, true, false, false)
    end

    -- 弹刀类技能触发预警事件，主要用于CV响应
    if self:Contain(self._counterSkills, skillId) then
        --self:ApplyMagicsToSelf({self._cvEventMagics.CastCounterSkill}, 1)
        if targetId ~= nil and targetId ~= 0 then
            self._proxy:ApplyMagic(self._uuid, targetId, self._cvEventMagics.CastCounterSkill, 1)
        end
    end

    -- 常规高强类技能触发预警事件，主要用于CV响应
    if self:Contain(self._powerfulSkills, skillId) then
        self:ApplyMagicsToSelf({self._cvEventMagics.CastHighDmgSkill}, 1)
    end

    -- 角力联弹技能触发预警事件，主要用于CV响应
    if self:Contain(self._multiQTESkills, skillId) then
        self:ApplyMagicsToSelf({self._cvEventMagics.CastMultiQTESkill }, 1)
    end
end

function XChar8005:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if not self._proxy:CheckNpc(self._uuid) then
        return
    end

    if launcherId ~= self._uuid then return end

    -- 所有技能后确保移除头部IK
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._removeLookAtIKMagic, 1)
    -- 清除技能目标
    self._curActionTarget = nil
    -- 清除当前ActionId
    self._bb:SetSyncVar(self._syncKeys.curActionId, 0)
    -- 重置技能计时器
    self._skillTimer = 0

    -- OD吼解锁韧性
    if skillId == 8005011 then
        self:UnlockGameplayState(false, true, true, true, false, false)
    end

    -- DPS检测锁OD锁削韧
    if skillId == self._ultraEndActionId then
        self:UnlockGameplayState(true, true, true, true, true, false)
        -- 移除所有镜头
        self:ApplyMagicsToAllPlayers(self._ultraCameraRemoveMagics, 1)
        -- 移除狂爆技标记
        self:ApplyMagicsToSelf({1000498}, 1)
    end

    -- 全场喷火结束
    if skillId == 8005301 then
        self:UnlockGameplayState(true, true, true, true, false, false)
        -- 移除狂爆技标记
        self:ApplyMagicsToSelf({1000498}, 1)
    end

    -- Break开始 -> Break循环 触发器
    if skillId == 8005331 then
        self._fightSM:SetTrigger(self._fightSMTriggers.enterBreaking)
    end

    -- 软狂暴吼取消免疫打断
    if skillId == 8005013 then
        self:UnlockGameplayState(false, true, true, true, false, false)
    end

    -- 角力联弹触发攻击 解锁状态
    if skillId == 8005505 then
        self:UnlockGameplayState(true, true, true, true, false, false)
    end
end

function XChar8005:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        return
    end
    -- DPS期间受击逻辑
    if self._proxy:CheckBuffByKind(self._uuid, 8005070) then
        -- 受击特效
        self._proxy:LaunchMissile(self._uuid, self._uuid, 8005112, 8005105)

        -- 检测护盾值
        if self._proxy:GetNpcProtector(self._uuid) <= 0 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005082, 1)
            self:ApplyMagicsToAllPlayers({ 8005467}, 1) -- 移除临时镜头
        end
    end

    -- 不可打断状态
    if self._proxy:CheckBuffByKind(self._uuid, self._immuUltraAbortMagicId) then
        return
    end

    -- 特殊受击(Fullchain终结Hit, 只会向后击退)
    if magicId == 12000108 or magicId == 12000112 or magicId == 12000113 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 8005311)
        return
    end
    -- 特殊受击
    if GameplayTag.CSMatchAnyTag(magicTags, {EGameplayTag.Magic_RelinkDamage_HitType_MultiSupQte}) then
        self:CastUltraHitBySrcPos(launcherId, false)
        return
    end
    if GameplayTag.CSMatchAnyTag(magicTags, {EGameplayTag.Magic_RelinkDamage_HitType_MultiEndQte}) then
        self:CastUltraHitBySrcPos(launcherId, true)
        return
    end
    if GameplayTag.CSMatchAnyTag(magicTags, {EGameplayTag.Magic_RelinkDamage_HitType_Ultra}) then
        self:CastUltraHitBySrcPos(launcherId, false)
        return
    end
    if GameplayTag.CSMatchAnyTag(magicTags, {EGameplayTag.Magic_RelinkDamage_HitType_Break}) then
        self:CastBreakSkill(true)
        return
    end
end

function XChar8005:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
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

    -- 破韧
    if buffId == self._breakMagicId then
        self._isBreaking = true
    end

    -- DPS实际测试开始
    if buffId == 8005070 then
        -- 加护盾值给自己
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._ultraDpsCheckProtectorMagic, 1)
        -- 时间条
        self._proxy:ShowMechanismBar(3, 30, 0, 0, self._uuid, 0, true, true)
    end

    -- 看向目标
    if buffId == self._lookAtIKMagic then
        local curTarget = self:GetSkillTarget()
        if curTarget ~= nil then
            self._proxy:EnableNpcLookAt(self._uuid, curTarget, "HitCase")
        end
    end
end

function XChar8005:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end

    -- 决定DPS检测是否通过
    if buffId == 8005070 then
        if self._proxy:GetNpcProtector(self._uuid) <= 0 then
            -- 优先打断动作防止卡状态
            self._proxy:AbortAction(self._uuid, true)
            -- 移除所有子弹
            self._proxy:DestroyAllMissileDependOnLauncher(self._uuid)
            -- 解锁状态
            self:UnlockGameplayState(true, true, true, true, true, false)
            -- 扣除OD值, DPS检测成功通知
            self:ApplyMagicsToSelf({8005959, 8005915}, 1)
            -- 强制关闭机制条
            self._proxy:HideMechanismBar(3)
            -- 成功语音
            self:ApplyMagicsToAllPlayers({ self._cvMagics.DPSCheckSuccess }, 1)
        else
            self._proxy:AbortAction(self._uuid, true)
            -- 移除所有子弹
            self._proxy:DestroyAllMissileDependOnLauncher(self._uuid)
            self._proxy:CastActionToPosition(self._uuid, self._ultraEndActionId, self._battleSceneCenter)
            --  DPS检测失败通知
            self:ApplyMagicsToSelf({8005916}, 1)
            -- 由于循环走连招系统，这里要确保连招序号推进防止出bug
            self._bb:SetSyncVar(self._syncKeys.curComboId, 1)
            -- 强制关闭机制条
            self._proxy:HideMechanismBar(3)
            -- 失败语音
            self:ApplyMagicsToAllPlayers({ self._cvMagics.DPSCheckFail }, 1)
        end
        -- 碎盾特效子弹
        self._proxy:LaunchMissile(self._uuid, self._uuid, 8005113, 8005106)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005958, 1) -- 关护盾部位
    end

    -- 破韧结束
    if buffId == self._breakMagicId then
        -- 取消硬锁
        self._proxy:CanceAllPlayerBreakResilienceLockTarget()
        self._isBreaking = false
    end

    -- 停止看向目标
    if buffId == self._lookAtIKMagic then
        self._proxy:DisableNpcLookAt(self._uuid)
    end

    -- 角力/多人弹刀移除锁状态
    if buffId == 8005967 then
        -- 解锁状态
        self:UnlockGameplayState(true, true, true, true, true, true)
        -- 移除减伤
        self:ApplyMagicsToSelf({8005555}, 1)
    end
end

function XChar8005:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    -- 确保是自身破韧
    if targetUUID ~= self._uuid then
        return
    end

    -- 确保可被打断，允许QTE
    if not self._proxy:CheckBuffByKind(self._uuid, self._immuUltraAbortMagicId) then
        -- 根据目标位置播破韧动作
        self:CastBreakSkill(false)
    end

    -- 破韧持续时间
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._breakMagicId, 1)
    -- 破韧易伤
    self:ApplyMagicsToSelf({self._breakPhyDefDownMagic}, 1)
    -- 玩家强制看向怪
    --self._proxy:SetAllPlayerBreakResilienceLockToPart(self._uuid, 8001001)
end

function XChar8005:OnNpcEnterOverDrive(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end

    -- 添加标记效果
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._odMarkMagic, 1)
end

function XChar8005:OnNpcODBreakAfter(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end
    -- 状态机触发
    self._fightSM:SetTrigger(self._fightSMTriggers.enterBreak)
end

function XChar8005:OnNpcODExitBreakAfter(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end

    -- 状态机触发
    self._fightSM:SetTrigger(self._fightSMTriggers.exitBreak)
end

function XChar8005:BeforeDamageCalc(eventArgs)
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

function XChar8005:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    Base.OnNpcBeforeTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    -- 非技能目标不能给怪物弹刀表现
    if self._curActionTarget == nil or counterNpcUUID ~= self._curActionTarget then
        return
    end

    self._proxy:DispatchLuaEvent(ELuaEventTarget.All, EFightLuaEvent.RelinkCounterSuccess, { TriggerNpcUUid = triggerNpcUUID, NpcUUid = counterNpcUUID })

    local isSustain = GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_Sustain}) or
            GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Light})
    -- 不打断拼刀(触发盒为sustain或反制盒为light)
    if isSustain then
        -- 通用逻辑部分
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._lightReflectSlomo, 1)    -- 弱顿帧（对自己）
        self._proxy:ApplyMagic(self._uuid, counterNpcUUID, self._lightReflectSlomo, 1)-- 弱顿帧（对目标）

        -- 根据子弹ID的定制化表现,弹刀特效
        if triggerMissileTemplateId == 8005064 or triggerMissileTemplateId == 8005067 then
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005012,  1)
        end
        return
    end

    -- 打断拼刀(触发盒为interrupt)
    local isInterrupt = GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_Interrupt})
    if isInterrupt then
        -- 根据子弹ID的定制化表现
        if triggerMissileTemplateId == 8005065 or triggerMissileTemplateId == 8005069 or triggerMissileTemplateId == 8005169 then
            -- 正面弹
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005317, 1)     -- 自身缓速
            self:ApplyMagicsToTarget(counterNpcUUID, {8005403, 8005458, 8005318}, 1)
            self:ForceCastActionToTarget(8005504, self:GetSkillTarget())
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005000, 8005158,  1)
        elseif triggerMissileTemplateId == 8005063 or triggerMissileTemplateId == 8005066 then
            -- 左弹
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005307, 1)      -- 强顿帧（对自己）
            self:ApplyMagicsToTarget(counterNpcUUID, {8005308, 8005490, 8005459}, 1)
            self:DelayCall("ForceCastActionToTarget", 0.3, 8005502, counterNpcUUID)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005012,  1)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005158,  1)
        elseif triggerMissileTemplateId == 8005062 or triggerMissileTemplateId == 8005068 or triggerMissileTemplateId == 8005180 then
            -- 右弹
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005307, 1)      -- 强顿帧（对自己）
            self:ApplyMagicsToTarget(counterNpcUUID, {8005308, 8005490, 8005459}, 1)
            self:DelayCall("ForceCastActionToTarget", 0.3, 8005503, counterNpcUUID)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005013, 8005013,  1)
            self._proxy:LaunchMissile(self._uuid, counterNpcUUID, 8005012, 8005158,  1)
        end
        return
    end

    local isMulti = GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_MultiInteract}) and
            GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Heavy})
    if isMulti then
        -- 打断动作
        self._proxy:AbortAction(self._uuid, true)
        -- 锁OD, 锁削韧, 防被大招打断, 锁血,  关闭叠加受击
        self:LockGameplayState(true, true, true, true, true, true)
        -- 角力减伤
        self:ApplyMagicsToSelf({8005554}, 1)
        -- 开启QTE交互状态
        self._bb:SetSyncVar(self._syncKeys.IsInQTEInteract, true)
        -- 移除所有角力前攻击镜头
        self:ApplyMagicsToAllPlayers({ 8005481 }, 1)

        if self:IsPlayerTank(counterNpcUUID) then
            -- 安全点保底
            self:CalcAndSetQTEInteractSafePoint(true, counterNpcUUID)
            -- 角力
            self._proxy:CastWrestle(self._uuid, counterNpcUUID, 800501)
        else
            -- 安全点保底
            self:CalcAndSetQTEInteractSafePoint(false, counterNpcUUID)
            -- 多人弹刀
            self._proxy:CastMultiParry(self._uuid, counterNpcUUID, 800501)
            return
        end
    end
end

function XChar8005:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end

function XChar8005:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID, succeed)
    Base.OnNpcWrestleStart(self, launcherNpcUUID, targetNpcUUID, succeed)
    if launcherNpcUUID ~= self._uuid then return end

    -- 显示机制条
    self._proxy:ShowMechanismBar(4, 0, 0, 0, self._uuid, 0, false, true, targetNpcUUID)

    if not succeed then
        self:ExitQTEInteract()
        return
    end
end

function XChar8005:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self, launcherNpcUUID, targetNpcUUID)
    if launcherNpcUUID ~= self._uuid then return end

    self:ExitQTEInteract()
    -- 延迟通知赛利卡发出语音
    self._proxy:AddTimerTask(1.5, function()
        self:ApplyMagicsToSelf({self._cvEventMagics.MultiQTESuccess}, 1)
    end)
end

function XChar8005:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self, launcherNpcUUID, targetNpcUUID)
    if launcherNpcUUID ~= self._uuid then return end

    self:ExitQTEInteract()
    -- 延迟通知赛利卡发出语音
    self._proxy:AddTimerTask(1.5, function()
        self:ApplyMagicsToSelf({self._cvEventMagics.MultiQTESuccess}, 1)
    end)
end

function XChar8005:OnNpcMultiParryStart(launcherNpcUUID, targetNpcUUID, succeed)
    Base.OnNpcMultiParryStart(self, launcherNpcUUID, targetNpcUUID, succeed)
    if launcherNpcUUID ~= self._uuid then return end

    if not succeed then
        self:ExitQTEInteract()
    end
end

function XChar8005:OnNpcMultiParrySucceed(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcMultiParrySucceed(launcherNpcUUID, targetNpcUUID)
    if launcherNpcUUID ~= self._uuid then return end

    self:ExitQTEInteract()
    -- 延迟通知赛利卡发出语音
    self._proxy:AddTimerTask(1.5, function()
        self:ApplyMagicsToSelf({self._cvEventMagics.MultiQTESuccess}, 1)
        XLog.Debug("音频测试：联弹成功！")
    end)
end

function XChar8005:OnNpcMultiParryFail(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcMultiParryFail(launcherNpcUUID, targetNpcUUID)
    if launcherNpcUUID ~= self._uuid then return end

    self:ExitQTEInteract()
end

function XChar8005:ExitQTEInteract()
    -- 锁状态延迟移除buff
    self:ApplyMagicsToSelf({8005967}, 1)
    -- 隐藏机制条
    self._proxy:HideMechanismBar(4)
    self._bb:SetSyncVar(self._syncKeys.IsInQTEInteract, false)
end

function XChar8005:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    if self._uuid ~= AttackerUUID or not self._proxy:IsPlayerNpc(SourceUUID) then
        return
    end

    -- 添加免火盾
    --[[
    if MissileTemplateId == 8005119 then
        self._proxy:ApplyMagic(self._uuid, SourceUUID, 8005960, 1)
    end
    if MissileTemplateId == 8005120 then
        self._proxy:ApplyMagic(self._uuid, SourceUUID, 8005970, 1)
    end
    if MissileTemplateId == 8005121 then
        self._proxy:ApplyMagic(self._uuid, SourceUUID, 8005971, 1)
    end
    ]]
end

function XChar8005:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    if npcUUID ~= self._uuid then
        return
    end

    -- 死亡时如果在软狂暴，移除软狂暴相关状态
    if self._bb:GetSyncVarLocal(self._syncKeys.isFury) then
        self:ApplyMagicsToSelf(self._softFuryDeadRemoveMagics, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000513, 1)
    end
end
--endregion

--region 工具函数
function XChar8005:IsPosSatisfyAngleCond(targetPos, angleCond)
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
function XChar8005:IsTarSatisfyAngleCond(targetUUID, angleCond)
    if not self._proxy:CheckNpc(targetUUID) then
        return false
    end

    local targetPos = self._proxy:GetNpcPosition(targetUUID)
    return self:IsPosSatisfyAngleCond(targetPos, angleCond)
end

--- 将一个数组的效果 由 自己 施加给 目标
function XChar8005:ApplyMagicsToTarget(target, magicIds, level)
    for i, magicId in ipairs(magicIds) do
        self._proxy:ApplyMagic(self._uuid, target, magicId, level)
    end
end

--- 将一个数组的效果 由 自己 施加给 自己
function XChar8005:ApplyMagicsToSelf(magicIds, level)
    self:ApplyMagicsToTarget(self._uuid, magicIds, level)
end

--- 给所有玩家添加效果
--- @param magicIds table @ magicId数组
--- @param level number @ level等级
function XChar8005:ApplyMagicsToAllPlayers(magicIds, level)
    for k, playerId in ipairs(self._proxy:GetPlayerNpcList()) do
        self:ApplyMagicsToTarget(playerId, magicIds, level)
    end
end

--- 获取仇恨列表内，除了当前仇恨目标以外的所有玩家
function XChar8005:GetNonAggroPlayerList()
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
function XChar8005:IsPlayerTank(playerId)
    return self._proxy:CheckBuffByKind(playerId, 1000487)
end

--- 检测玩家是否为输出位
function XChar8005:IsPlayerCarry(playerId)
    return self._proxy:CheckBuffByKind(playerId, 1000486)
end

--- 检测玩家是否为奶/支援位
function XChar8005:IsPlayerSup(playerId)
    return self._proxy:CheckBuffByKind(playerId, 1000488)
end

--- 朝目标释放技能
function XChar8005:CastActionToTarget(actionId, targetUUID)
    self._proxy:CastActionToTarget(self._uuid, actionId, targetUUID)
end

--- 强制打断当前技能后，朝目标释放技能
function XChar8005:ForceCastActionToTarget(actionId, targetUUID)
    self._proxy:AbortAction(self._uuid, true)                                   -- 打断动作
    self:CastActionToTarget(actionId, targetUUID)   -- 动作
end

--- 修正角力和多人弹刀的起始位置，该方案需要确保场景大小比角力所需空间要大，否则不给予正确修正
function XChar8005:CalcAndSetQTEInteractSafePoint(isWrestle, targetUUID)
    -- 禁用功能则不修正
    if not self._enableQTEInteractFix then
        return
    end

    -- 计算场景上下左右的值
    local left = self._battleSceneCenter.x - self._battleAreaHalfSize.x
    local right = self._battleSceneCenter.x + self._battleAreaHalfSize.x
    local top = self._battleSceneCenter.z + self._battleAreaHalfSize.z
    local bottom = self._battleSceneCenter.z - self._battleAreaHalfSize.z

    local safeRadius = self._wrestleSafeRadius
    if not isWrestle then
        safeRadius = self._multiParrySafeRadius
    end

    -- 检测当前位置是否处于安全范围内
    local myPos = self._proxy:GetNpcPosition(self._uuid)
    local isInsideHori = ((left + safeRadius) <= myPos.x) and ((right - safeRadius) >= myPos.x)
    local isInsideVert = ((top - safeRadius) >= myPos.z) and ((bottom + safeRadius) <= myPos.z)

    local safePos = { x = myPos.x, y = 1, z = myPos.z }

    -- 安全直接返回
    if isInsideHori and isInsideVert then
        return
    end

    -- 不安全，计算挤压后的安全位置
    local leftDistance = myPos.x - left
    local rightDistance = right - myPos.x
    local topDistance = top - myPos.z
    local bottomDistance = myPos.z - bottom

    if leftDistance < safeRadius then
        safePos.x = left + safeRadius
    elseif rightDistance < safeRadius then
        safePos.x = right - safeRadius
    end

    if bottomDistance < safeRadius then
        safePos.z = bottom + safeRadius
    elseif topDistance < safeRadius then
        safePos.z = top - safeRadius
    end

    -- 计算目标位置并设置
    local safePosVec2 = { safePos.x, safePos.z }
    local myPosVec2 = { myPos.x, myPos.z }
    local dir = self:SubtractVector2(safePosVec2, myPosVec2)

    local tarPos = self._proxy:GetNpcPosition(targetUUID)
    local tarSafePosVec2 = self:AddVector2({ tarPos.x, tarPos.z }, dir)
    local tarSafePos = { x = tarSafePosVec2[1], y = 1, z = tarSafePosVec2[2] }

    self._proxy:SetNpcPosition(self._uuid, safePos, false)
    self._proxy:SetNpcPosition(targetUUID, tarSafePos, false)
end

--- 检测table中是否拥有某元素
function XChar8005:Contain(tableToCheck, targetElement)
    for k, v in pairs(tableToCheck) do
        if v == targetElement then
            return true
        end
    end
    return false
end

---锁定玩法相关的状态
---@param overDrive boolean @锁OD
---@param tenaBreak boolean @锁破韧
---@param tenaChange boolean @锁削韧
---@param ultraHit boolean @锁大招打断
---@param health boolean @锁血
---@param additionHit boolean @锁叠加受击
function XChar8005:LockGameplayState(overDrive, tenaBreak, tenaChange, ultraHit, health, additionHit)
    if overDrive then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1) -- 锁OD
    end
    if tenaBreak then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000467, 1) -- 锁破韧
    end
    if tenaChange then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000469, 1) -- 锁削韧
    end
    if ultraHit then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._immuUltraAbortMagicId, 1) -- 防被大招打断
    end
    if health then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000446, 1) -- 锁血
    end
    if additionHit then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005968, 1) -- 锁叠加受击
    end
end

---解锁玩法相关的状态
---@param overDrive boolean @解锁OD
---@param tenaBreak boolean @解锁破韧
---@param tenaChange boolean @解锁削韧
---@param ultraHit boolean @解锁大招打断
---@param health boolean @解锁血
------@param additionHit boolean @解锁叠加受击
function XChar8005:UnlockGameplayState(overDrive, tenaBreak, tenaChange, ultraHit, health, additionHit)
    if overDrive then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1) -- 解锁OD
    end
    if tenaBreak then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1) -- 解锁破韧
    end
    if tenaChange then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000470, 1) -- 解锁削韧
    end
    if ultraHit then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cancelImmuUltraAbortMagicId, 1) -- 取消防被大招打断
    end
    if health then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000447, 1) -- 移除锁血
    end
    if additionHit then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005969, 1) -- 解锁叠加受击
    end
end
--endregion

--region 数学
--- 将val的值限制在min和max之间，随后返回
--- @param val number @ 需要限制的值
--- @param min number @ 区间最小值
--- @param max number @ 区间最大值
--- @return number @ 限制后的值
function XChar8005:Clamp(val, min, max)
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

function XChar8005:CheckPosInAngle(pos, from, to)
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
function XChar8005:CheckTargetInAngle(targetUUID, from, to)
    local targetPos = self._proxy:GetNpcPosition(targetUUID)
    return self:CheckPosInAngle(targetPos, from, to)
end

--- 旋转一个二维向量（这里用于计算XZ平面的旋转，即Y轴旋转）
--- @param vector @ 二维向量table
--- @param deg @ 旋转角度
--- @return @ 旋转后的向量
function XChar8005:RotateVector2(vector, deg)
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
function XChar8005:GetVector2Magnitude(vector)
    return math.sqrt(vector[1]^2 + vector[2]^2)
end

--- 二维向量归一化
function XChar8005:NormalizeVector2(vector)
    local mag = self:GetVector2Magnitude(vector)
    return { vector[1] / mag, vector[2] / mag }
end

--- 二维向量点乘
function XChar8005:DotProduct(vectorA, vectorB)
    return vectorA[1] * vectorB[1] + vectorA[2] * vectorB[2]
end

--- 二维向量减法
function XChar8005:SubtractVector2(vectorA, vectorB)
    return { vectorA[1] - vectorB[1], vectorA[2] - vectorB[2] }
end

--- 二维向量加法
function XChar8005:AddVector2(vectorA, vectorB)
    return { vectorA[1] + vectorB[1], vectorA[2] + vectorB[2] }
end

--- 二维向量缩放
function XChar8005:ScaleVector2(vector, scalar)
    return { vector[1] * scalar, vector[2] * scalar }
end

        --- 浮点数插值
        --- @param u number @ 起始值
        --- @param v number @ 最终值
        --- @param t number @ 插值位置（0 - 1之间）
        --- @param interpMode @ 插值类型
function XChar8005:InterpFloat(u, v, t, interpMode)
    if interpMode == XChar8005.EInterpMode.EaseOutCubic then
        t = 1 - (1 - t)^3
    end

    return u * (1 - t) + v * t
end
--endregion

--region 技能表现相关杂项
--- 大招激光更新逻辑
function XChar8005:UltraRayUpdateLogic()
    -- 逻辑阻断
    if not self._isUltraRayStart then
        return
    end

    -- 更新计时器
    local curNpcTime = self._proxy:GetNpcTime(self._uuid)
    local scaledDeltaTime = curNpcTime - self._ultraRayLastNpcTime
    self._ultraRayTimer = self._ultraRayTimer + scaledDeltaTime
    self._ultraRayLastNpcTime = curNpcTime

    -- 逻辑结束
    if self._ultraRayTimer >= self._ultraRayStopTime then
        self._isUltraRayStart = false
        return
    end

    -- 开始延迟
    if self._ultraRayTimer <= self._ultraRayStartTime then
        return
    end

    self._ultraRayIntervalTimer = self._ultraRayIntervalTimer - scaledDeltaTime
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


    self._ultraPoissonDiskTimer = self._ultraPoissonDiskTimer - scaledDeltaTime
    if self._ultraPoissonDiskTimer <= 0 then
        local poissonDiskPoints = self._proxy:PoissonDiscPoints(self._ultraPoissonDiskWidth, self._ultraPoissonDiskHeight, self._ultraPoissonDiskRadius)
        -- 有效性检测
        local isValid = poissonDiskPoints ~= nil and
        #poissonDiskPoints > 0 and
        #poissonDiskPoints % 2 == 0

        if isValid then
            self._ultraPoissonDiskPerInterval = self._ultraPoissonDiskInterval / #poissonDiskPoints
            self._ultraPoissonDiskPerCount = 0
            self._ultraPoissonDiskPoints = poissonDiskPoints
        end

        -- 刷新计时器
        self._ultraPoissonDiskTimer = self._ultraPoissonDiskInterval
    end

    self._ultraPoissonDiskPerTimer = self._ultraPoissonDiskPerTimer - scaledDeltaTime
    if self._ultraPoissonDiskPerTimer <= 0 and self._ultraPoissonDiskPoints ~= nil then
        if self._ultraPoissonDiskPerCount < ((#self._ultraPoissonDiskPoints / 2) - 1) then
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

--region 状态机
function XChar8005:InitFightStateMachine()
    self._fightSMTriggers =
    {
        activate = 0,
        enterBreak = 1,
        enterBreaking = 2,
        exitBreak = 3,
    }

    --- @type RelinkStateMachine
    self._fightSM = RelinkStateMachine.New("白龙战斗状态机")

    self._enterNormal = function()
        if self._enableSoftFury and self._bb:GetSyncVarLocal(self._syncKeys.isFury) then
            self._curSkillSeq = self._intendSkillSeqs[3][1]
        else
            -- 重置技能轴
            local newBattleLoopIdx = self._bb:GetSyncVarLocal(self._syncKeys.battleLoopIdx) + 1
            if #self._skillSeqLoopKeys > 0 then
                if newBattleLoopIdx > #self._skillSeqLoopKeys then
                    newBattleLoopIdx = 1
                end
            else
                newBattleLoopIdx = 0
            end
            self._bb:SetSyncVar(self._syncKeys.battleLoopIdx, newBattleLoopIdx)

            -- 设立技能轴
            if newBattleLoopIdx > 0 then
                local key = self._skillSeqLoopKeys[newBattleLoopIdx]
                self._curSkillSeq = self._intendSkillSeqs[key][1]
            end
        end

        -- 技能索引刷新
        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
        -- 刷新CD
        self:RefreshSkillCD(false)
    end
    self._enterOD = function()
        if self._enableSoftFury and self._bb:GetSyncVarLocal(self._syncKeys.isFury) then
            self._curSkillSeq = self._intendSkillSeqs[3][2]
        else
            -- 设立技能轴
            local battleLoopIdx = self._bb:GetSyncVarLocal(self._syncKeys.battleLoopIdx)
            if battleLoopIdx > 0 then
                local key = self._skillSeqLoopKeys[battleLoopIdx]
                self._curSkillSeq = self._intendSkillSeqs[key][2]
            end
        end

        -- 技能索引刷新
        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)

        -- 刷新CD
        self:RefreshSkillCD(false)
    end
    self._enterODBreak = function()
        -- 播放进入OD Break动作
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, self._odBreakEnterSkill)

        -- 移除绑定强化特效
        self:ApplyMagicsToSelf({8005212, 8005213, 8005214, 8005215, 8005216, 8005217, 8005218, 8005219, 8005220}, 1)
        -- 移除隐藏浮游炮的buff
        self:ApplyMagicsToSelf({8005043, 8005044, 8005045, 8005046, 8005047, 8005048, 8005051, 8005051 }, 1)
        -- 移除OD标记, 自身时停, 移除减伤, 添加易伤, OD结束特效
        self:ApplyMagicsToSelf({self._odMarkRemoveMagic, 8005302, 8005553, 8005556, 8005211}, 1)
        -- 锁状态
        self:LockGameplayState(false, true, true, true, false, false)
        -- 时停, 碎屏特效，镜头拉近
        self:ApplyMagicsToAllPlayers({8005302, 8005201, 8005401}, 1)

        -- 给玩家团队技能量
        local hasGiveEnergy = false
        for k, playerID in ipairs(self._proxy:GetPlayerNpcList()) do
            if not hasGiveEnergy and self._proxy:CheckNpc(playerID) and not self._proxy:IsNpcDead(playerID) then
                self._proxy:AddTeamWorkEnergy(playerID, 50)                        -- 给50能量
                hasGiveEnergy = true
            end
        end

        -- 超算开始特效(-> 子子弹超算持续特效)
        self._proxy:LaunchMissile(self._uuid, self._uuid, 8005000, 8005174, 1)
    end
    self._enterODBreaking = function()
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, self._odBreakLoopSkill)
    end
    self._exitODBreaking = function()
        -- 退出OD Break状态
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionEx(self._uuid, self._odBreakExitSkill)

        -- 解锁状态
        self:UnlockGameplayState(false, true, true, true, false, false)
        -- 移除易伤
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8005557, 1)
        -- 超算结束特效
        self._proxy:LaunchMissile(self._uuid, self._uuid, 8005000, 8005176, 1)
    end

    self._fightSM:AddState(XChar8005.EFightState.Inactive, "未激活", nil, nil, nil, math.huge)
    self._fightSM:AddState(XChar8005.EFightState.Normal, "常规", self._enterNormal, nil, nil, math.huge)
    self._fightSM:AddState(XChar8005.EFightState.OD, "OD", self._enterOD, nil, nil, math.huge)
    self._fightSM:AddState(XChar8005.EFightState.ODBreakStart, "ODBreak开始", self._enterODBreak, nil, nil, 1.733)
    self._fightSM:AddState(XChar8005.EFightState.ODBreaking, "ODBreak中", self._enterODBreaking, nil, self._exitODBreaking, math.huge)

    self._fightSM:AddTrigger(self._fightSMTriggers.activate)
    self._fightSM:AddTrigger(self._fightSMTriggers.enterBreak)
    self._fightSM:AddTrigger(self._fightSMTriggers.enterBreaking)
    self._fightSM:AddTrigger(self._fightSMTriggers.exitBreak)

    self._inactiveToNormal = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.activate)
    end
    self._normalToOD = function()
        return self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.OverDrive) >= self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.OverDrive)
    end
    self._odToODBreakStart = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.enterBreak)
    end
    self._odBreakStartToOdBreaking = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.enterBreaking)
    end
    self.odBreakStartToNormal = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.exitBreak)
    end
    self.odBreakingToNormal = function()
        return self._fightSM:CheckTrigger(self._fightSMTriggers.exitBreak)
    end

    self._fightSM:AddTransition(XChar8005.EFightState.Inactive, XChar8005.EFightState.Normal, 0, self._inactiveToNormal, 0, 0)
    self._fightSM:AddTransition(XChar8005.EFightState.Normal, XChar8005.EFightState.OD, 0, self._normalToOD, 0, 0)
    self._fightSM:AddTransition(XChar8005.EFightState.OD, XChar8005.EFightState.ODBreakStart, 0, self._odToODBreakStart, 0, 0)
    self._fightSM:AddTransition(XChar8005.EFightState.ODBreakStart, XChar8005.EFightState.ODBreaking, 0, nil, 0, 0.9)
    self._fightSM:AddTransition(XChar8005.EFightState.ODBreakStart, XChar8005.EFightState.Normal, 1, self.odBreakStartToNormal, 0, 0)
    self._fightSM:AddTransition(XChar8005.EFightState.ODBreaking, XChar8005.EFightState.Normal, 0, self.odBreakingToNormal, 0, 0)

    self._onFightSMStateChangedHandler = function(previousStateId, nextStateId)
        -- 规避初始进入时候，首个stateId为nil导致报错的情况
        local previousState = nil
        if previousStateId ~= nil then
            previousState = self._fightSM:GetState(previousStateId)
        end
        local nextState = self._fightSM:GetState(nextStateId)

        -- 初始进入战斗状态时，给全场玩家加仇恨值(T+5000, 非T+1), 强制刷一遍CD
        if previousStateId == XChar8005.EFightState.Inactive and nextStateId == XChar8005.EFightState.Normal then
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

        -- ODBreak开始 转到 ODBreak结束，也调用一下退出的逻辑
        if previousStateId == XChar8005.EFightState.ODBreakStart and nextStateId == XChar8005.EFightState.Normal then
            -- 退出OD Break状态
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionEx(self._uuid, self._odBreakExitSkill)

            -- 移除锁破韧
            self:UnlockGameplayState(false, true, true, true, false, false)
            -- 移除易伤
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005557, 1)
            -- 超算结束特效
            self._proxy:LaunchMissile(self._uuid, self._uuid, 8005000, 8005176, 1)
        end

        self._bb:SetSyncVar(self._syncKeys.fightStateId, nextStateId)
    end
    self._fightSM:RegisterOnStateChanged(self._onFightSMStateChangedHandler)
end
--endregion

return XChar8005