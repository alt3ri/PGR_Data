local base = require("Common/XFightBase")
---Relink角色底层
---@class XRelinkCharBase : XFightBase
---@field _followController XNpcFollowController 跟随组件
local XRelinkCharBase = XClass(base, "XRelinkCharBase")

function XRelinkCharBase:Init() --初始化
    base.Init(self)
    self:RegisterKeyboard()   --注册按键映射
    self:InitHandleJumpTurnSpeedParams()  --初始化跳跃相关逻辑
    -- 这其实是每个Npc都在调用Camera的全局开关, 行为树版本也一样，待v0.3或v0.4版本优化
    self._proxy:SetCameraIgnoreHeightLerpOnAir(false)
    self._DodgeIsNotCd = true
    self:JumpWeaponHidShowCheckInit()
    --- 弹刀无敌通用buff id
    self._counterImmortalMagicId = 1000479
    self:RebootCheckInit()--复活初始化
    --- 初始化隐藏qte按钮
    self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,false)
    --- 破韧通知buff
    self._BreakQteBuff = 8005902
end

---@param dt number @ delta time 
function XRelinkCharBase:Update(dt)
    if self._proxy:IsNpcBackState(self._uuid) then -- 在后台不触发逻辑
        return
    end
    self:JumpWeaponHidShowCheck()
    self:HardLockInput() --手动锁定
    self:ProcessChangeMoveState()
    self:ProcessResetSprintMoveTypeOnJump()
    self:ProcessHandleJumpTurnSpeed()
    self:ProcessChangeJumpState()
    self:RebootCheckUpdate()
end

---@param eventType number
---@param eventArgs userdata
function XRelinkCharBase:HandleEvent(eventType, eventArgs) --事件中转站
    base.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcCastActionByInputActionBefore then
        -- XLog.Warning("InputNPC:" ..eventArgs.LauncherId)
        self:OnNpcCastActionByInputActionBeforeEvent(eventArgs)
    end
    if eventType == EWorldEvent.LockTargetChanged then --锁定变更事件
        self:OnLockTargetChanged(eventArgs.CurTargetUID,eventArgs.LastTargetUID,eventArgs.LockTargetType)
    end
    if eventType == EWorldEvent.FullChainSkillStart then
        self:OnFullChainSkillStart(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.FullChainSkillEnd then
        self:OnFullChainSkillEnd(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.CastFullChainFinalSkill then
        self:OnCastFullChainFinalSkill(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.FullChainStageEnd then
        self:OnFullChainStageEnd(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
end

---跳跃武器显隐藏初始化
function XRelinkCharBase:JumpWeaponHidShowCheckInit()
    self.lastActionIsJump = false --上一个状态是否是跳跃
end

---跳跃控制武器显隐
function XRelinkCharBase:JumpWeaponHidShowCheck()
    local isJumping = self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) or self._proxy:CheckNpcAction(self._uuid, ENpcAction.Move)--当前是否在跳跃中
    if self.lastActionIsJump and (not isJumping)then
        self:OnExitJumpWeaponShow()
    end

    if (not self.lastActionIsJump) and isJumping then
        self:OnEnterJumpWeaponHide()
    end
    self.lastActionIsJump = isJumping
end

---进入跳跃隐藏武器
function XRelinkCharBase:OnEnterJumpWeaponHide()

end

---退出跳跃隐藏武器
function XRelinkCharBase:OnExitJumpWeaponShow()

end

--region 复活系统
---复活检查初始化
function XRelinkCharBase:RebootCheckInit()
    self.rebootCount = 1 --第几次复活
    self.lastDead = false --默认存活
end

---复活系统Update检查
function XRelinkCharBase:RebootCheckUpdate()
    
    local isDead = self._proxy:IsNpcDead(self._uuid)
    
    if self.lastDead and (not isDead) then
        self.lastDead = false
        if self.rebootCount< 3 then --小于3次才处理
            if self.rebootCount == 1 then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1000482,1)--下次复活值加1500
                self.rebootCount = 2
            elseif self.rebootCount == 2  then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1000483,1)--下次复活值加3000
                self.rebootCount = 3
            end
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000485)--去除支援特效
    end

    if (not self.lastDead) and isDead then
        self.lastDead = true
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000484)--挂上支援特效
    end
    
end


--endregion

---FullChain开启连锁
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XRelinkCharBase:OnFullChainSkillStart(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
end

---FullChain连锁结束
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XRelinkCharBase:OnFullChainSkillEnd(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
end

---FullChainSkill释放！
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XRelinkCharBase:OnCastFullChainFinalSkill(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
end

---FullChainSkill释放！
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XRelinkCharBase:OnFullChainStageEnd(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
end


function XRelinkCharBase:Terminate()
end

--region Keyboard 按键映射
function XRelinkCharBase:RegisterKeyboard()  --按键注册
    -- XLog.Warning("----------准备注册按键映射----------")
    -- XLog.Warning("----------注册按键映射完成----------")
end
--endregion

--region AttackTarget 索敌

--endregion

--region ChangeMoveState 空花角色移动状态逻辑
function XRelinkCharBase:ProcessChangeMoveState()
    -- Try Do = Check Can Do + Select Do What
    local isChange, nextMoveType = self:TryDoChangeMoveState()
    -- Do
    if not isChange then
        return
    end
    self._proxy:SetNpcMoveType(self._uuid, nextMoveType)
end
---决策将要切换的移动状态
---@return boolean,number isChange, ENpcMoveType
function XRelinkCharBase:TryDoChangeMoveState()

    -- Select Do What
    local curMoveType = self._proxy:GetNpcMoveType(self._uuid)      -- Npc当前移动状态
    local nextMoveType = curMoveType                                -- Npc将要切换的移动状态
    local moveNormalizedDist = self._proxy:GetMoveNormalizedDist()  -- 摇杆用力量化长度
    local normalizedWalk2Run = 0.4                                  -- 慢走阈值
    local normalizedRun2Sprint = 1                                  -- 疾跑阈值


    if curMoveType == ENpcMoveType.Walk then
        if moveNormalizedDist >= normalizedWalk2Run and moveNormalizedDist < normalizedRun2Sprint then                  -- 摇杆大于慢走阈值则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        end
    elseif curMoveType == ENpcMoveType.Run then
        if moveNormalizedDist > 0 and moveNormalizedDist <= normalizedWalk2Run then                                     -- 摇杆小于慢走阈值且不为0则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        end
    elseif curMoveType == ENpcMoveType.Sprint then
        if moveNormalizedDist == 0 then                                                                                 -- 停止输入切换到普通跑
            nextMoveType = ENpcMoveType.Run
        elseif moveNormalizedDist <= normalizedWalk2Run and moveNormalizedDist > normalizedWalk2Run then                -- 摇杆小于慢走阈值且不为0则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchWalk) then                                                  -- 点击了慢走切换按键则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchSprint) then                                                -- 点击了疾跑切换则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        end
    end
    return curMoveType ~= nextMoveType, nextMoveType
end
--endregion

--region HandleJumpTurnSpeed 空花角色处理跳跃转向速度
function XRelinkCharBase:InitHandleJumpTurnSpeedParams()
    self._proxy:SetNpcJumpLookAtSpeed(self._uuid, 0)--初始甚至成0
    self._jumpTurnSpeed_IdleJumpUp = 700
    self._jumpTurnSpeed_IdleJumpOnAir = 700
    self._jumpTurnSpeed_IdleJumpUpToDown = 550
    self._jumpTurnSpeed_IdleJumpDown = 0
    self._jumpTurnSpeed_IdleJumpDownLoop = 0
    self._jumpTurnSpeed_MoveJumpUp = 700
    self._jumpTurnSpeed_MoveJumpOnAir = 700
    self._jumpTurnSpeed_MoveJumpUpToDown = 550
    self._jumpTurnSpeed_MoveJumpDown = 0
    self._jumpTurnSpeed_MoveJumpDownLoop = 0
end

function XRelinkCharBase:ProcessHandleJumpTurnSpeed()
    -- Check Can Do
    if not self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 不是跳跃状态不设置速度
        return
    end
    -- Select & Do
    if self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpUp) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpUp)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpOnAir) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpOnAir)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpUpToDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpUpToDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpDownLoop) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpDownLoop)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpUp) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpUp)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpOnAir) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpOnAir)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpUpToDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpUpToDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpDownLoop) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpDownLoop)
    end
end
--endregion

--region ChangeJumpMoveState 空花角色空中根据输入重置冲刺移动状态
function XRelinkCharBase:ProcessResetSprintMoveTypeOnJump()
    -- Check Can Do
    if not self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 角色不在跳跃不重置
        return false
    end

    if not (self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.None) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpToStand) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpToStand)) then    -- 除跳跃落地阶段外外，其它状态无法跳跃
        return false
    end

    -- Select Do What
    local curMoveType = self._proxy:GetNpcMoveType(self._uuid)          -- Npc当前移动状态
    local moveNormalizedDist = self._proxy:GetMoveNormalizedDist()      -- 摇杆用力量化长度
    local normalizedRun2Sprint = 1                                      -- 疾跑阈值

    if curMoveType == ENpcMoveType.Sprint and moveNormalizedDist < normalizedRun2Sprint then
        self._proxy:SetNpcMoveType(self._uuid, ENpcMoveType.Run)
    end
end
--endregion

--region ChangeJumpState 空花角色跳跃状态逻辑
function XRelinkCharBase:ProcessChangeJumpState()
    -- Check Can Do
    if not self._proxy:IsKeyDown(ENpcOperationKey.Jump) then                                -- 没有按键也不跳 (低频条件可优先判断)
        return false
    end
    if self._proxy:CheckNpcOnAir(self._uuid) then                                           -- 空中没有二段跳
        return false
    end
    if not (self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.None) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpToStand) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpToStand)) then    -- 除跳跃落地阶段外外，其它状态无法跳跃
        return false
    end
    
    if not (self._proxy:CheckCanCastSkill(self._uuid) and self._proxy:CheckNpcCurActionIsDone(self._uuid)) then --技能状态时需要在技能完成时跳
        return false
    end
    -- Select Do What
    local isHasMoveInput = self._proxy:HasMoveInput()
    -- Do Jump
    if isHasMoveInput then
        self._proxy:Jump(self._uuid, true)
    else
        self._proxy:Jump(self._uuid, false)
    end
end
--endregion

--region EventCallBack
function XRelinkCharBase:InitEventCallBackRegister()
    --按需求解除注释进行注册
    XLog.Warning("开始注册")

    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore)         -- OnNpcCastActionBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastActionAfterEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionByInputActionBefore)         -- OnNpcCastActionByInputActionBeforeEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)         -- OnNpcExitActionEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)               -- OnNpcDieEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRevive)            -- OnNpcReviveEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcWaitReboot)        -- OnNpcWaitRebootEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcLoadComplete)      -- OnNpcLoadCompleteEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)               --OnNpcDodge
    --self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg)   -- OnBehavior2ScriptMsgEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileHit)           -- OnMissileHitEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileDead)          -- OnMissileDeadEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileCreate)        -- OnMissileCreateEvent
    self._proxy:RegisterEvent(EWorldEvent.LockTargetChanged)      -- OnLockTargetChanged
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillStart)      --OnFullChainSkillStart
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillEnd)        --OnFullChainSkillEnd
    self._proxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill)        --OnCastFullChainFinalSkill
    self._proxy:RegisterEvent(EWorldEvent.FullChainStageEnd)        --OnFullChainStageEnd

    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess, self._uuid)  -- OnNpcCounterSuccess
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterSyncCounterSuccess, self._uuid) -- OnNpcAfterSyncCounterSuccess

    XLog.Warning("Relink基类注册事件")
end

--设置技能释放前上下文
function XRelinkCharBase:OnNpcCastActionByInputActionBeforeEvent(args)
    local skillId = args.SkillId
    local launcher = args.LauncherUUID
    local contextId = args.ContextId

    if not launcher == self._uuid then
        return
    end
   --检查当前是否拥有锁定目标
    local locktaregetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
    if npcid == 0 and locktaregetid == 0 then
        return
    end
    local targetPos = self._proxy:GetSearchTargetPosition(locktaregetid) -- 获取技能目标位置
    --XLog.Warning("新索敌目标"..locktaregetid)
    self._proxy:SetCastSkillByInputActionBeforeValue(contextId, ESkillTargetType.Npc, npcid, targetPos,locktaregetid) --设置技能上下文
end


--demo基础索敌逻辑
function XRelinkCharBase:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    --技能目标为自己，返回
    if TargetId == self._uuid then
        return
    end

    --技能目标为空，执行搜索
    if TargetId == 0 then
        --新索敌节点逻辑处理（新锁定包装了npc与部位，在锁定前无法分拆）
        local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy) --新索敌获取权重最高目标，搜寻规则见表
        --搜索目标为空，返回
        if searchtarget == 0 then
            return
        end
        self._proxy:SetSoftLock(LauncherId,searchtarget) --直接使用新索敌获得目标设置为软锁目标，新索敌获得的id不可读，为组合生成内容
        local locktargetid, npcid = self._proxy:GetLockTarget()--转换新索敌目标为搜索目标id，npcuuid
        self._proxy:SetNpcFocusTarget(LauncherId, npcid)  --镜头锁定
    end
    if TargetId ~= 0 then
        local locktargetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
        self:CheckFocusTarget()
        if locktargetid == 0 then
            return
        end
    end
end

function XRelinkCharBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == self._BreakQteBuff  then
        self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,true)
    end
end

function XRelinkCharBase:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == self._BreakQteBuff  then
        self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,false)
    end
end

function XRelinkCharBase:OnNpcDodge(SourceUUID, AttackerUUID, Type)
    
    if (SourceUUID ~= self._uuid) then
        return
    end

    if (Type == 1) then 
        if not self._DodgeIsNotCd then
            return
        end

        XLog.Warning("极限闪避成功:")

        self._proxy:AddBuff(self._uuid, 10510701)
        self._proxy:AddBuff(self._uuid, 10510702)
        self._proxy:AddBuff(self._uuid, 10510703)
        self._proxy:AddBuff(self._uuid, 10510705)
        self._DodgeIsNotCd = false

        self._proxy:AddTimerTask(  1,  function()
            self._DodgeIsNotCd = true
        end)
    end
end

function XRelinkCharBase:HardLockInput() -- tab键手动锁定
    --XLog.Warning("update手动锁定")
    if self._proxy:IsKeyDown(ENpcOperationKey.Focus) then  --按下tab键
        local locktarget, _ = self._proxy:GetLockTarget()
        if locktarget ~= 0 then               --锁定目标不为空
            local locktargettype = self._proxy:GetCurLockTargetType()
            self._proxy:ApplyMagic(self._uuid,self._uuid,105296,1)  --限制镜头拖动输入
            self:CheckFocusTarget()
            if locktargettype == ELockTargetType.ForceLock then   --强制锁定，直接返回
                return
            elseif locktargettype == ELockTargetType.HardLock then    --硬锁定，执行切换锁定目标逻辑
                local searchtargetlist = self._proxy:GetSearchTargetList(self._uuid, ENpcTargetType.Enemy)
                if searchtargetlist == nil then
                    return
                end
                for _ , target in pairs(searchtargetlist) do
                    if target == nil then
                        return
                    end
                    if target ~= locktarget then
                        self._proxy:SetHardLock(self._uuid,target)
                        break
                    end
                end
            else
                self._proxy:SetHardLock(self._uuid,locktarget)
            end
        else
            local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
            if searchtarget == 0 then
                return
            end
            self._proxy:SetHardLock(self._uuid,searchtarget)
            local _, npc = self._proxy:GetLockTarget()
            --self._proxy:SetNpcFocusTarget(self._uuid, npc)
            --self._proxy:ApplyMagic(self._uuid,self._uuid,105296,1)  --限制镜头拖动输入
        end
    end
    local iskeyhold,holdtime = self._proxy:IsKeyHold(8)
    if iskeyhold and holdtime >= 0.5 then --长按tab键手动取消
        --self._proxy:ApplyMagic(self._uuid,self._uuid,105297,1)  --移除限制镜头拖动输入
        self._proxy:CancelHardLockTarget(self._uuid)
        self._proxy:CancelSoftLockTarget(self._uuid)
        --self._proxy:RemoveNpcFocusTarget(self._uuid)
    end
end

function XRelinkCharBase:OnLockTargetChanged(CurTargetUID,LastTargetUID,LockTargetType) --监听锁定变更事件
    --[[
    local locktarget,_ = self._proxy:GetLockTarget()
    if locktarget == 0 then --无锁定时移除镜头维持逻辑
        self._proxy:RemoveNpcFocusTarget(self._uuid)
    end
    --]]
end

function XRelinkCharBase:CheckFocusTarget() --若当前有锁定，但是通过拖动镜头移除了镜头维持目标，重新设置
    local focustargetid = self._proxy:GetNpcFocusTarget(self._uuid)
    local _,locknpc = self._proxy:GetLockTarget()
    --XLog.Warning("确认镜头维持目标"..focustargetid)
    --XLog.Warning("确认"..locknpc)
    if focustargetid == 0 and locknpc ~= 0 then
        --XLog.Warning("重锁")
        self._proxy:SetNpcFocusTarget(self._uuid, locknpc)
    end
end

function XRelinkCharBase:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    -- 弹刀成功后无敌
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._counterImmortalMagicId, 1)
end

function XRelinkCharBase:OnNpcAfterSyncCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end
--endregion

---npc死亡事件
function XRelinkCharBase:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID ~= self._uuid then
        return  
    end
    XLog.Warning("我死了"..self._uuid)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000480,1)--死亡次数标记buff，每次一次都加一层
end

---npc复活事件
function XRelinkCharBase:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID ~= self._uuid then
        return
    end
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000478,1)--复活无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000477,1)--复活特效
end

return XRelinkCharBase