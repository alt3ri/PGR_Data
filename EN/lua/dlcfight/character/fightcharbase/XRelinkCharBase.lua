local base = require("Common/XFightBase")
---Relink角色底层
---@class XRelinkCharBase : XFightBase
---@field _followController XNpcFollowController 跟随组件
local XRelinkCharBase = XClass(base, "XRelinkCharBase")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local EFightCVAction = require("Enum/XFightCVAction")

function XRelinkCharBase:ScriptInit(isGainControl)
    self:RegisterKeyboard()   --注册按键映射
    self:InitHandleJumpTurnSpeedParams()  --初始化跳跃相关逻辑
    ---- 这其实是每个Npc都在调用Camera的全局开关, 行为树版本也一样，待v0.3或v0.4版本优化
    --self._proxy:SetCameraIgnoreHeightLerpOnAir(false)
    self._DodgeIsNotCd = true
    self:JumpWeaponHidShowCheckInit()
    --- 弹刀无敌通用buff id
    self._counterImmortalMagicId = 1000479
    self:RebootCheckInit()--复活初始化
    --- 初始化隐藏qte按钮
    self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,false)
    --- 破韧通知buff
    self._BreakQteBuff = 1000492
    --- 闪避能量禁止恢复buff
    self._BanDodgeRecoverBuff = 1000515
    --- 闪避能量Check开关
    self._DodgeCheck = true
    --初始化团队极限技使用次数
    -- self._proxy:SetTeamWorkSkillNpcRemainUseCount(self._uuid,1)

    -- 属性记录
    self._attribRecordInterval = 0.5
    self._attribRecordTimer = 0
    self._curLifeRatio = 0

    -- 初始化CV
    self:InitCV()

    -- 公共Npc
    self._publicNpc = nil
    self._publicNpcMarkBuff = 1000510

    -- 快速讯息CD值初始化
    self._quickMessageInitTime = 0
    self._quickMessageCD = 0

    -- 获取本地NPC
    self._localNpc = self._proxy:GetLocalPlayerNpcId()
end
--定义UI开关
local UIControl = {
    On = 100,                               --全开
    Off = 10                                --全关
}

---@param dt number @ delta time 
function XRelinkCharBase:Update(dt)
    if self._proxy:IsNpcBackState(self._uuid) then -- 在后台不触发逻辑
        return
    end
    self:JumpWeaponHidShowCheck()
    self:HardLockInput() --手动锁定
    self:CheckDodgeEnergyAddBanRecover() --检测闪避为0
    self:ProcessChangeMoveState()
    self:ProcessResetSprintMoveTypeOnJump()
    self:ProcessHandleJumpTurnSpeed()
    self:ProcessChangeJumpState()
    --self:RebootCheckUpdate()
    self:UpdateRecordAttribute(dt)
    self:UpdateCV(dt)
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
    if eventType == EWorldEvent.EnterLevel then --进入关卡事件，设置相机。
        self._proxy:SetCameraIgnoreHeightLerpOnAir(false)
    end
end

---跳跃武器显隐藏初始化
function XRelinkCharBase:JumpWeaponHidShowCheckInit()
    self.lastActionIsJump = false --上一个状态是否是跳跃
end

---跳跃控制武器显隐
function XRelinkCharBase:JumpWeaponHidShowCheck()
    local isJumping = self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) --当前是否在跳跃中
    if self.lastActionIsJump and (not isJumping) then
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
        if moveNormalizedDist >= normalizedWalk2Run and moveNormalizedDist <= normalizedRun2Sprint then                  -- 摇杆大于慢走阈值则切换为普通跑
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

--region 属性记录
function XRelinkCharBase:UpdateRecordAttribute(dt)
    -- 计时器确保不会频繁记录
    if self._attribRecordTimer <= 0 then
        self._attribRecordTimer = self._attribRecordInterval

        -- 记录属性
        self._curLifeRatio = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life) / self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    end

    -- 更新计时器
    self._attribRecordTimer = self._attribRecordTimer - dt
end
--endregion

--region CV相关
function XRelinkCharBase:InitCV()
    --- CV事件magic (CV事件是指，通过magic的同步特性通知在服务器运行的[关卡logic]脚本播放一些特定的互动语音)
    self._cvEventMagics = {
        PraiseCounterSuccess = 1000509,
        LowLifeWarning = 1000511
    }

    -- CV残血阈值
    --- 是否在残血状态下
    self._cvIsInLowLifeMode = false
    --- 残血的血量归一化阈值（必须0 - 1）
    self._cvLowLifeRatioThreshold = 0.3

    -- CV 救和被救相关
    --[[
        被救援逻辑：起身时，若有玩家参与了救助，且一定范围内存在其他玩家，则播放语音
        救援逻辑：在开始救助他人时，确保
            当前公共播音冷却不在CD（防俩倒地的人贴一起，救的时候连播两声）并且
            对被救助目标的独立冷却（防止对同一目标多次播放）不在CD的话,
            才能播放语音
    ]]
    --- 在倒地期间是否有玩家参与了救助
    self._cvHasBeenRescuedByOther = false
    --- 倒地起身时，检测该范围内是否存在玩家来决定是否需要播出语音
    self._cvRescuedByOtherSuccessCheckRadius = 15
    --- 自身救助其他倒地玩家时播出语音的公共冷却时间
    self._cvRescueOtherPlayerPublicCd = 5
    --- 自身救助其他倒地玩家时播出语音的公共冷却计时器
    self._cvRescueOtherPlayerCdPublicTimer = 0
    --- 自身救助其他倒地玩家时，对于每个角色播出语音的冷却时间
    self._cvRescueOtherPlayerForEachCd = 5
    --- 自身救助其他倒地玩家时，对于每个角色的救助冷却计时器
    --- @type table<int, float>
    self._cvRescueOtherPlayerForEachCdTimer = {}
end

function XRelinkCharBase:UpdateCV(dt)
    --region 残血CV更新逻辑
    local isLowLife = self._curLifeRatio <= self._cvLowLifeRatioThreshold
    if not self._cvIsInLowLifeMode and isLowLife then
        -- 由非残血进入残血状态
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._cvEventMagics.LowLifeWarning, 1)
    end
    self._cvIsInLowLifeMode = isLowLife
    --endregion

    --region 救助CV相关冷却更新
    -- 防止浮点数不精确问题，统一到 -1 时才停止更新计时器

    -- 公共救人CV冷却更新
    if self._cvRescueOtherPlayerCdPublicTimer >= -1 then
        self._cvRescueOtherPlayerCdPublicTimer = self._cvRescueOtherPlayerCdPublicTimer - dt
    end

    -- 对目标救人CV冷却更新
    for playerUUID, timer in pairs(self._cvRescueOtherPlayerForEachCdTimer) do
        if self._cvRescueOtherPlayerForEachCdTimer[playerUUID] >= -1 then
            XLog.Debug(string.format("目标%d救助冷却%.2f", playerUUID, self._cvRescueOtherPlayerForEachCdTimer[playerUUID]))
            self._cvRescueOtherPlayerForEachCdTimer[playerUUID] = self._cvRescueOtherPlayerForEachCdTimer[playerUUID] - dt
        end
    end
    --endregion
end
--endregion

--region EventCallBack 事件回调
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
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal) --注册角力弹开事件
    self._proxy:RegisterEvent(EWorldEvent.NpcMultiParrySucceed)
    self._proxy:RegisterEvent(EWorldEvent.LockTargetChanged)      -- OnLockTargetChanged
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillStart)      --OnFullChainSkillStart
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillEnd)        --OnFullChainSkillEnd
    self._proxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill)        --OnCastFullChainFinalSkill
    self._proxy:RegisterEvent(EWorldEvent.FullChainStageEnd)        --OnFullChainStageEnd
    self._proxy:RegisterEvent(EWorldEvent.FullChainShowStart) --OnFullChainShowStart
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcMultiParryStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
    self._proxy:RegisterEvent(EWorldEvent.NpcCure)

    self._proxy:RegisterEvent(EWorldEvent.OnNpcBeginRescue)

    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess, self._uuid)  -- OnNpcCounterSuccess
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterSyncCounterSuccess, self._uuid) -- OnNpcAfterSyncCounterSuccess

    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)        --OnEnterLevel
end

function XRelinkCharBase:HandleLuaEvent(eventType, eventArgs)
end

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

function XRelinkCharBase:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    self:CheckDodgeEnergyAddBanRecover();
    if launcherId ~= self._uuid then
        return
    end
    local succeed, actionId, actionType = self._proxy:TryGetCurrentAction(self._uuid)
    if succeed and actionType == 9 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1200010)
    end
end

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
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == self._BreakQteBuff  then
        self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,true)
    end

    -- 下面这段是怪物放狂暴技时，获得丽芙罩子，会弹出给丽芙点赞的快速讯息的逻辑
    -- 这个只是临时做法，可拓展性非常低
    -- 第一步先保证自己不是放罩子丽芙，且获得的是罩子的减伤buff
    local livBuffId = 105308003
    if casterNpcUUID ~= npcUUID and buffId == livBuffId then
        XLog.Debug("已获得丽芙的罩子BUFF")
        -- 第二步先判断下CD，因为丽芙的罩子是不停的给人加BUFF，不能重复触发
        local nowTime = self._proxy:GetFightTime()
        if nowTime > self._quickMessageInitTime + self._quickMessageCD then
            XLog.Debug("CD判断已通过")
            -- 第三步遍历所有角色，看看存不存在带狂暴技标记1000497 buff的单位
            local npcList = self._proxy:GetNpcList()      --获取NPC列表
            local BuffID = 1000497                                  --狂暴技buff
            for _, npc in ipairs(npcList) do
                if self._proxy:CheckBuffByKind(npc,BuffID) then
                    XLog.Debug("有人处于狂暴状态！！")
                    -- 到此已经全部判断完毕，最后再随机生一个夸夸讯息
                    -- 这代码写得太丑陋了，之后一定要把这个变成通用规则
                    local messageId = 6
                    self._proxy:ShowQuickMessage(messageId)
                    XLog.Debug("已发送")
                    self._quickMessageCD = 30
                    self._quickMessageInitTime = self._proxy:GetFightTime()
                    break
                end
            end
        end
    end

end

function XRelinkCharBase:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == self._BreakQteBuff  then
        self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,false)
    end
end

function XRelinkCharBase:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    
    if (SourceUUID ~= self._uuid) then
        return
    end
    if (Type == 1) then 
        if not self._DodgeIsNotCd then
            return
        end

        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510701, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510702, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510703, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510705, 1)
        
        self._DodgeIsNotCd = false

        self._proxy:AddTimerTask(  1,  function()
            self._DodgeIsNotCd = true
        end)
    end
end

function XRelinkCharBase:HardLockInput() -- tab键手动锁定
    ----新tab逻辑
    if self._proxy:IsKeyDown(ENpcOperationKey.Focus) then  --按下tab键
        local locktarget, _ = self._proxy:GetLockTarget()
        if locktarget ~= 0 then               --锁定目标不为空
            local locktargettype = self._proxy:GetCurLockTargetType()
            self._proxy:ApplyMagic(self._uuid,self._uuid,105296,1)  --限制镜头拖动输入
            self:CheckFocusTarget()
            if locktargettype == ELockTargetType.ForceLock then   --强制锁定，直接返回
                return
            elseif locktargettype == ELockTargetType.HardLock then    --硬锁定，取消
                self._proxy:CancelHardLockTarget(self._uuid)
                self._proxy:CancelSoftLockTarget(self._uuid)
            else
                self._proxy:SetHardLock(self._uuid,locktarget) --软锁，切硬锁
            end
        else
            local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
            if searchtarget == 0 then
                return
            end
            self._proxy:SetHardLock(self._uuid,searchtarget)
        end
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

function XRelinkCharBase:CheckDodgeEnergyAddBanRecover()
    if self._DodgeCheck == true and self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.DodgeEnergy) == 0 then
        --XLog.Warning("闪避为0时禁用")
        self._DodgeCheck = false
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._BanDodgeRecoverBuff, 1)
    elseif self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.DodgeEnergy) > 0 then
        self._DodgeCheck = true
        self._proxy:RemoveBuffByKindAndCount(self._uuid,self._BanDodgeRecoverBuff,0)
    end
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
    if self._uuid ~= counterNpcUUID then
        return
    end
    -- 弹刀成功后无敌
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._counterImmortalMagicId, 1)

    -- CV: 弹刀成功，通知关卡找玩家夸一句(多人弹刀不触发这句)
    if GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_MultiInteract}) then
        return
    end
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._cvEventMagics.PraiseCounterSuccess, 1)
end

function XRelinkCharBase:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    if self._uuid ~= targetNpcUUID then
        -- XLog.Debug("角力的不是我")
        -- 完成角力后，其他玩家可以点快速讯息给角力者点赞
        local index = math.random(1, 3)
        local messageid = 8
        if index == 2 then
            messageid = 9
        elseif index == 3 then
            messageid = 10
        end
        -- 给个1.5秒的延迟，等演出结束后再发
        self._proxy:AddTimerTask(1.5, function()
        self._proxy:ShowQuickMessage(messageid)
    end)
        
        return
    end

end

function XRelinkCharBase:OnNpcMultiParrySucceed(launcherNpcUUID, targetNpcUUID)
    -- 完成多人弹刀后，所有玩家都可以点快速讯息，然后从3个中随机发一个
    local index = math.random(1, 3)
    local messageid = 8
    if index == 2 then
        messageid = 9
    elseif index == 3 then
        messageid = 10
    end
    self._proxy:ShowQuickMessage(messageid)
end

function XRelinkCharBase:OnNpcAfterSyncCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end

function XRelinkCharBase:OnFullChainSkillStart(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel, curChainStartNpcId)
    if curChainStartNpcId ~= self._uuid then
        return
    end

    if chainLevel > 1 then
        self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.ResponseFullChain, EAudioLuaFuncSyncType.All)
    end

    self:ControlUltUI(UIControl.Off)
end

function XRelinkCharBase:OnFullChainSkillEnd(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel, curChainEndNpcId)
    if curChainEndNpcId ~= self._uuid then
        return
    end

    if chainLevel == 1 then
        self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.ActivateFullChain, EAudioLuaFuncSyncType.All)
    end

    if chainLevel == 2 then
        self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.NotifyFullChain, EAudioLuaFuncSyncType.All)
    end

    self:ControlUltUI(UIControl.On)
end

function XRelinkCharBase:OnFullChainShowStart(gameplayActive, chainNpcList, chainLevel)
    --XLog.Warning("进入表演")
    self:ControlFullChainUI(UIControl.Off)
end

function XRelinkCharBase:OnCastFullChainFinalSkill(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel)
    self:ControlFullChainUI(UIControl.On)
    local isInChainList = false
    for i, player in ipairs(chainNpcList) do
        if player == self._uuid then
            isInChainList = true
            break
        end
    end

    if not isInChainList then
        return
    end

    -- 如果触发了fc,tc，则在3个预制message中随机选一个发，给队友点赞
    local index = math.random(1, 3)
    local messageid = 8
    if index == 2 then
        messageid = 9
    elseif index == 3 then
        messageid = 10
    end
    self._proxy:ShowQuickMessage(messageid)
end

function XRelinkCharBase:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID, succeed)
    if targetNpcUUID ~= self._uuid then
        return
    end
    self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.EnterMultiQTE, EAudioLuaFuncSyncType.All)
end

function XRelinkCharBase:OnNpcMultiParryStart(launcherNpcUUID, targetNpcUUID, succeed)
    if targetNpcUUID ~= self._uuid then
        -- 非多人弹刀角色，在多人弹刀触发后添加标记（用于处理角力与弹刀复用动作，弹刀流程需要打断效果）
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000517,1) --buff标记持续3s，且仅处理支援qte
        return
    end
    self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.EnterMultiQTE, EAudioLuaFuncSyncType.All)

end

function XRelinkCharBase:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID ~= self._uuid then
        return
    end

    self._proxy:ApplyMagic(self._uuid,self._uuid,1000480,1)--死亡次数标记buff，每次一次都加一层
end

function XRelinkCharBase:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID == self._uuid then
        self:OnSelfReviveEvent()
    end
end

function XRelinkCharBase:OnSelfReviveEvent()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000478,1)--复活无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000477,1)--复活特效
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000485)--去掉支援等待救援特效

    -- 播放被救的语音
    if self._cvHasBeenRescuedByOther then
        -- 检测是否有其他玩家在范围内
        local hasPlayerInRange = false
        for key, player in ipairs(self._proxy:GetPlayerNpcList()) do
            if player ~= self._uuid and self._proxy:CheckNpcDistance(self._uuid, player, self._cvRescuedByOtherSuccessCheckRadius) then
                hasPlayerInRange = true
                break
            end
        end

        -- 播放被救的感谢语音
        if hasPlayerInRange then
            self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.RescuedByTeammate, EAudioLuaFuncSyncType.All)
        end
    end

    -- 重置被救播CV的状态
    self._cvHasBeenRescuedByOther = false
    -- 重置救人播CV的状态
    self._cvRescueOtherPlayerCdPublicTimer = 0
    self._cvRescueOtherPlayerForEachCdTimer = {}
end

function XRelinkCharBase:OnNpcWaitRebootEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    if npcUUID == self._uuid then
        self:OnSelfWaitRebootEvent()
    end
end

function XRelinkCharBase:OnSelfWaitRebootEvent()
    -- 挂掉时弹快速讯息：救救我
    self._proxy:ShowQuickMessage(4)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000484)--挂上支援等待救援特效
end

function XRelinkCharBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        return
    end
end

function XRelinkCharBase:OnNpcCureEvent(launcherId, targetId, magicId, kind, value, skillId)
    if targetId ~= self._uuid then
        return
    end

    if launcherId == self._uuid then
        return
    end

    local maxLife = self._proxy:GetNpcAttribMaxValue(targetId, ENpcAttrib.Life)
    local curLife = self._proxy:GetNpcAttribValue(targetId, ENpcAttrib.Life)
    local tarLifeRatio = (curLife + value) / maxLife

    if self._cvIsInLowLifeMode and tarLifeRatio > self._cvLowLifeRatioThreshold then
        self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.PowerUpOrHealFromTeammate, EAudioLuaFuncSyncType.All)
    end
end

function XRelinkCharBase:ControlFullChainUI(SwitchType)    --FullChain控制UI隐藏
    if SwitchType == UIControl.Off then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,3)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,3)         --隐藏右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localNpc,3)              --隐藏目标面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localNpc,3)          --隐藏关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonRollNumber,self._localNpc,3)          --隐藏伤害飘字
        self._proxy:SetLevelUiState(EFightUiType.CommonBuff,self._localNpc,3)          --隐藏buff飘字
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localNpc,3)          --隐藏锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localNpc,3)                --隐藏从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localNpc,3)          --隐藏能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localNpc,3)            --隐藏队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localNpc,3)            --隐藏玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localNpc,3)     --隐藏DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localNpc,3)    --隐藏聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localNpc,3)    --隐藏聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeammateIndicator,self._localNpc,3)    --隐藏队友信息
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localNpc,3)    --隐藏任务
        self._proxy:SetLevelUiState(EFightUiType.RelinkMechanicInfo,self._localNpc,3)    --隐藏机制进度
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball4,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localNpc,3)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball4,self._localNpc,3)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,3) 


    elseif SwitchType == UIControl.On then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,1)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,1)         --隐藏右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localNpc,1)              --隐藏目标面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localNpc,1)          --隐藏关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonRollNumber,self._localNpc,1)          --隐藏伤害飘字
        self._proxy:SetLevelUiState(EFightUiType.CommonBuff,self._localNpc,1)          --隐藏buff飘字
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localNpc,1)          --隐藏锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localNpc,1)                --隐藏从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localNpc,1)          --隐藏能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localNpc,1)            --隐藏队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localNpc,1)            --隐藏玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localNpc,1)     --隐藏DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localNpc,1)    --隐藏聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localNpc,1)    --隐藏聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeammateIndicator,self._localNpc,1)    --隐藏队友信息
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localNpc,1)    --隐藏任务
        self._proxy:SetLevelUiState(EFightUiType.RelinkMechanicInfo,self._localNpc,1)    --隐藏机制进度
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball4,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,true)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localNpc,1)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball4,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,1)
    end
end

function XRelinkCharBase:ControlUltUI(SwitchType)    --大招控制UI隐藏
    if SwitchType == UIControl.Off then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,3)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,3)         --隐藏右侧面板
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball4,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localNpc,3)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball4,self._localNpc,3)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,3) 

    elseif SwitchType == UIControl.On then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,1)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,1)         --隐藏右侧面板
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball4,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,true)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localNpc,1)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball4,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,1)
    end
end

function XRelinkCharBase:OnNpcBeginRescueEvent(npcUUID, npcPlaceId, npcKind, isPlayer, rescuerUUID)
    -- 我开始被救
    if npcUUID == self._uuid then
        -- 如果没人救过我，则标记为有人救过了
        if not self._cvHasBeenRescuedByOther then
            self._cvHasBeenRescuedByOther = true
        end
    end

    -- 我开始救人
    if rescuerUUID == self._uuid then
        -- 如果公共冷却还在转，则不给播
        if self._cvRescueOtherPlayerCdPublicTimer >= 0 then
            return
        end

        if self:ContainsKey(self._cvRescueOtherPlayerForEachCdTimer, npcUUID) then
            -- 这个人最近被播过语音了，看看对他的冷却到了没
            local timer = self._cvRescueOtherPlayerForEachCdTimer[npcUUID]
            if timer >= 0 then
                return
            else
                -- 冷却好了，播
                self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.StartRescueTeammate, EAudioLuaFuncSyncType.All)
                self._cvRescueOtherPlayerForEachCdTimer[npcUUID] = self._cvRescueOtherPlayerForEachCd
                self._cvRescueOtherPlayerCdPublicTimer = self._cvRescueOtherPlayerPublicCd
            end
        else
            -- 对这人没播过救助语音，播一下
            self._proxy:PlayNpcCV(self._uuid, 0, EFightCVAction.StartRescueTeammate, EAudioLuaFuncSyncType.All)
            self._cvRescueOtherPlayerForEachCdTimer[npcUUID] = self._cvRescueOtherPlayerForEachCd
            self._cvRescueOtherPlayerCdPublicTimer = self._cvRescueOtherPlayerPublicCd
        end
    end
end
--endregion

--region 工具封装
---尝试获取公共Npc，有可能为nil
function XRelinkCharBase:TryGetPublicNpc()
    if self._publicNpc ~= nil and self._proxy:CheckNpc(self._publicNpc) then
        return self._publicNpc
    end

    for i, npc in ipairs(self._proxy:GetNpcList()) do
        if self._proxy:CheckBuffByKind(self._uuid, self._publicNpcMarkBuff) then
            self._publicNpc = npc
            break
        end
    end

    return self._publicNpc
end

--- 检测KeyValuePair样的table是否包含指定key
--- @param targetTable table @ 目标table
--- @param targetKey @ 目标键
--- @return boolean @ 是否包含key
function XRelinkCharBase:ContainsKey(targetTable, targetKey)
    local result = false
    for key, val in pairs(targetTable) do
        if key == targetKey then
            result = true
            break
        end
    end

    return result
end
--endregion

return XRelinkCharBase