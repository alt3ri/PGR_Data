local XTheatre6FightBase = require("Gameplay/Theatre6/XTheatre6FightBase")
local XLevelStateMachine = require("Gameplay/Theatre6/XTheatre6StateMachine")
local XTheatre6SkillComboCaster = require("Gameplay/Theatre6/XTheatre6SkillComboCaster")

---@class XTheatre6CharBase:XTheatre6FightBase
local XTheatre6CharBase = XClass(XTheatre6FightBase, "XTheatre6CharBase")

local DOGE_COST = 100 --触发超算时的超算值消耗(临时方案, 正式方案应该读配置表)
local ARMOR_BUFF = 1025012
local InTraction_BUFF = 1025018

--region 状态机框架搭建

local StateEnum = {
    WaitHit = 0,         -- 这是一个失去出手权但是还没吃到伤害的中间状态
    Hit = 1,             -- 受击状态
    Block = 2,           -- 格挡状态
    MainSkill = 3,       -- 主动技能状态
    InsertSkill = 4,     -- 插入技能状态
    Wrestle = 5,         -- 角力状态
    Dodge = 6,           -- 超算状态
    Die = 7,             -- 死亡状态
    Delay = 8,           -- 这是一个处理指令延迟的中间状态, 用以优化状态衔接时的表现细节
    WrestleSucSkill = 9, --拼刀成功技能
    DodgeSucSkill = 10   --超算成功技能
}

XTheatre6CharBase.StateEnum = StateEnum

---@class XTheatre6CharBase.State:XTheatre6State
---@field _owner XTheatre6CharBase
---@field _stateMachine XTheatre6CharBase.StateMachine
---@class XTheatre6CharBase.StateMachine:XTheatre6StateMachine

local StateMachine, States = XLevelStateMachine:CreateClassByEnum(StateEnum, "XTheatre6CharBase")
XTheatre6CharBase.StateMachine = StateMachine --[[@as XTheatre6CharBase.StateMachine]]
XTheatre6CharBase.States = States --[[@as table<string|integer, XTheatre6CharBase.State>]]

---@protected
---@param namePrefix string 类名前缀,用于为新生成的state类创建名称
---@return XTheatre6CharBase.StateMachine stateMachine 肉鸽6角色状态机派生类
---@return table<string|integer, XTheatre6CharBase.State> states 肉鸽6角色状态派生类列表
function XTheatre6CharBase:CreateClasses(namePrefix)
    if type(namePrefix) ~= "string" then
        XLog.Error("XTheatre6CharBase.CreateStateClasses Error: illegal namePrefix")
        return
    end

    -- local StateMachineClass, StateClasses
    -- StateMachineClass = XClass(self.StateMachine, namePrefix .. ".StateMachine")

    return self.StateMachine:CreateChildClasses(namePrefix)
end

---改变角色状态机状态
---@param stateId integer StateEnum中定义的状态Ida
---@param needDelay bool|nil 是否跳过延迟直接进入目标状态
function XTheatre6CharBase:SetState(stateId, needDelay)
    -- 禁止通过这个接口直接设置为delay状态
    if stateId == StateEnum.Delay then
        self:LogError("XTheatre6CharBase:SetState Error: Directly Set State to Delay")
        return
    end

    if needDelay == nil then needDelay = self._states.Delay.NeedDelayStates[stateId] end
    if not needDelay then return self._stateMachine:SetStateById(stateId) end
    local oldStateId = self._stateMachine:GetCurStateId()
    if oldStateId == StateEnum.Delay then
        self:LogError("XTheatre6CharBase:SetState Error: Repeat Enter Delay State, Record is " ..
            self._states.Delay:DebugInfo())
        oldStateId = self._states.Delay._oldStateId
    end
    if not oldStateId then return self._stateMachine:SetStateById(stateId) end -- 第一次启动状态机
    self._states.Delay:Prepare(oldStateId, stateId)
    self._stateMachine:SetStateById(StateEnum.Delay)
end

---检查角色状态机状态
---@param stateId integer StateEnum中定义的状态Ida
function XTheatre6CharBase:CheckState(stateId)
    return self._stateMachine:CheckStateById(stateId)
end

--endregion

--region 状态通用UI流程接口

---部分状态结束时, 尝试关闭出手权头像Ux
---@param state XTheatre6CharBase.State
---@param newState XTheatre6CharBase.State
function XTheatre6CharBase.TryShutDownHandSideUxOnStateEnd(state, newState)
    if newState.CheckCanRemainHandSideUx and newState:CheckCanRemainHandSideUx() then return end
    state._owner:ToggleHandSideUx(false)
end

---部分状态中, 攻击命中敌人时增加连击数
---@param state XTheatre6CharBase.State
function XTheatre6CharBase.IncComboCountOnDamgeInState(state, launcherId, targetId, actionId)
    if not actionId or actionId == 0 then return end
    local npc = state._owner
    if launcherId ~= npc._uuid then return end
    return npc:IncComboCount()
end

--endregion

--region UI表现修改接口

---设置出手权头像UI动效
function XTheatre6CharBase:SetHandSideUx(newUx)
    if self._handSideUx == newUx then return end
    self._handSideUx = newUx
    -- self._level:TryUdpateHandSideUx(self)
    self:TryRefreshHandSideUx()
end

---获取出手权头像UI动效
function XTheatre6CharBase:GetHandSideUx()
    return self._handSideUx
end

--开关出手权头像特效
function XTheatre6CharBase:ToggleHandSideUx(isOn)
    if isOn == nil then isOn = false end
    if self._uiStates.handSide == isOn then return end
    self._uiStates.handSide = isOn
    if isOn then
        -- self:LogError("Activate Hand Side Ux")
        self._proxy:Theatre6UpdateHandSideUI(self._uuid, self._handSideUx)
    else
        -- self:LogError("ShutDown Hand Side Ux")
        self._proxy:Theatre6UpdateHandSideUI(0)
    end
end

--尝试刷新出手权头像特效
function XTheatre6CharBase:TryRefreshHandSideUx()
    if not self._uiStates.handSide then return end
    self._proxy:Theatre6UpdateHandSideUI(self._uuid, self._handSideUx)
end

--增加连击数
function XTheatre6CharBase:IncComboCount()
    if not self._uiStates.Combo then self:ShowComboUi() end
    self._proxy:Theatre6UpdateComboCountUI(self._uuid)
end

--开启连击数UI
function XTheatre6CharBase:ShowComboUi()
    if self._uiStates.Combo then return end
    self._uiStates.Combo = true
    self._proxy:Theatre6SwitchComboCountUI(self._uuid, true)
end

--关闭连击数UI(需要补充破碎效果)
function XTheatre6CharBase:BreakComboUi()
    if not self._uiStates.Combo then return end
    self._uiStates.Combo = false
    self._proxy:Theatre6SwitchComboCountUI(self._uuid, false)
end

--关闭连击数UI(无破碎效果)
function XTheatre6CharBase:HideComboUi()
    if not self._uiStates.Combo then return end
    self._uiStates.Combo = false
    self._proxy:Theatre6SwitchComboCountUI(self._uuid, false)
end

--更新技能播报UI
---@param skillType ETheatre6SkillType 本次实际释放的技能类型, 决定UI动效
function XTheatre6CharBase:UpdateSkillUi(curSkillId, previewMainSkillId, skillType)
    if not self._uiStates.skill then self:ShowSkillUi() end
    self._proxy:Theatre6UpdateSkillUI(self._uuid, curSkillId, previewMainSkillId, skillType)
end

--开启技能播报UI
--暂且没有[开启一个空的技能播报]的表现, 只处理布尔标志位
function XTheatre6CharBase:ShowSkillUi()
    if self._uiStates.skill then return end
    self._uiStates.skill = true
    -- self._proxy:Theatre6UpdateSkillUI(self._uuid, 0, 0)
end

--关闭技能播报UI(携带破碎效果)
function XTheatre6CharBase:BreakSkillUi()
    if not self._uiStates.skill then return end
    self._uiStates.skill = false
    self._proxy:Theatre6BrokenSkill(self._uuid)
end

--关闭技能播报UI(无破碎效果)
function XTheatre6CharBase:HideSkillUi()
    if not self._uiStates.skill then return end
    self._uiStates.skill = false
    self._proxy:Theatre6BrokenSkill(self._uuid, false)
    -- self._proxy:Theatre6UpdateSkillUI(self._uuid, 0, 0)
end

--endregion

--region 主动行为状态逻辑定义

-- Wrestle 状态逻辑
do
    ---@class XTheatre6CharBase.State.Wrestle:XTheatre6CharBase.State
    ---@field WrestleSkillId integer 拼刀动作actionId
    ---@field SucceedActionId integer 拼刀成功后释放的终结动作actionId
    local Wrestle = States.Wrestle

    ---控制中心决定进入拼刀状态
    function XTheatre6CharBase:OnCenterWrestleStart()
        if self:CheckState(StateEnum.Wrestle) then
            return self:LogError("XTheatre6CharBase:OnCenterWrestleStart Error: Called Inside Wrestle State")
        end
        self._Pindao_Start_2L_camera = self._states.Wrestle.PindaoStart2LCamera
        self._Pindao_Start_2R_camera = self._states.Wrestle.PindaoStart2RCamera
        self:SetState(StateEnum.Wrestle)
    end

    ---自己已完成前置状态清理,自己进入拼刀状态
    function Wrestle:Start()
        self._owner._level:OnCharWrestleReady(self._owner._uuid) --通知控制中心自己已经完成前置状态清理
    end

    ---控制中心进入二次拼刀重置状态
    ---@param fighter1UUID number 战斗发起方(Fighter1)的UUID
    ---@param fighter2UUID number 战斗接收方(Fighter2)的UUID
    ---@param Position1 Vector3 战斗发起方(Fighter1)的技能目标位置
    ---@param Position2 Vector3 战斗发起方(Fighter2)的技能目标位置
    function XTheatre6CharBase:OnSecondWrestleReset(fighter1UUID, fighter2UUID, Position1, Position2)
        if self._uuid == fighter1UUID then
            self:AddArmor()
            self._proxy:CastSkillActionToPositionNotCheck(self._uuid, self._states.Wrestle.SecondWrestleReset, Position1)
            self._isFighter1 = true
        elseif self._uuid == fighter2UUID then
            self:AddArmor()
            self._proxy:CastSkillActionToPositionNotCheck(self._uuid, self._states.Wrestle.SecondWrestleReset, Position2)
        end
    end

    ---控制中心已进入拼刀状态,并且双方均已完成前置状态清理
    ---@param fighter1UUID number 战斗发起方(Fighter1)的UUID
    ---@param fighter2UUID number 战斗接收方(Fighter2)的UUID
    function XTheatre6CharBase:OnCenterWrestleBegin(fighter1UUID, fighter2UUID)
        self:AddArmor()
        --对应目标释放对应拼刀技能
        if self._uuid == fighter1UUID then
            self:CastAction(self._states.Wrestle.WrestleSkillIdLeft);
        elseif self._uuid == fighter2UUID then
            self:CastAction(self._states.Wrestle.WrestleSkillIdRight);
        end
        self._proxy:ApplyMagic(fighter1UUID,fighter1UUID,1027501) -- 拼刀时，给双方打个标记
        self._proxy:ApplyMagic(fighter2UUID,fighter2UUID,1027501) -- 拼刀时，给双方打个标记
    end

    ---控制中心进行拼刀僵持状态
    ---@param fighter1UUID number 战斗发起方(Fighter1)的UUID
    ---@param fighter2UUID number 战斗接收方(Fighter2)的UUID
    function XTheatre6CharBase:OnCenterWrestleCountinue(fighter1UUID, fighter2UUID)
        self:AddArmor()
        --对应目标释放对应拼刀技能
        if self._uuid == fighter1UUID then
            self:CastAction(self._states.Wrestle.WrestleSkillIdLeftCountinue);
        elseif self._uuid == fighter2UUID then
            self:CastAction(self._states.Wrestle.WrestleSkillIdRightCountinue);
        end
    end

    ---拼刀拼点结束通知
    ---@param winnerUUID integer 拼点获胜的npc的uuid
    ---@param diff integer 点数差值
    function XTheatre6CharBase:OnCenterWrestleRollDiceEnd(winnerUUID, diff)
        if not self:CheckState(StateEnum.Wrestle) then
            return self:LogError("XTheatre6CharBase:OnCenterWrestleStart Error: Called Outside Wrestle State")
        end

        local UUID = self._uuid
        local proxy = self._proxy

        self:RemoveArmor()

        if winnerUUID == UUID then
            self:CastWrestleEndSucced();
        else
            self:CastWrestleEndFailed();
        end

        proxy:ChangeNpcGameplayEnergy(UUID, ETheatre6AttribType.Stamina,
            proxy:GetNpcGameplayAttribMaxValue(UUID, ETheatre6AttribType.Stamina))
    end

    --释放拼刀失败的终结动作
    function XTheatre6CharBase:CastWrestleEndFailed()
        local timeSlow = 1025010
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:ApplyMagic(self._uuid, self._uuid, timeSlow)
        self:CastAction(self._states.Wrestle.SucceedActionId)
    end

    --释放拼刀成功的终结动作
    function XTheatre6CharBase:CastWrestleEndSucced()
        local SetCameraModify = 10250206
        local MonsterTag = 8025000
        self._proxy:AbortAction(self._uuid, true)
        if self._proxy:CheckBuffByKind(self._uuid, MonsterTag) then 
            self:CastAction(self._states.Wrestle.SucceedActionId);
            return
        end
        self._proxy:SetCameraFocusTarget(self._uuid, self._enemyUUID)
        self._proxy:ApplyMagic(self._uuid, self._uuid, SetCameraModify)
        self:CastAction(self._states.Wrestle.SucceedActionId);
    end

    --拼刀终结动作结束的通知
    function XTheatre6CharBase:OnWrestleSuccEndFinish(actionId, keyFrameId)
        self._level:OnCharWrestleSuccEndFinish(self._uuid);
    end
end

-- WrestleSucSkill 状态逻辑
do
    ---@class XTheatre6CharBase.State.WrestleSucSkill:XTheatre6CharBase.State
    local WrestleSucSkill = States.WrestleSucSkill
    WrestleSucSkill.CheckInterval = 0.05 --技能结束的轮询检查间隔(临时方案)
    function WrestleSucSkill.CheckCanRemainHandSideUx() return true end

    ---@param launcherUUID XTheatre6CharBase
    function XTheatre6CharBase:OnCenterCastWrestleSucSkill(launcherUUID)
        if self._uuid == launcherUUID then
            self:SetState(StateEnum.WrestleSucSkill)
        else
            self:SetState(StateEnum.WaitHit)
        end
    end

    function WrestleSucSkill:Start()
        local npc = self._owner
        local skillId, actionId = npc._skillComboCaster:CastWrestleSucSkill()
        if not actionId then
            self:LogError("WrestleSucSkill:Start Error: Cast WrestleSucSkill Skill Failed, SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
            return
        end

        npc:ToggleHandSideUx(true)
        self._skillId = skillId
        self._actionId = actionId
        self._dmgIncRatio = self._proxy:Theatre6GetConfig():GetInt("PDDmg+")
        -- self._dmgIncValue = self._proxy:GetNpcGameplayAttribValue(npc._uuid, ETheatre6AttribType.WrestlePoint) * 60
        self._dmgIncValue = self._proxy:GetNpcGameplayAttribValue(npc._uuid, ETheatre6AttribType.WrestlePoint) *
            self._dmgIncRatio
        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
        npc._level:RefreshWrestleSucSkillForceContinueTime(npc._skillComboCaster:GetSkillTime(skillId))
        self:BroadCastWrestleSucSkillStart()
    end

    function WrestleSucSkill:BroadCastWrestleSucSkillStart()
        local eventType = EFightLuaEvent.Theatre6SkillStart
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Wrestle
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function WrestleSucSkill:Update(dt)
        -- self:LogError("_owner._npcTime = " ..self._owner._npcTime ..", checkTime = " .. self._checkTime)
        if self._owner._npcTime < self._checkTime then return end
        self:RefreshCheckTime()
        if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        return self:OnActionEnd(self._actionId)

        -- if self._owner._npcTime < self._forceContinueTime then return end
        -- if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        -- return self:ForceContinueAction()
    end

    function WrestleSucSkill:DebugInfo()
        return " ActionId = " .. tostring(self._actionId)
    end

    ---兜底逻辑.一个动作持续时间超时后强制衔接下一个动作
    function WrestleSucSkill:ForceContinueAction()
        self:LogError("WrestleSucSkill:ForceContinueAction is Called, Record is " .. self:DebugInfo())
        return self:OnActionEnd()
    end

    function WrestleSucSkill:OnActionEnd(actionId)
        if (actionId ~= self._actionId) then
            return self:LogError("WrestleSucSkill:OnActionEnd Error: ActionId Mismatch, Event Action Id is " ..
                tostring(actionId) .. ", Record is " .. self:DebugInfo())
        end

        local skillCaster = self._owner._skillComboCaster

        --技能结束, 通知控制中心
        if not skillCaster:CanContinue() then return self:OnSkillEnd() end

        --技能继续派生
        local skillId, actionId = skillCaster:Continue()
        if not (skillId and actionId) then
            return self:LogError("WrestleSucSkill:OnActionEnd Error: Continue WrestleSucSkill Skill Failed,  SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
        end
        if (skillId ~= self._skillId) then
            return self:LogError("WrestleSucSkill:OnActionEnd Error: ActionId Mismatch After Continue, New Skill Id is " ..
                skillId .. ", Record is " .. self:DebugInfo())
        end

        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
    end

    function WrestleSucSkill:OnSkillEnd()
        self:BroadCastWrestleSucSkillEnd()
        self._owner._level:OnCharWrestleSucSkillEnd(self._owner._uuid)
    end

    function WrestleSucSkill:BroadCastWrestleSucSkillEnd()
        local eventType = EFightLuaEvent.Theatre6SkillEnd
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Wrestle
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function WrestleSucSkill:RefreshForceContinueTime(actionId)
        self._forceContinueTime = self._owner._npcTime + self._owner._skillComboCaster:GetActionTime(actionId)
    end

    function WrestleSucSkill:RefreshCheckTime()
        self._checkTime = self._owner._npcTime + self.CheckInterval
        -- self:LogError("checkTime is set to " .. self._checkTime)
    end

    ---释放拼刀成功技能时增伤(乘区71)
    ---@param eventArgs BeforeDamageCalcEventArgs
    function WrestleSucSkill:BeforeDamageCalc(eventArgs)
        local npc = self._owner
        if eventArgs.Launcher ~= npc._uuid then return end
        self._proxy:AddDamageMagicContextValue(eventArgs.ContextId, ENpcAttrib.Attack2AmpP, self._dmgIncValue, 0)
    end

    WrestleSucSkill.OnCsNpcDamageEvent = XTheatre6CharBase.IncComboCountOnDamgeInState
    WrestleSucSkill.End = XTheatre6CharBase.TryShutDownHandSideUxOnStateEnd
end

-- Dodge 状态逻辑
do
    ---@class XTheatre6CharBase.State.Dodge:XTheatre6CharBase.State
    ---@field SucceedActionId integer 超算成功后释放的终结动作actionId
    ---@field DodgeActionId integer 超算动作actionId
    local Dodge = States.Dodge
    local TimeSlowBuff = 10250301

    ---控制中心决定进入超算状态
    function XTheatre6CharBase:OnCenterDodgeStart(launcherUUID)
        -- 如果角色攒够200点超算值，或者在超算失败期间被超算终结动作又打满了100点超算值，还真有可能连续释放两个超算。因此跳过这里的检查
        -- if self:CheckState(StateEnum.Dodge) then
        --     return self:LogError("XTheatre6CharBase:OnCenterDodgeStart Error: Called Inside Dodge State")
        -- end

        self:SetState(StateEnum.Dodge)
    end

    ---自己已完成前置状态清理,自己进入超算状态
    function Dodge:Start()
        self._owner._level:OnCharDodgeReady(self._owner._uuid) --通知控制中心自己已经完成前置状态清理
    end

    Dodge.ReEnter = Dodge.Start

    ---控制中心已进入超算状态,并且双方均已完成前置状态清理
    function XTheatre6CharBase:OnCenterDodgeBegin(launcherUUID)
        self:AddArmor()
        if launcherUUID ~= self._uuid then return end
        self._proxy:Theatre6CastNpcRuntimeOverClock(self._uuid, DOGE_COST) -- 消耗超算值
        self:CastAction(self._states.Dodge.DodgeSkillId);
        self._proxy:ApplyMagic(self._uuid, self._enemyUUID, TimeSlowBuff)
        --todo 根据发送事件释放超算特效子弹
    end

    ---超算拼点结束通知
    ---@param launcherUUID integer 发起超算的单位的uuid
    ---@param winnerUUID integer 拼点获胜的单位的uuid
    function XTheatre6CharBase:OnCenterDodgeRollDiceEnd(launcherUUID, winnerUUID)
        if not self:CheckState(StateEnum.Dodge) then
            return self:LogError("XTheatre6CharBase:OnCenterDodgeStart Error: Called Outside Dodge State")
        end

        --我超算成功且我是超算释放者
        if winnerUUID == self._uuid and launcherUUID == self._uuid then
            self._proxy:RemoveBuff(self._uuid, TimeSlowBuff)
            --ToDo: 这里要补充超算成功后降低超算获取率的逻辑
            self:CastDodgeEndSucced();
            return
            --我超算成功但我不是超算释放者
        elseif winnerUUID == self._uuid and launcherUUID ~= self._uuid then
            self._proxy:RemoveBuff(self._uuid, TimeSlowBuff)
            -- todo 删除超算特效成功子弹
            --我超算失败但我是超算释放者
        elseif winnerUUID ~= self._uuid and launcherUUID == self._uuid then
            self._proxy:RemoveBuff(self._uuid, TimeSlowBuff)
            -- todo 删除超算特效成功子弹
            --我超算失败且我不是超算释放者
        elseif winnerUUID ~= self._uuid and launcherUUID ~= self._uuid then
            self._proxy:RemoveBuff(self._uuid, TimeSlowBuff)
            -- todo 删除超算特效成功子弹
        end
        self:OnDodgeSuccEndFinish()
    end

    -- ---释放超算失败的终结动作
    -- function XTheatre6CharBase:CastDodgeEndFailed() end

    ---释放超算成功的终结动作
    function XTheatre6CharBase:CastDodgeEndSucced()
        self:CastAction(self._states.Dodge.SucceedActionId);
    end

    ---角色超算成功终结动作结束事件
    function XTheatre6CharBase:OnDodgeSuccEndFinish(actionId, keyFrameId)
        self:RemoveArmor()
        self._level:OnCharDodgeSuccEndFinish(self._uuid);
    end
end

-- DodgeSucSkill 状态逻辑
do
    ---@class XTheatre6CharBase.State.DodgeSucSkill:XTheatre6CharBase.State
    local DodgeSucSkill = States.DodgeSucSkill
    DodgeSucSkill.CheckInterval = 0.05 --技能结束的轮询检查间隔(临时方案)
    function DodgeSucSkill.CheckCanRemainHandSideUx() return true end

    ---@param launcherUUID XTheatre6CharBase
    function XTheatre6CharBase:OnCenterCastDodgeSucSkill(launcherUUID)
        if self._uuid == launcherUUID then
            self:SetState(StateEnum.DodgeSucSkill)
        else
            self:SetState(StateEnum.WaitHit)
        end
    end

    function DodgeSucSkill:Start()
        local npc = self._owner
        local skillId, actionId = npc._skillComboCaster:CastDodgeSucSkill()
        if not actionId then
            self:LogError("DodgeSucSkill:Start Error: Cast DodgeSucSkill Skill Failed, SkillId is " ..
                tostring(skillId))
            return
        end

        npc:ToggleHandSideUx(true)

        self._skillId = skillId
        self._actionId = actionId
        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
        npc._level:RefreshDodgeSucSkillForceContinueTime(npc._skillComboCaster:GetSkillTime(skillId))
        self:BroadCastDodgeSucSkillStart()
    end

    function DodgeSucSkill:BroadCastDodgeSucSkillStart()
        local eventType = EFightLuaEvent.Theatre6SkillStart
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Dodge
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function DodgeSucSkill:Update(dt)
        -- self:LogError("_owner._npcTime = " ..self._owner._npcTime ..", checkTime = " .. self._checkTime)
        if self._owner._npcTime < self._checkTime then return end
        self:RefreshCheckTime()
        if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        return self:OnActionEnd(self._actionId)

        -- if self._owner._npcTime < self._forceContinueTime then return end
        -- if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        -- return self:ForceContinueAction()
    end

    function DodgeSucSkill:DebugInfo()
        return " ActionId = " .. tostring(self._actionId)
    end

    ---兜底逻辑.一个动作持续时间超时后强制衔接下一个动作
    function DodgeSucSkill:ForceContinueAction()
        self:LogError("DodgeSucSkill:ForceContinueAction is Called, Record is " .. self:DebugInfo())
        return self:OnActionEnd()
    end

    function DodgeSucSkill:OnActionEnd(actionId)
        if (actionId ~= self._actionId) then
            return self:LogError("DodgeSucSkill:OnActionEnd Error: ActionId Mismatch, Event Action Id is " ..
                tostring(actionId) .. ", Record is " .. self:DebugInfo())
        end

        local skillCaster = self._owner._skillComboCaster

        --技能结束, 通知控制中心
        if not skillCaster:CanContinue() then return self:OnSkillEnd() end

        --技能继续派生
        local skillId, actionId = skillCaster:Continue()
        if not (skillId and actionId) then
            return self:LogError("DodgeSucSkill:OnActionEnd Error: Continue DodgeSucSkill Skill Failed, SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
        end
        if (skillId ~= self._skillId) then
            return self:LogError("DodgeSucSkill:OnActionEnd Error: ActionId Mismatch After Continue, New Skill Id is " ..
                skillId .. ", Record is " .. self:DebugInfo())
        end

        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
    end

    function DodgeSucSkill:OnSkillEnd()
        self:BroadCastDodgeSucSkillEnd()
        self._owner._level:OnCharDodgeSucSkillEnd(self._owner._uuid)
    end

    function DodgeSucSkill:BroadCastDodgeSucSkillEnd()
        local eventType = EFightLuaEvent.Theatre6SkillEnd
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Dodge
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function DodgeSucSkill:RefreshForceContinueTime(actionId)
        self._forceContinueTime = self._owner._npcTime + self._owner._skillComboCaster:GetActionTime(actionId)
    end

    function DodgeSucSkill:RefreshCheckTime()
        self._checkTime = self._owner._npcTime + self.CheckInterval
        -- self:LogError("checkTime is set to " .. self._checkTime)
    end

    DodgeSucSkill.OnCsNpcDamageEvent = XTheatre6CharBase.IncComboCountOnDamgeInState
    DodgeSucSkill.End = XTheatre6CharBase.TryShutDownHandSideUxOnStateEnd
end

-- MainSkill 状态逻辑
do
    ---@class XTheatre6CharBase.State.MainSkill:XTheatre6CharBase.State
    local MainSkill = States.MainSkill
    MainSkill.CheckInterval = 0.05 --技能结束的轮询检查间隔(临时方案)
    function MainSkill.CheckCanRemainHandSideUx() return true end

    ---@param launcherUUID XTheatre6CharBase
    function XTheatre6CharBase:OnCenterCastMainSkill(launcherUUID)
        if self._uuid == launcherUUID then
            self:SetState(StateEnum.MainSkill)
        else
            self:SetState(StateEnum.WaitHit)
        end
    end

    function MainSkill:Start()
        local npc = self._owner
        local skillId, actionId = npc._skillComboCaster:CastMain()
        if not (skillId and actionId) then
            self:LogError("MainSkill:Start Error: Cast Main Skill Failed,  SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
            return
        end
        npc:AddArmor()
        npc:ToggleHandSideUx(true)
        self._skillId = skillId
        self._actionId = actionId
        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
        npc._level:RefreshMainSkillForceContinueTime(npc._skillComboCaster:GetSkillTime(skillId))
        -- self._proxy:Theatre6SwitchComboCountUI(npc._uuid, true)
        self:BroadCastMainSkillStart()
    end

    MainSkill.ReEnter = MainSkill.Start

    function MainSkill:BroadCastMainSkillStart()
        local eventType = EFightLuaEvent.Theatre6SkillStart
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Main
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function MainSkill:Update(dt)
        if self._owner._npcTime < self._checkTime then return end
        self:RefreshCheckTime()
        if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        return self:OnActionEnd(self._actionId)

        -- if self._owner._npcTime < self._forceContinueTime then return end
        -- if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        -- return self:ForceContinueAction()
    end

    function MainSkill:DebugInfo()
        return "SkillId = " .. tostring(self._skillId) .. ", ActionId = " .. tostring(self._actionId)
    end

    ---兜底逻辑.一个动作持续时间超时后强制衔接下一个动作
    function MainSkill:ForceContinueAction()
        self:LogError("MainSkill:ForceContinueAction is Called, Record is " .. self:DebugInfo())
        return self:OnActionEnd()
    end

    function MainSkill:OnActionEnd(actionId)
        if (actionId ~= self._actionId) then
            return self:LogError("MainSkill:OnActionEnd Error: ActionId Mismatch, Event Action Id is " ..
                tostring(actionId) .. ", Record is " .. self:DebugInfo())
        end

        local skillCaster = self._owner._skillComboCaster

        --技能结束, 通知控制中心
        if not skillCaster:CanContinue() then return self:OnSkillEnd() end

        --技能继续派生
        local skillId, actionId = skillCaster:Continue()
        if not (skillId and actionId) then
            return self:LogError("MainSkill:OnActionEnd Error: Continue Main Skill Failed,  SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
        end
        if (skillId ~= self._skillId) then
            return self:LogError("MainSkill:OnActionEnd Error: ActionId Mismatch After Continue, New Skill Id is " ..
                skillId .. ", Record is " .. self:DebugInfo())
        end

        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
    end

    function MainSkill:OnSkillEnd()
        self._owner:RemoveArmor()
        self:BroadCastMainSkillEnd()
        self._owner._level:OnCharMainSkillEnd(self._owner._uuid)
    end

    function MainSkill:BroadCastMainSkillEnd()
        local eventType = EFightLuaEvent.Theatre6SkillEnd
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Main
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function MainSkill:RefreshForceContinueTime(actionId)
        self._forceContinueTime = self._owner._npcTime + self._owner._skillComboCaster:GetActionTime(actionId)
    end

    function MainSkill:RefreshCheckTime()
        self._checkTime = self._owner._npcTime + self.CheckInterval
    end

    MainSkill.OnCsNpcDamageEvent = XTheatre6CharBase.IncComboCountOnDamgeInState

    MainSkill.End = XTheatre6CharBase.TryShutDownHandSideUxOnStateEnd
end

-- InsertSkill 状态逻辑
do
    ---@class XTheatre6CharBase.State.InsertSkill:XTheatre6CharBase.State
    local InsertSkill = States.InsertSkill
    InsertSkill.CheckInterval = 0.05 --技能结束的轮询检查间隔(临时方案)
    function InsertSkill.CheckCanRemainHandSideUx() return true end

    ---@param launcherUUID XTheatre6CharBase
    function XTheatre6CharBase:OnCenterCastInsertSkill(launcherUUID, skillId)
        if self._uuid == launcherUUID then
            self._states.InsertSkill:Prepare(skillId)
            self:SetState(StateEnum.InsertSkill)
        else
            self:SetState(StateEnum.WaitHit)
        end
    end

    function InsertSkill:Prepare(skillId)
        self._skillId = skillId
    end

    function InsertSkill:Start()
        local npc = self._owner
        local skillId = self._skillId
        local _, actionId = npc._skillComboCaster:CastInsert(skillId)
        if not actionId then
            self:LogError("InsertSkill:Start Error: Cast Insert Skill Failed,  SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
            return
        end

        npc:AddArmor()
        npc:ToggleHandSideUx(true)
        self._actionId = actionId
        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
        self._owner._level:RefreshInsertSkillForceContinueTime(npc._skillComboCaster:GetSkillTime(skillId))
        self:BroadCastInsertSkillStart()
    end

    InsertSkill.ReEnter = InsertSkill.Start

    function InsertSkill:BroadCastInsertSkillStart()
        local eventType = EFightLuaEvent.Theatre6SkillStart
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Insert
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function InsertSkill:Update(dt)
        if self._owner._npcTime < self._checkTime then return end
        self:RefreshCheckTime()
        if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        return self:OnActionEnd(self._actionId)

        -- if self._owner._npcTime < self._forceContinueTime then return end
        -- if not self._proxy:CheckNpcCurActionIsDone(self._owner._uuid) then return end
        -- return self:ForceContinueAction()
    end

    function InsertSkill:DebugInfo()
        return "SkillId = " .. tostring(self._skillId) .. ", ActionId = " .. tostring(self._actionId)
    end

    ---兜底逻辑.一个动作持续时间超时后强制衔接下一个动作
    function InsertSkill:ForceContinueAction()
        self:LogError("InsertSkill:ForceContinueAction is Called, Record is " .. self:DebugInfo())
        return self:OnActionEnd()
    end

    function InsertSkill:OnActionEnd(actionId)
        if (actionId ~= self._actionId) then
            return self:LogError("InsertSkill:OnActionEnd Error: ActionId Mismatch, Event Action Id is " ..
                tostring(actionId) .. ", Record is " .. self:DebugInfo())
        end

        local skillCaster = self._owner._skillComboCaster

        --技能结束, 通知控制中心
        if not skillCaster:CanContinue() then return self:OnSkillEnd() end

        --技能继续派生
        local skillId, actionId = skillCaster:Continue()
        if not (skillId and actionId) then
            return self:LogError("InsertSkill:OnActionEnd Error: Continue Main Skill  SkillId = " ..
                tostring(skillId) .. ", ActionId = " .. tostring(actionId))
        end
        if (skillId ~= self._skillId) then
            return self:LogError("InsertSkill:OnActionEnd Error: ActionId Mismatch After Continue, New Skill Id is " ..
                skillId .. ", Record is " .. self:DebugInfo())
        end

        self:RefreshForceContinueTime(actionId)
        self:RefreshCheckTime(); --临时方案
    end

    function InsertSkill:OnSkillEnd()
        self._owner:RemoveArmor()
        self:BroadCastInsertSkillEnd()
        self._owner._level:OnCharInsertSkillEnd(self._owner._uuid)
    end

    function InsertSkill:BroadCastInsertSkillEnd()
        local eventType = EFightLuaEvent.Theatre6SkillEnd
        local eventArgs = XEventManager.GetEventArgs(eventType)
        eventArgs._skillType = ETheatre6SkillType.Insert
        eventArgs._skillId = self._skillId
        eventArgs._launcherUUID = self._owner._uuid
        eventArgs._targetUUID = self._owner._enemyUUID
        self._owner:DispatchLuaEvent(eventType, eventArgs)
    end

    function InsertSkill:RefreshForceContinueTime(actionId)
        self._forceContinueTime = self._owner._npcTime + self._owner._skillComboCaster:GetActionTime(actionId)
    end

    function InsertSkill:RefreshCheckTime()
        self._checkTime = self._owner._npcTime + self.CheckInterval
    end

    InsertSkill.OnCsNpcDamageEvent = XTheatre6CharBase.IncComboCountOnDamgeInState
    InsertSkill.End = XTheatre6CharBase.TryShutDownHandSideUxOnStateEnd
end

--endregion

--region 被动行为状态逻辑定义

-- WaitHit 等待受击状态逻辑
do
    ---@class XTheatre6CharBase.State.WaitHit:XTheatre6CharBase.State
    local WaitHit = States.WaitHit
    function WaitHit:ReEnter()
        return self:LogError("WaitHit:ReEnter Error: Repeat Enter")
    end

    function WaitHit:CheckCanRemainHandSideUx()
        --如果从前置状态衔接waitHit里面,说明出手方已交换给敌人
        --如果敌人是从受击状态释放的插入式技能,则暂时保持出手权特效,以防剧透
        if self._owner._level:IsInsertSkillFromDefend(self._owner._enemyUUID) then return true end
        return false
    end
end

-- Hit 受击状态逻辑
do
    ---@class XTheatre6CharBase.State.Hit:XTheatre6CharBase.State
    local Hit = States.Hit

    local SubState = {
        HitEnd = "HitEnd",
        HitLight = "HitLight",
        HitHeavy = "HitHeavy",
        HitDown = "HitDown",
        HitFly = "HitFly",
        HitLie = "HitLie"
    }
    Hit.SubState = SubState

    Hit.HitTypeMap = {
        [EHitType.None] = SubState.HitEnd,         -- 无

        [EHitType.HitLeft] = SubState.HitLight,    -- 左轻
        [EHitType.HitRight] = SubState.HitLight,   -- 右轻

        [EHitType.HeavyLeft] = SubState.HitHeavy,  -- 左重
        [EHitType.HeavyRight] = SubState.HitHeavy, -- 右重

        [EHitType.HitDown] = SubState.HitDown,     -- 击倒

        [EHitType.BeHitFly] = SubState.HitFly,     -- 击飞
        [EHitType.HoverHit] = SubState.HitFly,     -- 浮空受击
        [EHitType.FallDown] = SubState.HitFly,     -- 空中落地
        [EHitType.Hover] = SubState.HitFly,
        [EHitType.BeHitFlyBegin] = SubState.HitFly,
        [EHitType.BeHitFlyLoop] = SubState.HitFly,
        [EHitType.BeHitFlyToDown] = SubState.HitFly,
        [EHitType.BeHitFlyDownLoop] = SubState.HitFly,
        [EHitType.BeHitFlyDownToBounce] = SubState.HitFly,

        [EHitType.StandUp] = SubState.HitLie,    -- 起身
        [EHitType.LieOnFloor] = SubState.HitLie, -- 躺地 (击飞)

        [EHitType.HitToStand] = SubState.HitEnd,

        -- 这些子状态需要进一步看源码确认一下从属关系
        [EHitType.Suppress] = nil, -- 压制
    }

    Hit.CanBlockStates = {
        [SubState.HitEnd] = true,
        [SubState.HitLight] = true,
        [SubState.HitHeavy] = true,
    }

    function Hit:Start()
        local npc = self._owner
        npc:BreakSkillUi()
        npc:BreakComboUi()
    end

    function Hit:GetSubState()
        local hitType = self._proxy:GetNpcBeHitState(self._owner._uuid)
        local subState = self.HitTypeMap[hitType]
        if not subState then
            self:LogError("Hit:GetSubState Error: Unknown HitType : " .. tostring(hitType))
        end
        return subState
    end

    function Hit:CanBlock()
        return self.CanBlockStates[self:GetSubState()]
    end
end

-- Block 状态逻辑
do
    ---@class XTheatre6CharBase.State.Block:XTheatre6CharBase.State
    ---@field Actions integer[] 格挡成功时触发的动作id列表
    local Block = States.Block

    -- 格挡控制器触发格挡的通知
    function XTheatre6CharBase:OnBlock()
        self:SetState(StateEnum.Block)
    end

    -- 格挡控制器触发破防的通知
    function XTheatre6CharBase:OnBreakBlock()
        self:SetState(StateEnum.Hit)
    end

    function Block:Ctor()
        self._actIndex = 0
    end

    function Block:Start()
        self._actIndex = (self._actIndex + 1) % (#self.Actions)
        local actionId = self.Actions[self._actIndex + 1]
        self._owner:CastAction(actionId)
    end

    function Block:ReEnter()
        if not self._proxy:CheckCanCastSkill(self._owner._uuid) then return end
        self:Start()
    end
end

-- Delay 状态逻辑
do
    ---@class XTheatre6CharBase.State.Delay:XTheatre6CharBase.State
    local Delay = States.Delay
    Delay.NeedDelayStates = {
        [StateEnum.MainSkill] = "MainSkill",
        [StateEnum.InsertSkill] = "InsertSkill",
        [StateEnum.Wrestle] = "Wrestle",
        [StateEnum.Dodge] = "Dodge",
        [StateEnum.WrestleSucSkill] = "WrestleSucSkill",
        [StateEnum.DodgeSucSkill] = "DodgeSucSkill",
    }
    Delay.DelayTimeConfig =
    {
        HitLight = {
            Default = { nil, nil, 0.2, 0.5 }
        },

        HitHeavy = {
            Dodge = { nil, nil, 0.4 },
            Default = { 0, nil, 0.4, 0.7 }
        },

        HitDown = {
            Dodge = { nil, nil, 0.4 },
            Default = { 0, nil, 0.6, 1 }
        },

        HitFly = {
            Wrestle = { 0.2, 0.3, 1.2, 1.4},
            Dodge = { nil, nil, 0.4 },
            Default = { nil, nil, 0.8, 1.5 }
        },

        HitLie = {
            Default = { 0.2, 0.3, 0.4 },
        },

        Block = {
            Dodge = { nil, nil, 0.4 },
            Default = { nil, nil, 0.3, 0.7 }
        },

        MainSkill = {
            Wrestle = { 0.2, 0.3, 0.3 },
            Default = { nil, nil, 0 }
        },

        InsertSkill = {
            Wrestle = { 0.2, 0.3, 0.3 },
            Default = { nil, nil, 0 }
        },

        WrestleSucSkill = {
            Wrestle = { 0.2, 0.3, 0.3 },
            Default = { nil, nil, 0 }
        },

        DodgeSucSkill = {
            Wrestle = { 0.2, 0.3, 0.3 },
            Default = { nil, nil, 0 }
        },

        Wrestle = {
            Default = { 0.3, 0.5, 0.5 }
        },

        Dodge = {
            Default = { 0.1, 0.2, 0.3 }
        },

        Default = {
            Dodge = { nil, nil, 0.4 },
            Default = { nil, nil, 0.8, 1.2 },
        }
    }

    function Delay:DebugInfo()
        local sm = self._stateMachine
        local oldState = sm:GetStateById(self._oldStateId)
        local newState = sm:GetStateById(self._newStateId)
        return "oldState = " ..
            tostring(oldState and oldState.Name) .. ", newState = " .. tostring(newState and newState.Name)
    end

    function Delay:Prepare(oldStateId, newStateId)
        self._oldStateId = oldStateId
        self._newStateId = newStateId
    end

    function Delay:Start()
        local oldState, newState = self:GetOldStateName(), self.NeedDelayStates[self._newStateId]
        if (not (oldState and newState)) or (oldState == "WaitHit") then
            -- self:LogError("Delay:Start Error: Illegal Old State or New State, Record is:\n" .. self:DebugInfo())
            return self._stateMachine:SetStateById(self._newStateId)
        end

        local cfg = self.DelayTimeConfig
        cfg = cfg[oldState] or cfg.Default
        cfg = cfg[newState] or cfg.Default

        local proxy = self._proxy
        local minTime, maxTime
        minTime = cfg[1] or 0
        if cfg[2] then minTime = proxy:RandomFloat(minTime, cfg[2]) end

        maxTime = cfg[3] or math.maxinteger
        if cfg[4] then maxTime = proxy:RandomFloat(maxTime, cfg[4]) end

        local now = self._owner._npcTime

        self._minTime = now + minTime
        self._maxTime = now + maxTime
    end

    function Delay:ReEnter()
        self:LogError("Delay:ReEnter Error: Repeated Enter, Info:\n" .. self:DebugInfo())
        return self._stateMachine:SetStateById(self._newStateId)
    end

    function Delay:Update()
        local time = self._owner._npcTime
        if time < self._minTime then return end
        if self:CanCastAction() or time > self._maxTime then return self:Continue() end
    end

    function Delay:GetOldStateName()
        local oldState = self._stateMachine:GetStateById(self._oldStateId)
        local Hit = self._owner._states.Hit
        if oldState ~= Hit then return oldState.Name end

        --如果前置状态是受击状态, 则需要对受击状态进行细分
        return Hit:GetSubState()
    end

    function Delay:CanCastAction()
        return self._proxy:CheckCanCastSkill(self._owner._uuid)
    end

    function Delay:Continue()
        self._stateMachine:SetStateById(self._newStateId)
    end

    function Delay:CheckCanRemainHandSideUx()
        local newState = self._owner._states[self._newStateId]
        return newState.CheckCanRemainHandSideUx and newState:CheckCanRemainHandSideUx()
    end
end

-- Die 死亡状态逻辑
do
    ---@class XTheatre6CharBase.State.Die:XTheatre6CharBase.State
    local Die = States.Die

    function Die:Prepare(deadUuid, livingUuid)
        self._isDead = (self._owner._uuid == deadUuid)
        self._killerUuid = livingUuid
    end

    function Die:Start()
        local uuid = self._owner._uuid
        if self._isDead then
            -- self:LogError("setNpcDie")
            self._proxy:NpcDie(uuid, nil, self._killerUuid)
        else
            self._proxy:ApplyMagic(uuid, uuid, 1010051, 0, 1) --锁血
        end
    end

    function XTheatre6CharBase:OnCenterEnterDieState(deadUuid, livingUuid)
        self._states.Die:Prepare(deadUuid, livingUuid)
        self:SetState(StateEnum.Die)
    end
end

--endregion

--region 初始化

function XTheatre6CharBase:Ctor(proxy)
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._npcTime = 0
    self._stateMachine = self.StateMachine.New(self) ---@type XTheatre6CharBase.StateMachine
    self._states = self._stateMachine:GetStates()
    self._hasArmor = false
    self._affixControllers = {}
    self._updateControllers = {} ---@type table<string, XTheatre6AffixControllerBase>
    self._atkModifyTags = {}
    self._defModifyTags = {}
    self._isInited = false
    self._uiStates = {
        handSide = false,  -- 出手权UI
        skill = false,     -- 技能播报UI
        combo = false,     -- 连击数UI
    }
    self._isActive = false --是否为出手方的标记
    self._handSideUx = nil --角色的出手权头像UI动效
    self.StaminaDmgReducRatio = proxy:Theatre6GetConfig():GetInt("TLDmg-")
    self._overclockvalue = 0
    self._TLvalue = 0
end

function XTheatre6CharBase:_BaseInit()
    XTheatre6FightBase._BaseInit(self)
    self._name = self.__cname .. "." .. self._proxy:GetNpcTemplate(self._uuid).Id .. "." .. self._uuid 
end

function XTheatre6CharBase:OnEnterLevel(levelId)
    if self._isInited then return end
    self._isInited = true
    XTheatre6FightBase.OnEnterLevel(self, levelId)
    local caster = XTheatre6SkillComboCaster.New(self) --[[@as XTheatre6SkillComboCaster]]
    -- local caster = XTheatre6SkillComboCaster.New(self._proxy, self._uuid, self._enemyUUID) --[[@as XTheatre6SkillComboCaster]]
    self._skillComboCaster = caster
    if caster:GetSingleSkillConfig(ETheatre6SkillType.Wrestle) then self._hasWrestleSuccSkill = true end
    if caster:GetSingleSkillConfig(ETheatre6SkillType.Dodge) then self._hasDodgeSuccSkill = true end
end

-- function XTheatre6

function XTheatre6CharBase:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)                                           -- Npc伤害事件
    self._proxy:RegisterEvent(EWorldEvent.OnNpcBeHitBegin)                                     --受击事件
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)                                          --Buff添加事件
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)                                       --Buff删除事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
    local uuid = self._uuid
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, uuid)       --注册技能事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, uuid)
    -- self._proxy:RegisterEvent(EWorldEvent.NpcChangeDamageBeforeCalc)
end

function XTheatre6CharBase:HandleEvent(eventType, eventArgs)
    -- 由于通知接收与proxy绑定, 所以词条控制器的事件通知只能从这里转发出去
    for _, controller in pairs(self._affixControllers) do
        controller:HandleEvent(eventType, eventArgs)
    end

    XTheatre6FightBase.HandleEvent(self, eventType, eventArgs)

    if eventType == EWorldEvent.OnNpcBeHitBegin then
        -- self:LogError("HitBegin:" .. eventArgs.LauncherUUID .. ", " .. eventArgs.TargetUUID .. ", " .. eventArgs.HitType)
        self:OnNpcBeHitBegin(eventArgs.LauncherUUID, eventArgs.TargetUUID, eventArgs.HitType)
    end
end

function XTheatre6CharBase:HandleLuaEvent(eventType, eventArgs)
    -- self:LogError("HandleLuaEvent is called, event Type is " .. eventType)

    -- 由于通知接收与proxy绑定, 所以词条控制器的事件通知只能从这里转发出去
    for _, controller in pairs(self._affixControllers) do
        controller:HandleLuaEvent(eventType, eventArgs)
    end

    XTheatre6FightBase.HandleEvent(self, eventType, eventArgs)
end

--endregion

--region 流程相关接口

function XTheatre6CharBase:CastAction(actionId)
    -- self:LogError(self.__cname .. ".CastAction: " .. self._uuid .. " cast action " .. tostring(actionId) .. " to " .. self._enemyUUID)
    self._proxy:CastSkillActionToNpcNotCheck(self._uuid, actionId, self._enemyUUID)
end

function XTheatre6CharBase:GetUUID()
    return self._uuid
end

---检查单位体力是否清空
---@return boolean
function XTheatre6CharBase:HasStamina()
    return self._proxy:GetNpcGameplayAttribValue(self._uuid, ETheatre6AttribType.Stamina) > 0
end

---检查技能体力值消耗, 用于插入式技能
function XTheatre6CharBase:CheckSkillStaminaCostById(skillId)
    local skillConfig = self._proxy:Theatre6GetSkillConfig(skillId)
    if not skillConfig then
        self:LogError("XTheatre6CharBase:CheckSkillStaminaCostById Error: Unknown skillId " .. tostring(skillId))
        return false
    end

    if self:HasStamina() then return true end       --只要还有体力就允许放技能
    if skillConfig.CostTL <= 0 then return true end --如果没有体力消耗, 也允许释放(即使体力为空)

    return false
end

---检查技能体力值消耗, 用于主动技能,超算成功技能,拼刀成功技能
function XTheatre6CharBase:CheckSkillStaminaCostByType(skillType)
    local skillConfig = self._skillComboCaster:GetSkillConfig(skillType)
    if not skillConfig then
        self:LogError("XTheatre6CharBase:CheckSkillStaminaCostByType Error: No Skill Found , SkillType " ..
            tostring(skillType))
        return false
    end

    local skillId = skillConfig.Id
    if self:HasStamina() then return skillId end       --只要还有体力就允许放技能
    if skillConfig.CostTL <= 0 then return skillId end --如果没有体力消耗, 也允许释放(即使体力为空)

    return false
end

---检查单位是否存在拼刀成功技能
function XTheatre6CharBase:HasWrestleSuccSkill()
    return self._hasWrestleSuccSkill
end

---检查单位是否存在超算成功技能
function XTheatre6CharBase:HasDodgeSuccSkill()
    return self._hasDodgeSuccSkill
end

function XTheatre6CharBase:AddArmor()
    if self._hasArmor then return end
    self._proxy:ApplyMagic(self._uuid, self._uuid, ARMOR_BUFF)
    self._proxy:ApplyMagic(self._uuid, self._uuid, InTraction_BUFF)
    self._hasArmor = true
end

function XTheatre6CharBase:RemoveArmor()
    if not self._hasArmor then return end
    self._proxy:RemoveBuff(self._uuid, ARMOR_BUFF)
    self._proxy:RemoveBuff(self._uuid, InTraction_BUFF)
    self._hasArmor = false
end

--检查单位是否处于可以触发格挡的状态
function XTheatre6CharBase:CanBlock()
    if self:CheckState(StateEnum.Delay) then return false end
    return self._states.Hit:CanBlock()
end

--检查单位是否已经处于格挡状态
function XTheatre6CharBase:IsInBlock()
    return self:CheckState(StateEnum.Block)
end

--endregion

--region 词条相关接口
local XTheatre6AffixControllerBase = require("Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase")
local AffixControllerTag2Name = XTheatre6AffixControllerBase.Tag2Name

---@return XTheatre6CritController
function XTheatre6CharBase:GetCritController()
    return self:GetAffixControllerByName("Crit") --[[@as XTheatre6CritController]]
end

---@return XTheatre6HitFlyController
function XTheatre6CharBase:GetHitFlyController()
    return self:GetAffixControllerByName("HitFly") --[[@as XTheatre6HitFlyController]]
end

---@return XTheatre6HitDownController
function XTheatre6CharBase:GetHitDownController()
    return self:GetAffixControllerByName("HitDown") --[[@as XTheatre6HitDownController]]
end

---@return XTheatre6BurnController
function XTheatre6CharBase:GetBurnController()
    return self:GetAffixControllerByName("Burn") --[[@as XTheatre6BurnController]]
end

---@return XTheatre6BlockController
function XTheatre6CharBase:GetBlockController()
    return self:GetAffixControllerByName("Block") --[[@as XTheatre6BlockController]]
end

---@return XTheatre6AngerController
function XTheatre6CharBase:GetAngerController()
    return self:GetAffixControllerByName("Anger") --[[@as XTheatre6AngerController]]
end

---@return XTheatre6SunController
function XTheatre6CharBase:GetSunController()
    return self:GetAffixControllerByName("Sun") --[[@as XTheatre6SunController]]
end

---@return XTheatre6ProtectorController
function XTheatre6CharBase:GetProtectorController()
    return self:GetAffixControllerByName("Protector") --[[@as XTheatre6ProtectorController]]
end

---@return XTheatre6HypnoController
function XTheatre6CharBase:GetHypnoController()
    return self:GetAffixControllerByName("Hypno") --[[@as XTheatre6HypnoController]]
end

---@return XTheatre6PoisonedController
function XTheatre6CharBase:GetPoisonedController()
    return self:GetAffixControllerByName("Poisoned") --[[@as XTheatre6PoisonedController]]
end

---@param tag EGameplayTag [受击效果tag, 只能为Missle.Theatre6.HitAffixType的子tag](https://kurogame.feishu.cn/wiki/UadMwIczpirAH9k22YPcOI7WnJc#share-Pyibd6tS5oSwOAxOLvMccKmmn2c)
---@return XTheatre6AffixControllerBase
function XTheatre6CharBase:GetAffixControllerByHitTag(tag)
    return self:GetAffixControllerByName(AffixControllerTag2Name[tag])
end

---@param name string
---@return XTheatre6AffixControllerBase
function XTheatre6CharBase:GetAffixControllerByName(name)
    local controller = name and self._affixControllers[name]
    return controller or self:AddAffixController(name)
end

---@param controllerName string
---@return XTheatre6AffixControllerBase
function XTheatre6CharBase:AddAffixController(controllerName)
    local class = XTheatre6AffixControllerBase:GetAffixControllerClass(controllerName)
    if not class then
        self:LogError("AddAffixController Error: Unknown Controller Name " .. tostring(controllerName))
        return nil
    end
    local controller = class.New(self._proxy, self) ---@type XTheatre6AffixControllerBase
    self._affixControllers[controllerName] = controller
    controller:PostInit()
    return controller
end

function XTheatre6CharBase:RegisterAffixControllerUpdate(name)
    self._updateControllers[name] = self._affixControllers[name]
end

function XTheatre6CharBase:UnRegisterAffixControllerUpdate(name)
    self._updateControllers[name] = nil
end

function XTheatre6CharBase:RegisterAtkModifier(tag)
    self._atkModifyTags[tag] = true
end

function XTheatre6CharBase:UnregisterAtkModifier(tag)
    self._atkModifyTags[tag] = nil
end

function XTheatre6CharBase:RegisterDefModifier(tag)
    self._defModifyTags[tag] = true
end

function XTheatre6CharBase:UnregisterDefModifier(tag)
    self._defModifyTags[tag] = nil
end

function XTheatre6CharBase:GetAtkModifiers()
    return self._atkModifyTags
end

function XTheatre6CharBase:GetDefModifiers()
    return self._defModifyTags
end

function XTheatre6CharBase:DispatchLuaEvent(eventType, eventArgs, targetType)
    --由于lua事件不会发送给调用dispatch的proxy, 而词条控制器又和角色复用同一个proxy, 因此不得不在这里主动转发给自身的词条控制器
    for _, controller in pairs(self._affixControllers) do
        controller:HandleLuaEvent(eventType, eventArgs)
    end

    XTheatre6FightBase.DispatchLuaEvent(self, eventType, eventArgs, targetType)
end

--endregion

--region 事件通知

function XTheatre6CharBase:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    if launcher ~= self._uuid then return end
    -- self:LogError(eventName .. launcher)
    if eventName == "WrestleSuccEndFinish" then return self:OnWrestleSuccEndFinish(skillActionId, keyFrameId) end
    if eventName == "DodgeSuccEndFinish" then return self:OnDodgeSuccEndFinish(self._uuid) end
    if eventName == "ChangeCamera" then
        XLog.Warning("切换镜头")
        self._proxy:SetCameraFocusTarget(self._uuid, self._enemyUUID)
    end
end

---释放拼刀成功技能时增伤(乘区14)
---@param eventArgs BeforeDamageCalcEventArgs
function XTheatre6CharBase:BeforeDamageCalc(eventArgs)
    local state = self._stateMachine._curState
    if not state then return end
    return state.BeforeDamageCalc and state:BeforeDamageCalc(eventArgs)
end

---受伤时, 根据实时体力值进行减伤（独立乘区）
---@param eventArgs AfterDamageCalcEventArgs
function XTheatre6CharBase:AfterDamageCalc(eventArgs)
    if eventArgs.SkillActionId == 0 then return end
    if eventArgs.Target ~= self._uuid then return end

    if self._proxy:GetBuffCountByKind(self._uuid,1025800) >= 1 then
        local stamina = self._proxy:GetNpcGameplayAttribValue(self._uuid, ETheatre6AttribType.Stamina) - 50
        if stamina < 0 then return end
        local ratio = 1 - stamina * self.StaminaDmgReducRatio / 10000
        if ratio < 0.6 then ratio = 0.6 end
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalDamage * ratio, eventArgs
                .ElementDamage, eventArgs.FinalHackDamage)
    else
        local stamina = self._proxy:GetNpcGameplayAttribValue(self._uuid, ETheatre6AttribType.Stamina)
        if stamina < 0 then return end
        local ratio = 1 - stamina * self.StaminaDmgReducRatio / 10000
        if ratio < 0.6 then ratio = 0.6 end
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalDamage * ratio, eventArgs
                .ElementDamage, eventArgs.FinalHackDamage)
    end

    -- local value = 30
    -- local ratio = 1 - stamina * value / 10000
end

---受到伤害时 增加实时超算值
---@param launcherId number 伤害发起者的UUID
---@param targetId number 伤害目标的UUID
---@param magicId number 伤害Magic的配表Id
---@param kind number 策划定义的伤害类型
---@param physicalDamage number 物理伤害
---@param elementDamage number 元素伤害
---@param elementType number 元素伤害类型
---@param realDamage number 真实伤害
---@param isCritical boolean 是否暴击
---@param actionId number 动作Id
---@param magicTags table Magic配置的Tags
---@param customValue number 自定义值 (技能超算基础倍率)
function XTheatre6CharBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage,
                                            elementType, realDamage, isCritical, actionId, magicTags, customValue)
    --todo:超算值获取逻辑追加读取技能配置&局内动态调整

    local curState = self._stateMachine._curState
    if curState and curState.OnCsNpcDamageEvent then curState:OnCsNpcDamageEvent(launcherId, targetId, actionId) end

    --todo:连击数更新逻辑迁移
    -- if launcherId == self._uuid and targetId == self._enemyUUID then
    --     if actionId ~= 0 then
    --         self._proxy:Theatre6UpdateComboCountUI(launcherId)
    --     end
    -- elseif launcherId == self._enemyUUID and targetId == self._uuid then
    --     if actionId ~= 0 then
    --         self._proxy:Theatre6SwitchComboCountUI(targetId, false)
    --     end
    -- end

    if targetId ~= self._uuid then return end

    if self._proxy:Theatre6CheckNpcStun(targetId) then -- 如果目标 眩晕 则不增加超算值
        return
    end

    local maxOverClock = self._proxy:GetNpcGameplayAttribMaxValue(targetId, ETheatre6AttribType.OverClock)
    local overClockEfficiency = self._proxy:GetNpcGameplayAttribMaxValue(targetId,
        ETheatre6AttribType.OverClockEfficiency)
    local overClockDamage = maxOverClock * (1 + overClockEfficiency / 10000) *
        (customValue / 10000) -- * (customValue / 10000) -- 目前技能还没配置基础超算倍率

    self._proxy:Theatre6AddNpcRuntimeOverClock(targetId, overClockDamage)
end

---进入受击动作时的通知
---@param  launcherUUID integer 发起攻击的单位的uuid
---@param  targetUUID integer 收到攻击的单位的uuid
---@param  hitType EConfigHitType 受击动作的类型
function XTheatre6CharBase:OnNpcBeHitBegin(launcherUUID, targetUUID, hitType)
    if targetUUID ~= self._uuid then return end
    --TODO: 这里要判断如下内容:
    --1.是影响动画的受击, 还是纯数值受击
    --2.进入防御动画还是进入受击动画(尚未完成)
    if hitType == EConfigHitType.None then return end
    if not self:CheckState(StateEnum.WaitHit) then return end
    self:SetState(StateEnum.Hit)
end

function XTheatre6CharBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if casterNpcUUID ~= self._uuid then return end
    if buffId == 10254103 or buffId == 10253107 then
        XLog.Error("镜头跟随目标发生更改")
        self._proxy:SetCameraFocusTarget(self._uuid, self._enemyUUID)
    end
end

--endregion

function XTheatre6CharBase:Update(dt)
    self._npcTime = self._npcTime + dt --记录关卡已进行时间
    self._stateMachine:Update(dt)
    for _, affixController in pairs(self._updateControllers) do
        affixController:Update(dt)
    end

    local curOverClockValue = self._proxy:Theatre6GetNpcRuntimeOverClock(self._uuid)
    if self._overclockvalue ~= curOverClockValue then
        if self._overclockvalue < 100 and curOverClockValue >= 100 then
            self._proxy:Theatre6PopDamage(self._uuid, self._uuid, 10, 0)
        end
        self._overclockvalue = curOverClockValue
    end

    local curTLValue = self._proxy:GetNpcGameplayAttribValue(self._uuid, ETheatre6AttribType.Stamina)
    if self._TLvalue ~= curTLValue then
        if self._TLvalue > 0 and curTLValue <= 0 then
            self._proxy:Theatre6PopDamage(self._uuid, self._uuid, 9, 0)
        end
        self._TLvalue = curTLValue
    end
end

return XTheatre6CharBase
