local XLevelStateMachine = require("Gameplay/Theatre6/XTheatre6StateMachine")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")

---@class XLevelScript.1081:XTheatre6FightBase
local XLevelScript1081 = XDlcScriptManager.RegLevelLogicScript(1081, "XLevel1081")
local Vector3 = XMain.IsClient and CS.UnityEngine.Vector3 or CS.HaruMath.Vector3

--region 状态机框架搭建

local StateEnum = {
    Start = 0,
    Show = 1,
    Settle = 2,
    MainSkill = 3,
    InsertSkill = 4,
    Wrestle = 5, --拼刀
    Dodge = 6,   --超算
    Die = 7,
    End = 8,
    WrestleSucSkill = 9, --拼刀成功技能
    DodgeSucSkill = 10   --超算成功技能
}

---@class XLevelScript1081.State:XTheatre6State
---@field _owner XLevelScript.1081
---@field _stateMachine XLevelScript1081.StateMachine

---@class XLevelScript1081.StateMachine:XTheatre6StateMachine

local StateMachine, States = XLevelStateMachine:CreateClassByEnum(StateEnum, "XLevel1081")
XLevelScript1081.StateMachine = StateMachine --[[@as XLevelScript1081.StateMachine]]
XLevelScript1081.States = States --[[@as table<string|integer, XLevelScript1081.State>]]

---改变关卡状态
---@param stateId integer StateEnum中定义的状态Id
function XLevelScript1081:SetState(stateId)
    self._stateMachine:SetStateById(stateId)
end

--endregion

--region 状态逻辑定义

-- Start 状态逻辑
do
    ---@class XLevelScript1081.State.Start:XLevelScript1081.State
    local Start = States.Start

    Start.EndTime = 0 --Start阶段结束时间点

    function Start:Start()
        self._proxy:SetAutoChessUiActive(false, "FightUiEnable") --开局清空UI
    end

    function Start:Update(dt)
        if self._owner._levelTime < self.EndTime then return end
        return self._owner:SetState(StateEnum.Show)
    end
end

-- Show 状态逻辑
do
    ---@class XLevelScript1081.State.Show:XLevelScript1081.State
    local Show = States.Show
    function Show:Start()
        local fighter1UUID = self._owner._fighter1UUID
        local fighter2UUID = self._owner._fighter2UUID
        local spawnPoint = self._owner._spawnPoint

        self._proxy:AbortAction(fighter1UUID, true)             --打断出场动作
        self._proxy:SetNpcPosition(fighter1UUID, spawnPoint[2]) --传送玩家1位置
        --4.8修改内容，需要修改回去
        -- self._proxy:SetNpcRotation(fighter1UUID,{x = 0, y = 180, z = 0})
        self._proxy:SetNpcFaceToPosition(fighter1UUID, spawnPoint[3]) --设置看向2的位置

        self._proxy:AbortAction(fighter2UUID, true)                   --打断出场动作
        self._proxy:SetNpcPosition(fighter2UUID, spawnPoint[3])       --传送玩家2位置
        --4.8修改内容，需要修改回去
        -- self._proxy:SetNpcRotation(fighter2UUID,{x = 0, y = 180, z = 0})
        self._proxy:SetNpcFaceToPosition(fighter2UUID, spawnPoint[2]) --设置看向1的位置
    end

    Show.EndTime = 1 --Show阶段结束时间点
    function Show:Update(dt)
        if self._owner._levelTime < self.EndTime then return end
        return self._owner:SetState(StateEnum.Settle)
    end
end

-- Settle 状态逻辑
do
    ---@class XLevelScript1081.State.Settle:XLevelScript1081.State
    local Settle = States.Settle

    function Settle:Start()
        self._proxy:Theatre6CountDownMessageTip(3) --倒计时3秒
        self._proxy:Theatre6UIShowAnimation(true)  --开启角色战斗UI
        self._proxy:SetCameraOpEnable(false)       --禁止移动镜头
    end

    Settle.EndTime = 5       --Settle阶段结束时间点
    Settle._settleTime = 1   --倒计时阶段开始时间
    Settle._settleCamera = 1 --倒计时阶段镜头序号
    function Settle:Update(dt)
        local levelId = self._owner._levelId
        local levelTime = self._owner._levelTime
        local playerUUID = self._owner._fighter1UUID
        local NPC = self._owner._robotUUID
        local Camera = self._owner._OpenCamera

        if levelId == 1081 then
            if levelTime >= self._settleTime and self._settleCamera == 1 then
                self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 38.8, 2.4, 88, 10, -40, 0, 0, 0, 101,
                    false) --第一个镜头
                self._settleCamera = 2
            elseif levelTime >= self._settleTime + 1 and self._settleCamera == 2 then
                self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 38.8, 2.4, 88, 10, 40, 0, 0, 0, 101,
                    false) --第二个镜头
                self._settleCamera = 3
            elseif levelTime >= self._settleTime + 2 and self._settleCamera == 3 then
                self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 1, 0, 38.8, 5, 82, 15, 0, 0, 0, 0, 101, false) --第三个镜头
                self._settleCamera = 4
            elseif levelTime >= self._settleTime + 3 and self._settleCamera == 4 then
                self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0) --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                self._settleCamera = 0                                           --镜头计数归零
            end
        elseif levelId == 1082 then
            if levelTime >= self._settleTime and self._settleCamera == 1 then
                self._proxy:PlayCameraTimeline("Theatre6LevelStartCamera", NPC, 0.25, 0.25, 0)
                self._settleCamera = 2
            elseif levelTime >= self._settleTime + 3 and self._settleCamera == 2 then
                self._proxy:PlayCameraTimeline("Theatre6LevelStartCameraPre", NPC, 1.5, 0.75, 0)
                self._settleCamera = 3
            elseif levelTime >= self._settleTime + 4 and self._settleCamera == 3 then
                self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0)
                self._settleCamera = 4
            end
            --elseif levelTime >= self._settleTime + 3 and self._settleCamera == 3 then
            --    --self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 100, 20.417, 77.0256, 0, 0,
            --    --        0, 0, 0, 101, false,0)
            --    self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0)
            --    self._settleCamera = 0
            --if levelTime >= self._settleTime and self._settleCamera == 1 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 100, 22.667, 104.56, 3.157, 150.35,
            --        -3.415, 0, 0, 101, false) --第一个镜头
            --    self._settleCamera = 2
            --elseif levelTime >= self._settleTime + 1 and self._settleCamera == 2 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 100, 22.667, 104.56, 3.157, -150.35,
            --        -3.415, 0, 0, 101, false) --第二个镜头
            --    self._settleCamera = 3
            --elseif levelTime >= self._settleTime + 2 and self._settleCamera == 3 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 1, 0, 100, 21.667, 87.566, -6, 0, 0, 0, 0, 101,
            --        false) --第三个镜头
            --    self._settleCamera = 4
            --elseif levelTime >= self._settleTime + 3 and self._settleCamera == 4 then
            --    self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0) --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
            --    self._settleCamera = 0                                           --镜头计数归零
            --end
        elseif levelId == 1083 then
            if levelTime >= self._settleTime and self._settleCamera == 1 then
                self._proxy:PlayCameraTimeline("Theatre6LevelStartCamera", NPC, 0.25, 0.25, 0)
                self._settleCamera = 2
            elseif levelTime >= self._settleTime + 3 and self._settleCamera == 2 then
                self._proxy:PlayCameraTimeline("Theatre6LevelStartCameraPre", NPC, 1.5, 0.75, 0)
                self._settleCamera = 3
            elseif levelTime >= self._settleTime + 4 and self._settleCamera == 3 then
                self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0)
                self._settleCamera = 4
            end
            --if levelTime >= self._settleTime and self._settleCamera == 1 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 75, 3.25, 60.5, 11.157, -29.65,-3.415, 0, 0,
            --        101, false) --第一个镜头
            --    self._settleCamera = 2
            --elseif levelTime >= self._settleTime + 1 and self._settleCamera == 2 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 75, 3.25, 60.5, 11.157, 29.65,-3.415, 0, 0,  101,
            --        false) --第二个镜头
            --    self._settleCamera = 3
            --elseif levelTime >= self._settleTime + 2 and self._settleCamera == 3 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 1, 0, 75, 2.25, 52.5, -6, 0, 0, 0, 0, 101,
            --        false) --第三个镜头
            --    self._settleCamera = 4
            --elseif levelTime >= self._settleTime + 3 and self._settleCamera == 4 then
            --    self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0) --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
            --    self._settleCamera = 0                                           --镜头计数归零
            --end
        elseif levelId == 1084 then
            if levelTime >= self._settleTime and self._settleCamera == 1 then
                self._proxy:PlayCameraTimeline("Theatre6LevelStartCamera", NPC, 0.25, 0.25, 0)
                self._settleCamera = 2
            elseif levelTime >= self._settleTime + 3 and self._settleCamera == 2 then
                self._proxy:PlayCameraTimeline("Theatre6LevelStartCameraPre", NPC, 1.5, 0.75, 0)
                self._settleCamera = 3
            elseif levelTime >= self._settleTime + 4 and self._settleCamera == 3 then
                self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0)
                self._settleCamera = 4
            end
            --if levelTime >= self._settleTime and self._settleCamera == 1 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 57, 14.5, 54, 11.157, -29.65, -3.415, 0,
            --        0, 101, false) --第一个镜头
            --    self._settleCamera = 2
            --elseif levelTime >= self._settleTime + 1 and self._settleCamera == 2 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 0.5, 0, 57, 14.5, 54, 11.157, 29.65, -3.415, 0, 0,
            --        101, false) --第二个镜头
            --    self._settleCamera = 3
            --elseif levelTime >= self._settleTime + 2 and self._settleCamera == 3 then
            --    self._proxy:ActivateVCam(playerUUID, "DlcAutoChess", 0, 1, 0, 57, 13.5, 46, -6, 0, 0, 0, 0, 101, false) --第三个镜头
            ----    self._settleCamera = 4
            ----elseif levelTime >= self._settleTime + 3 and self._settleCamera == 4 then
            --    self._proxy:DeactivateVCam(playerUUID, "DlcAutoChess", false, 0) --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
            --    self._settleCamera = 0                                           --镜头计数归零
            --end
        end
        if levelTime < self.EndTime then return end
        return self._owner:SetState(StateEnum.Wrestle)
    end

    function Settle:End()
        local proxy = self._proxy
        local level = self._owner
        local spawnPoint = level._spawnPoint
        local fighter1UUID = level._fighter1UUID
        local fighter2UUID = level._fighter2UUID

        proxy:SetAutoChessUiActive(true, "FightUiEnable")        --打开UI
        proxy:Theatre6SetTimerTipsActive(true, level._levelTime) --打开时间面板

        --让双方冲向场地中央(临时方案)
        -- local center = Vector3((spawnPoint[2].x + spawnPoint[3].x) / 2, (spawnPoint[2].y + spawnPoint[3].y) / 2,
        --     (spawnPoint[2].z + spawnPoint[3].z) / 2)
        -- proxy:NpcMoveTo(fighter1UUID, center, ENpcMoveType.Sprint)
        -- proxy:NpcMoveTo(fighter2UUID, center, ENpcMoveType.Sprint)

        self._proxy:SetNpcFocusTarget(fighter1UUID, fighter2UUID)
        self._proxy:ApplyMagic(fighter1UUID, fighter1UUID, 1025112, 0, 1)
        self._proxy:ApplyMagic(fighter2UUID, fighter2UUID, 1025112, 0, 1)
        -- XLog.Debug("双方被加上了1025112BUFF")

        -- local searchtarget = self._proxy:GetFirstSearchTarget(fighter1UUID, ENpcTargetType.Enemy)        --新索敌获取权重最高目标，搜寻规则见表
        -- --搜索目标为空，返回
        -- if searchtarget == 0 then
        --     return
        -- end
        -- self._proxy:SetSoftLock(fighter1UUID, searchtarget) --直接使用新索敌获得目标设置为软锁目标，新索敌获得的id不可读，为组合生成内容
    end
end

-- Wrestle 拼刀状态逻辑
do
    ---@class XLevelScript1081.State.Wrestle:XLevelScript1081.State
    local Wrestle = States.Wrestle
    Wrestle.MaxDuration = 10 --Wrestle阶段的最大持续时间, 超出此时间后强制中断
    Wrestle.DiceTime = 2.5   --拼点等待时间(临时方案)

    Wrestle.NpcSubState =
    {
        Wait = 0,
        Ready = 1,
    }

    function Wrestle:ReEnter()
        self:LogError("Wrestle:ReEnter is Called")
        self:RefreshForceContinueTime()
    end

    function Wrestle:RefreshForceContinueTime()
        self._endTime = self._owner._levelTime + self.MaxDuration
    end

    function Wrestle:SecondWrestleContinueTime()
        self._endTime = self._owner._levelTime + self.MaxDuration
    end

    ---控制中心进入拼刀状态
    function Wrestle:Start()
        local npcSubState = self.NpcSubState
        self._fighter1SubState = npcSubState.Wait
        self._fighter2SubState = npcSubState.Wait

        self._owner:SendWrestleStartEvent()
        self:RefreshForceContinueTime()
    end

    ---发送控制中心进入拼刀状态的通知
    function XLevelScript1081:SendWrestleStartEvent()
        self._fighter1:OnCenterWrestleStart();
        self._fighter2:OnCenterWrestleStart();
    end

    function Wrestle:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        return self._owner:ForceContinue()
    end

    ---某一方完成了前置状态清理的事件
    function XLevelScript1081:OnCharWrestleReady(uuid)
        local Wrestle = self._states.Wrestle --[[@as XLevelScript1081.State.Wrestle]]
        Wrestle:RefreshForceContinueTime()
        local Ready = Wrestle.NpcSubState.Ready
        if uuid == self._fighter1UUID then Wrestle._fighter1SubState = Ready end
        if uuid == self._fighter2UUID then Wrestle._fighter2SubState = Ready end
        if Wrestle._fighter1SubState == Ready and Wrestle._fighter2SubState == Ready then
            if self._isFirstWrestle == false then
                local fighter1 = self._fighter1UUID
                local fighter2 = self._fighter2UUID
                local positon1 = self._spawnPoint[2]
                local positon2 = self._spawnPoint[3]
                self._fighter1:OnSecondWrestleReset(fighter1, fighter2, positon1, positon2)
                self._fighter2:OnSecondWrestleReset(fighter1, fighter2, positon1, positon2)
                XLog.Warning("二次拼刀退出动作完成")
                -----------------上述动作无法退会到拼刀起始点，有bug，临时处理如下----------------------
                -- self._proxy:AddTimerTask(0.3, function()
                --     self._proxy:SetNpcPosition(fighter1, positon1)
                --     self._proxy:SetNpcPosition(fighter2, positon2)
                -- end)
                ---------------------------修复后请删除中间区域内容------------------------------------
                self._proxy:AddTimerTask(1, function()
                    Wrestle:OnFightersReady()
                end)
                return
            end
            return Wrestle:OnFightersReady()
        end
    end

    ---控制中心已进入拼刀状态,并且双方均已完成前置状态清理
    function Wrestle:OnFightersReady()
        local level = self._owner --[[@as XLevelScript.1081]]
        local fighter1 = level._fighter1
        local fighter2 = level._fighter2
        local uuid1 = fighter1:GetUUID()
        local uuid2 = fighter2:GetUUID()
        local proxy = self._proxy


        level:SendWrestleBeginEvent()

        local spawnPoint = level._spawnPoint
        proxy:SetNpcFaceToPosition(uuid1, spawnPoint[1])
        proxy:SetNpcFaceToPosition(uuid2, spawnPoint[1])

        proxy:Theatre6UIShowAnimation(false) --隐藏角色战斗UI
        proxy:AddTimerTask(1, function()
            fighter1:HideComboUi()
            fighter1:HideSkillUi()
            fighter2:HideComboUi()
            fighter2:HideSkillUi()
        end) --隐藏战斗UI后, 在后台关闭技能面板和连击面板


        local robotUUID = level._robotUUID
        local Pindao_Start_camera = level._Pindao_Start_camera
        local Pindao_Start_3_camera = level._Pindao_Start_3_camera
        local FxPindaoStart = 1025009
        local PindaoShake = 10250205

        proxy:ApplyMagic(robotUUID, robotUUID, Pindao_Start_camera) --目前有bug，用不了
        XLog.Warning("开始拼刀镜头1" .. Pindao_Start_camera)

        if fighter1 and fighter1._Pindao_Start_2L_camera then
            local Pindao_Start_2L_camera = fighter1._Pindao_Start_2L_camera
            proxy:AddTimerTask(0.533, function()
                proxy:ApplyMagic(robotUUID, robotUUID, Pindao_Start_2L_camera)
                XLog.Warning("开始拼刀镜头2" .. Pindao_Start_2L_camera)
            end)
        end

        if fighter2 and fighter2._Pindao_Start_2R_camera then
            local Pindao_Start_2R_camera = fighter2._Pindao_Start_2R_camera
            proxy:AddTimerTask(1.4, function()
                proxy:ApplyMagic(robotUUID, robotUUID, Pindao_Start_2R_camera)
                XLog.Warning("开始拼刀镜头3" .. Pindao_Start_2R_camera)
            end)
        end

        --拼刀僵持镜头
        proxy:AddTimerTask(2.2, function()
            proxy:ApplyMagic(robotUUID, robotUUID, Pindao_Start_3_camera) --目前有bug，用不了
            XLog.Warning("开始拼刀镜头1" .. Pindao_Start_3_camera)
            proxy:SetNpcPosition(uuid1, spawnPoint[4])                    --传送玩家1位置
            proxy:SetNpcFaceToPosition(uuid1, spawnPoint[3])
            proxy:SetNpcPosition(uuid2, spawnPoint[5])                    --传送玩家2位置
            proxy:SetNpcFaceToPosition(uuid1, spawnPoint[4])
            fighter1:OnCenterWrestleCountinue(uuid1, uuid2)
            fighter2:OnCenterWrestleCountinue(uuid1, uuid2)
        end)

        proxy:AddTimerTask(2.62, function()
            proxy:Theatre6StartWrestleRollDice(self.DiceTime)
            proxy:ApplyMagic(robotUUID, robotUUID, FxPindaoStart)
        end)
        proxy:AddTimerTask(2.68, function()
            proxy:ApplyMagic(robotUUID, robotUUID, PindaoShake)
        end)
        self._owner._isFirstWrestle = false
    end

    ---发送双方完成前置状态清理的通知
    function XLevelScript1081:SendWrestleBeginEvent()
        local uuid1 = self._fighter1UUID
        local uuid2 = self._fighter2UUID
        self._fighter1:OnCenterWrestleBegin(uuid1, uuid2);
        self._fighter2:OnCenterWrestleBegin(uuid1, uuid2);
    end

    -- function XLevelScript1081:SendWrestleContinueEvent()
    --     --获取fighter1Npc和fighter2Npc
    --     local uuid1 = self._fighter1:GetUUID()
    --     local uuid2 = self._fighter2:GetUUID()

    --     self._proxy:AddTimerTask(2.2, function()
    --         self._fighter1:OnCenterWrestleCountinue(uuid1,uuid2);
    --         self._fighter2:OnCenterWrestleCountinue(uuid1,uuid2);
    --     end)
    -- end

    ---C# 拼刀拼点结束事件
    ---@param winnerUUID integer 拼点获胜的NpcUUID
    ---@param diff integer 差值
    function XLevelScript1081:OnCSWrestleRollDiceEndEvent(winnerUUID, diff)
        XLog.Warning("拼刀拼点结束事件" .. winnerUUID .. "获得了拼刀胜利, 点数差为" .. diff)
        if not self:CheckNpcUUID(winnerUUID) then return self:LogError("有意外的角色获得了拼刀胜利" .. winnerUUID) end
        if not self._stateMachine:CheckStateById(StateEnum.Wrestle) then
            local curState = self._stateMachine._curState
            self:LogError(
                " XLevelScript1081:OnCSWrestleRollDiceEndEvent Error: Called Outside Wrestle State, curState is " ..
                tostring(curState and curState.Name))
            return
        end
        local FxPindaoStart = 1025009

        self._proxy:RemoveBuff(self._robotUUID, FxPindaoStart)
        self:SetActionNpc(winnerUUID) --这里的UI表现时间点需要细化
        self:SetTempActionNpc(winnerUUID)
        self._proxy:SetCameraFocusTarget(winnerUUID, self:GetTempDefender():GetUUID())

        return self:SendWrestleRollDiceEndEvent(winnerUUID, diff)

        -- local level = self._owner
        -- local fighter1UUID = self._owner._fighter1UUID
        -- local fighter2UUID = self._owner._fighter2UUID

        -- if winnerUUID == fighter1UUID then
        --     level:CastWrestleSkill(fighter1UUID)
        -- elseif winnerUUID == fighter2UUID then
        --     level:CastWrestleSkill(fighter2UUID)
        -- end
    end

    ---发送拼刀拼点结束通知
    function XLevelScript1081:SendWrestleRollDiceEndEvent(winnerUUID, diff)
        self._proxy:RemoveBuff(self._robotUUID, self._Pindao_Start_camera)
        self._fighter1:OnCenterWrestleRollDiceEnd(winnerUUID, diff);
        self._fighter2:OnCenterWrestleRollDiceEnd(winnerUUID, diff);
    end

    ---角色拼刀成功终结动作结束事件
    ---@param uuid integer
    function XLevelScript1081:OnCharWrestleSuccEndFinish(uuid)
        self:OnControlCenter()
    end

    function Wrestle:End()
        self._proxy:Theatre6UIShowAnimation(true)
    end
end

-- Dodge 超算状态逻辑
do
    ---@class XLevelScript1081.State.Dodge:XLevelScript1081.State
    ---@field _launcher XTheatre6CharBase
    local Dodge = States.Dodge
    Dodge.MaxDuration = 5 --Dodge阶段的最大持续时间, 超出此时间后强制中断
    Dodge.DiceTime = 2    --拼点等待时间
    Dodge.NpcSubState =
    {
        Wait = 0,
        Ready = 1,
        Finish = 2
    }

    function Dodge:RefreshForceContinueTime()
        self._endTime = self._owner._levelTime + self.MaxDuration
    end

    function Dodge:DebugInfo()
        return "launcher = " .. tostring(self._launcher and self._launcher._name)
    end

    function Dodge:Prepare(defender)
        self._launcher = defender
    end

    ---控制中心进入超算状态
    function Dodge:Start()
        local npcSubState = self.NpcSubState
        self._fighter1SubState = npcSubState.Wait
        self._fighter2SubState = npcSubState.Wait
        self._owner:SendDodgeStartEvent(self._launcher:GetUUID())
        self:RefreshForceContinueTime()
    end

    ---发送控制中心进入超算状态的通知
    function XLevelScript1081:SendDodgeStartEvent(launcherUUID)
        self._fighter1:OnCenterDodgeStart(launcherUUID)
        self._fighter2:OnCenterDodgeStart(launcherUUID)
    end

    Dodge.ReEnter = Dodge.Start

    function Dodge:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        return self._owner:ForceContinue()
    end

    ---某一方完成了前置状态清理的事件
    function XLevelScript1081:OnCharDodgeReady(uuid)
        local Dodge = self._states.Dodge --[[@as XLevelScript1081.State.Dodge]]
        Dodge:RefreshForceContinueTime()
        local Ready = Dodge.NpcSubState.Ready
        if uuid == self._fighter1UUID then Dodge._fighter1SubState = Ready end
        if uuid == self._fighter2UUID then Dodge._fighter2SubState = Ready end
        if Dodge._fighter1SubState == Ready and Dodge._fighter2SubState == Ready then
            return Dodge:OnFightersReady()
        end
    end

    ---控制中心已进入超算状态,并且双方均已完成前置状态清理
    function Dodge:OnFightersReady()
        local launcherUUID = self._launcher:GetUUID()
        --启动拼点(临时方案)
        self._proxy:Theatre6StartDodgeRollDice(launcherUUID, self.DiceTime)
        self._proxy:Theatre6UIShowAnimation(false)

        self._owner:SendDodgeBeginEvent(launcherUUID)
        --ToDo处理出手方UI
        --level:SetActionNpc(0);
    end

    ---发送双方完成前置状态清理的通知
    function XLevelScript1081:SendDodgeBeginEvent(launcherUUID)
        self._fighter1:OnCenterDodgeBegin(launcherUUID);
        self._fighter2:OnCenterDodgeBegin(launcherUUID);
    end

    ---C# 超算拼点结束事件
    ---@param launcherUUID number @ 超算发起方的NpcUUID
    ---@param winnerUUID number @ 拼点获胜方的NpcUUID
    function XLevelScript1081:OnCSDodgeRollDiceEndEvent(launcherUUID, winnerUUID)
        XLog.Warning("超算拼点结束事件" .. winnerUUID .. "获得了超算胜利, 发起方为" .. launcherUUID)

        if not self:CheckNpcUUID(winnerUUID) then return self:LogError("有意外的角色获得了超算胜利" .. winnerUUID) end
        if not self._stateMachine:CheckStateById(StateEnum.Dodge) then
            local curState = self._stateMachine._curState
            self:LogError(" XLevelScript1081:OnCSDodgeRollDiceEndEvent Error: Called Outside Dodge State, curState is " ..
                tostring(curState and curState.Name))
        end
        local FxPindaoStart = 1025009

        self._proxy:RemoveBuff(self._robotUUID, FxPindaoStart)
        self:SetActionNpc(winnerUUID) --这里的UI表现时间点需要细化
        self:SetTempActionNpc(winnerUUID)

        return self:SendDodgeRollDiceEndEvent(launcherUUID, winnerUUID)
    end

    ---发送超算拼点结束通知
    ---@param launcherUUID integer 发起超算的单位的uuid
    ---@param winnerUUID integer 超算拼点获胜的单位的uuid
    function XLevelScript1081:SendDodgeRollDiceEndEvent(launcherUUID, winnerUUID)
        self._fighter1:OnCenterDodgeRollDiceEnd(launcherUUID, winnerUUID);
        self._fighter2:OnCenterDodgeRollDiceEnd(launcherUUID, winnerUUID);
    end

    ---角色超算终结成功动作结束通知
    ---@param uuid integer
    function XLevelScript1081:OnCharDodgeSuccEndFinish(uuid)
        local Dodge = self._states.Dodge --[[@as XLevelScript1081.State.Dodge]]
        if uuid == self._fighter1UUID then Dodge._fighter1SubState = Dodge.NpcSubState.Finish end
        if uuid == self._fighter2UUID then Dodge._fighter2SubState = Dodge.NpcSubState.Finish end

        if Dodge._fighter1SubState == Dodge.NpcSubState.Finish and Dodge._fighter2SubState == Dodge.NpcSubState.Finish then
            self:OnControlCenter()
        end
    end

    function Dodge:End()
        self._proxy:Theatre6UIShowAnimation(true)
        self._launcher = nil
    end
end

-- WrestleSucSkill 拼刀成功技状态逻辑
do
    ---@class XLevelScript1081.State.WrestleSucSkill:XLevelScript1081.State
    local WrestleSucSkill = States.WrestleSucSkill

    ---@param npc XTheatre6CharBase 要释放主动技能的NPC
    function WrestleSucSkill:Prepare(npc)
        self._launcher = npc
    end

    WrestleSucSkill.MaxDuration = 10 --WrestleSucSkill阶段的最大持续时间, 如果在此时间内没有收到来自角色的任何更新, 则强制继续后续流程
    function WrestleSucSkill:Start()
        local level = self._owner
        local launcherUUID = level:GetAttacker():GetUUID()

        self._endTime = math.maxinteger

        level:SetTempActionNpc(launcherUUID);
        level:SendWrestleSucSkillStartEvent(launcherUUID);
    end

    WrestleSucSkill.ReEnter = WrestleSucSkill.Start

    function WrestleSucSkill:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        return self._owner:ForceContinue()
    end

    function WrestleSucSkill:End()
        self._launcher = nil
        self._skillId = nil
    end

    function XLevelScript1081:SendWrestleSucSkillStartEvent(launcherUUID)
        self._fighter1:OnCenterCastWrestleSucSkill(launcherUUID);
        self._fighter2:OnCenterCastWrestleSucSkill(launcherUUID);
    end

    function XLevelScript1081:RefreshWrestleSucSkillForceContinueTime(skillTime)
        self._states.WrestleSucSkill._endTime = self._levelTime + skillTime
    end

    ---角色拼刀成功技能结束通知
    ---@param uuid integer
    function XLevelScript1081:OnCharWrestleSucSkillEnd(uuid)
        self:OnControlCenter()
    end
end

-- DodgeSucSkill 超算成功技状态逻辑
do
    ---@class XLevelScript1081.State.DodgeSucSkill:XLevelScript1081.State
    local DodgeSucSkill = States.DodgeSucSkill

    ---@param npc XTheatre6CharBase 要释放主动技能的NPC
    function DodgeSucSkill:Prepare(npc)
        self._launcher = npc
    end

    DodgeSucSkill.MaxDuration = 10 --DodgeSucSkill阶段的最大持续时间, 如果在此时间内没有收到来自角色的任何更新, 则强制继续后续流程
    function DodgeSucSkill:Start()
        local level = self._owner
        local launcherUUID = self._launcher:GetUUID()

        self._endTime = math.maxinteger

        level:SetTempActionNpc(launcherUUID);
        level:SendDodgeSucSkillStartEvent(launcherUUID);
    end

    DodgeSucSkill.ReEnter = DodgeSucSkill.Start

    function DodgeSucSkill:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        return self._owner:ForceContinue()
    end

    function DodgeSucSkill:End()
        self._launcher = nil
        self._skillId = nil
    end

    function XLevelScript1081:SendDodgeSucSkillStartEvent(launcherUUID)
        self._fighter1:OnCenterCastDodgeSucSkill(launcherUUID);
        self._fighter2:OnCenterCastDodgeSucSkill(launcherUUID);
    end

    function XLevelScript1081:RefreshDodgeSucSkillForceContinueTime(skillTime)
        self._states.DodgeSucSkill._endTime = self._levelTime + skillTime
    end

    ---角色拼刀成功技能结束通知
    ---@param uuid integer
    function XLevelScript1081:OnCharDodgeSucSkillEnd(uuid)
        self:OnControlCenter()
    end
end

-- MainSkill 主动技能状态逻辑
do
    ---@class XLevelScript1081.State.MainSkill:XLevelScript1081.State
    local MainSkill = States.MainSkill

    ---@param npc XTheatre6CharBase 要释放主动技能的NPC
    function MainSkill:Prepare(npc)
        self._launcher = npc
    end

    MainSkill.MaxDuration = 10 --MainSkill阶段的最大持续时间, 如果在此时间内没有收到来自角色的任何更新, 则强制继续后续流程
    function MainSkill:Start()
        local level = self._owner
        local launcherUUID = self._launcher:GetUUID()

        self._endTime = math.maxinteger
        -- self:LogError("MainSkillEndTime is set to inf " .. self._endTime)

        level:SetActionNpc(launcherUUID);
        level:SetTempActionNpc(launcherUUID);
        level:SendMainSkillStartEvent(launcherUUID);
    end

    MainSkill.ReEnter = MainSkill.Start

    function MainSkill:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        return self._owner:ForceContinue()
    end

    function MainSkill:End()
        self._launcher = nil
    end

    function XLevelScript1081:SendMainSkillStartEvent(launcherUUID)
        self._fighter1:OnCenterCastMainSkill(launcherUUID);
        self._fighter2:OnCenterCastMainSkill(launcherUUID);
    end

    function XLevelScript1081:RefreshMainSkillForceContinueTime(skillTime)
        self._states.MainSkill._endTime = self._levelTime + skillTime
        -- self:LogError("MainSkillEndTime is refresed to " .. self._states.MainSkill._endTime )
    end

    ---角色主动技能结束通知
    ---@param uuid integer
    function XLevelScript1081:OnCharMainSkillEnd(uuid)
        self:OnControlCenter()
    end
end

-- InsertSkill 插入技状态逻辑
do
    ---@class XLevelScript1081.State.InsertSkill:XLevelScript1081.State
    local InsertSkill = States.InsertSkill

    ---@param npc XTheatre6CharBase 要释放主动技能的NPC
    function InsertSkill:Prepare(npc, skillId)
        self._launcher = npc
        self._skillId = skillId
        self._isCastFromDefend = (npc == self._owner:GetTempDefender())
    end

    InsertSkill.MaxDuration = 10 --InsertSkill阶段的最大持续时间, 如果在此时间内没有收到来自角色的任何更新, 则强制继续后续流程
    function InsertSkill:Start()
        local level = self._owner
        local launcherUUID = self._launcher:GetUUID()

        self._endTime = math.maxinteger

        level:SetTempActionNpc(launcherUUID);
        level:SendInsertSkillStartEvent(launcherUUID, self._skillId);
    end

    InsertSkill.ReEnter = InsertSkill.Start

    function InsertSkill:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        return self._owner:ForceContinue()
    end

    function InsertSkill:End()
        self._launcher = nil
        self._skillId = nil
        self._isCastFromDefend = false
    end

    function XLevelScript1081:SendInsertSkillStartEvent(launcherUUID, skillId)
        self._fighter1:OnCenterCastInsertSkill(launcherUUID, skillId);
        self._fighter2:OnCenterCastInsertSkill(launcherUUID, skillId);
    end

    function XLevelScript1081:RefreshInsertSkillForceContinueTime(skillTime)
        self._states.InsertSkill._endTime = self._levelTime + skillTime
    end

    ---角色插入式技能结束通知
    ---@param uuid integer
    function XLevelScript1081:OnCharInsertSkillEnd(uuid)
        self:OnControlCenter()
    end

    function InsertSkill:IsCastFromDefend(npcUUID)
        return npcUUID == self._launcher:GetUUID() and self._isCastFromDefend
    end

    ---检查给定角色是否从受击状态中释放插入式技能
    ---@param npcUUID integer
    function XLevelScript1081:IsInsertSkillFromDefend(npcUUID)
        if not self._stateMachine:CheckStateById(StateEnum.InsertSkill) then return false end
        local state = self._states.InsertSkill --[[@as XLevelScript1081.State.InsertSkill]]
        return state:IsCastFromDefend(npcUUID)
    end
end

-- Die 角色死亡状态逻辑
do
    ---@class XLevelScript1081.State.Die:XLevelScript1081.State
    local Die = States.Die
    Die.Duration = 0.5

    ---@param deadNpc XTheatre6CharBase
    ---@param livingNpc XTheatre6CharBase
    function Die:Prepare(deadNpc, livingNpc)
        self._deadNpc = deadNpc
        self._livingNpc = livingNpc
    end

    function Die:Start()
        self._endTime = self._owner._levelTime + self.Duration

        local proxy = self._proxy
        local deadUuid = self._deadNpc:GetUUID()
        local livingUuid = self._livingNpc:GetUUID()

        proxy:SetAutoChessUiActive(true, "FightUiDisable") --战斗UI退场

        proxy:RemoveBuff(deadUuid, 1025111)
        proxy:RemoveBuff(livingUuid, 1025111)
        self:LogError("卸载角色疲劳BUFF")
        proxy:KillStayScreenEffectById(1071001) --卸载疲劳状态屏幕特效
        self:LogError("结束阶段卸载疲劳屏幕特效")

        self._owner:SendDieStartEvent(deadUuid, livingUuid)
    end

    Die.EndState = States.End

    function Die:Update(dt)
        if self._owner._levelTime < self._endTime then return end
        self.EndState:Prepare(self._livingNpc)
        self._owner:SetState(StateEnum.End)
    end

    function XLevelScript1081:SendDieStartEvent(deadUuid, livingUuid)
        self._fighter1:OnCenterEnterDieState(deadUuid, livingUuid)
        self._fighter2:OnCenterEnterDieState(deadUuid, livingUuid)
    end
end

-- End 状态逻辑
do
    ---@class XLevelScript1081.State.End:XLevelScript1081.State
    local End = States.End

    function End:Prepare(livingNpc)
        self._livingNpc = livingNpc
    end

    function End:Start()
        local level = self._owner
        local proxy = self._proxy
        local fighter1Uuid = level._fighter1UUID
        proxy:RemoveNpcFocusTarget(fighter1Uuid)
        proxy:SetCameraCharacterTarget(fighter1Uuid)
        proxy:SettleFight(self._livingNpc == level._fighter1)
    end
end

--endregion

--region 决策逻辑

--- 中控行为 全局出手权判断
function XLevelScript1081:OnControlCenter()
    --如果已经处于死亡之后的流程，直接返回
    if self._stateMachine:CheckStateById(StateEnum.End) or self._stateMachine:CheckStateById(StateEnum.Die) then return end

    --如果有角色死亡，启动死亡流程
    if self:CheckNpcDie(self._fighter2UUID) then
        -- if self._fighter2UUID == 0 then
        self._states.Die:Prepare(self._fighter2, self._fighter1)
        self:SetState(StateEnum.Die)
        return
    end

    if self:CheckNpcDie(self._fighter1UUID) then
        -- if self._fighter1UUID == 0 then
        self._states.Die:Prepare(self._fighter1, self._fighter2)
        self:SetState(StateEnum.Die)
        return
    end

    --判断玩家能否释放拼刀成功技能
    if self:CheckCanCastWrestleSucSkill(self:GetAttacker()) then
        self:SetState(StateEnum.WrestleSucSkill)
        return
    end

    --判断玩家能否释放超算成功技能
    if self:CheckCanCastDodgeSucSkill(self._states.Dodge._launcher) then
        self._states.DodgeSucSkill:Prepare(self._states.Dodge._launcher)
        self:SetState(StateEnum.DodgeSucSkill)
        return
    end

    --尝试触发玩家插入式技能
    local skillId = self:CheckCanCastInsertSkill(self._fighter1)
    if skillId then
        self._states.InsertSkill:Prepare(self._fighter1, skillId)
        self:SetState(StateEnum.InsertSkill)
        return
    end

    --尝试触发敌方插入式技能
    skillId = self:CheckCanCastInsertSkill(self._fighter2)
    if skillId then
        self._states.InsertSkill:Prepare(self._fighter2, skillId)
        self:SetState(StateEnum.InsertSkill)
        return
    end

    local attacker, defender = self:GetAttacker(), self:GetDefender()
    if not (attacker and defender) then
        return self:LogError("XLevelScript1081:OnControlCenter Error: Lost Attacker or Defender")
    end

    --尝试触发守方超算
    if self:CheckCanCastDodge(defender) then
        self._states.Dodge:Prepare(defender)
        self:SetState(StateEnum.Dodge)
        return
    end

    --攻方尝试继续释放主动技能
    if self:CheckCanCastMainSkill(attacker) then
        self._states.MainSkill:Prepare(attacker)
        self:SetState(StateEnum.MainSkill)
        return
    end

    --攻方体力耗尽, 守方尝试释放主动技能

    if self:CheckCanCastMainSkill(defender) then
        self._states.MainSkill:Prepare(defender)
        self:SetState(StateEnum.MainSkill)
        return
    end

    -- XLog.Error("fighter1uuid = " .. self._fighter1UUID)
    -- XLog.Error("fighter1 Stamina = " ..  self._proxy:GetNpcGameplayAttribValue(self._fighter1UUID, ETheatre6AttribType.Stamina))

    -- XLog.Error("fighter2uuid = " .. self._fighter2UUID)
    -- XLog.Error("fighter2 Stamina = " ..  self._proxy:GetNpcGameplayAttribValue(self._fighter2UUID, ETheatre6AttribType.Stamina))

    --攻守双方体力均耗尽, 触发拼刀
    self:SetState(StateEnum.Wrestle)

    -- if self:TryCastQueuedInsertSkill(self._fighter1UUID) then
    --     return
    -- end

    -- if self:TryCastQueuedInsertSkill(self._fighter2UUID) then
    --     return
    -- end

    -- if self:CheckActionNpcIsValid() then -- 当前有出手角色, 说明是在攻防阶段
    --     --尝试触发守方超算
    --     if self:CheckIsActionNpc(self._fighter1UUID) then
    --         if self:CheckNpcRuntimeOverClockIsMax(self._fighter2UUID) then
    --             self:StartDodgeRollDice(self._fighter2UUID)
    --             return
    --         end
    --     elseif self:CheckIsActionNpc(self._fighter2UUID) then
    --         if self:CheckNpcRuntimeOverClockIsMax(self._fighter1UUID) then
    --             self:StartDodgeRollDice(self._fighter1UUID)
    --             return
    --         end
    --     end

    --     --尝试触发攻方主动技能
    --     if self:CheckIsActionNpc(self._fighter1UUID) and self._proxy:GetNpcGameplayAttribValue(self._fighter1UUID, ETheatre6AttribType.Stamina) > 0 then
    --         self:CastMainSkill(self._fighter1UUID)
    --     elseif self:CheckIsActionNpc(self._fighter2UUID) and self._proxy:GetNpcGameplayAttribValue(self._fighter2UUID, ETheatre6AttribType.Stamina) > 0 then
    --         self:CastMainSkill(self._fighter2UUID)
    --     else
    --         --攻方体力耗尽, 重新决策
    --         self:SetActionNpc(0)
    --         self:OnControlCenter()
    --     end
    -- else -- 当前没有出手角色, 查下来只有攻方体力耗尽这一种情况
    --     if self._proxy:GetNpcGameplayAttribValue(self._fighter1UUID, ETheatre6AttribType.Stamina) > 0 then
    --         self:CastMainSkill(self._fighter1UUID)
    --     elseif self._proxy:GetNpcGameplayAttribValue(self._fighter2UUID, ETheatre6AttribType.Stamina) > 0 then
    --         self:CastMainSkill(self._fighter2UUID)
    --     else
    --         self:StartWrestleRollDice() -- 双发体力耗尽，进行拼刀
    --     end
    -- end
end

---检查单位HP是否已经清空
---@param uuid integer
---@return boolean
function XLevelScript1081:CheckNpcDie(uuid)
    return self._proxy:GetNpcAttribValue(uuid, ENpcAttrib.Life) <= 0
end

---检查单位体力是否清空
---@param uuid integer
---@return boolean
function XLevelScript1081:CheckHasStamina(uuid)
    return self._proxy:GetNpcGameplayAttribValue(uuid, ETheatre6AttribType.Stamina) > 0
end

---检查是否存在可以释放的插入式技能, 如果存在, 返回该技能的id
---@param npc XTheatre6CharBase
---@return integer | nil
function XLevelScript1081:CheckCanCastInsertSkill(npc)
    local uuid = npc:GetUUID()
    local queue = self:GetInsertSkillQueue(uuid)
    if not queue or #queue <= 0 then
        return nil
    end

    local skillId = queue[1]
    if not npc:CheckSkillStaminaCostById(skillId) then return end

    return table.remove(queue, 1)
end

---检查是否存在可以释放的拼刀成功技能, 如果存在, 返回该技能的id
---@param npc XTheatre6CharBase
---@return bool | nil
function XLevelScript1081:CheckCanCastWrestleSucSkill(npc)
    local uuid = npc:GetUUID()
    local hasWrestleSucSkill = npc:HasWrestleSuccSkill()
    --如果处在拼刀技能状态，则释放拼刀成功技能
    if not self._stateMachine:CheckStateById(StateEnum.Wrestle) then
        return false
    end
    if not hasWrestleSucSkill then return false end
    return true
end

---检查是否存在可以释放的超算成功技能, 如果存在, 返回该技能的id
---@param npc XTheatre6CharBase
---@return bool | nil
function XLevelScript1081:CheckCanCastDodgeSucSkill(npc)
    --如果处在拼刀技能状态，则释放拼刀成功技能
    if self:GetAttacker() ~= npc then
        return false
    end
    if not self._stateMachine:CheckStateById(StateEnum.Dodge) then
        return false
    end
    if not npc:HasDodgeSuccSkill() then return false end
    return true
end

---检查是否可以触发超算
---@param npc XTheatre6CharBase
---@return bool
function XLevelScript1081:CheckCanCastDodge(npc)
    ---需要满足如下条件:
    ---既没有出手权, 也不是出手方, 即完全处于受击/防御状态
    ---超算值满
    if not self:CheckNpcRuntimeOverClockIsMax(npc:GetUUID()) then return false end
    if npc ~= self:GetDefender() or npc ~= self:GetTempDefender() then return false end
    return true
end

---检查是否可以释放下一个主动技能
---@param npc XTheatre6CharBase
---@return bool
function XLevelScript1081:CheckCanCastMainSkill(npc)
    return npc:CheckSkillStaminaCostByType(ETheatre6SkillType.Main)
end

--endregion

--region 受击结算逻辑
local GameplayTag = require "Tools/GameplayTag/GameplayTag"
local XGameplayTag = require "Enum/XGameplayTag"
local HitTagSourceType = require("Gameplay/Theatre6/AffixController/XTheatre6AffixControllerBase").EHitTagSourceType


-- function XLevelScript1081:OnMissileColliderNpc(contextId, missileUUID, launcherNpcUUID, targetNpcUUID, result, type)
function XLevelScript1081:OnMissileHitEvent(missileUUID, targetNpcUUID, launcherNpcUUID)
    local proxy = self._proxy
    local isSucced, actionId = proxy:GetMissileActionId(missileUUID)
    if not isSucced then return end
    local skillId = proxy:Theatre6GetSkillByAction(launcherNpcUUID, actionId)

    local attacker, defender = self:GetNpcByUUID(launcherNpcUUID), self:GetNpcByUUID(targetNpcUUID)
    if not (attacker and defender) then return end

    local hitCount = self._misHitCountRecord[missileUUID] or 0
    hitCount = hitCount + 1
    self._misHitCountRecord[missileUUID] = hitCount

    local HIT_TAG = XGameplayTag.Missile_Theatre6_HitAffixType
    local ACTIVATE_TAG = XGameplayTag.Missile_Theatre6_HitAffixType_Activate
    local KILL_TAG = XGameplayTag.Missile_Theatre6_HitAffixType_Kill
    local STATIC_ATK = HitTagSourceType.StaticAtk
    local DYNAMIC_ATK = HitTagSourceType.DynamicAtk
    local DYNAMIC_DEF = HitTagSourceType.DynamicDef
    local isActivate
    local finalTags = self._tempHitTags
    local triggeredTags = self._tempTriggerHitTags

    --收集子弹上的tag
    local _, missileTemplateId = proxy:MissileUUIDToTemplateId(missileUUID)
    local atkTags = proxy:GetMissileTemplateTags(missileTemplateId)
    for i = 0, atkTags.Count - 1 do
        local tag = atkTags[i]
        if tag == ACTIVATE_TAG then
            isActivate = true
        elseif tag == KILL_TAG then
        elseif GameplayTag.MatchTagInTree(tag, HIT_TAG) then
            finalTags[tag] = STATIC_ATK
        end
    end

    --收集攻击修改器
    atkTags = attacker:GetAtkModifiers()
    for tag, _ in pairs(atkTags) do
        if GameplayTag.MatchTagInTree(tag, HIT_TAG) then
            finalTags[tag] = (finalTags[tag] or 0) | DYNAMIC_ATK
        end
    end

    --收集受击修改器
    local defTags = defender:GetDefModifiers()
    for tag, _ in pairs(defTags) do
        if GameplayTag.MatchTagInTree(tag, HIT_TAG) then
            finalTags[tag] = (finalTags[tag] or 0) | DYNAMIC_DEF
        end
    end

    --没有收集到任何hit效果,只尝试广播特殊命中
    if not next(finalTags) then
        return isActivate and
            self:BroadCastSpecialHit(missileUUID, launcherNpcUUID, targetNpcUUID, nil, actionId, skillId, hitCount)
    end

    --存在hit效果
    --收集哪些效果满足触发条件
    local controller, isAtkTriggered, isDefTriggered

    for tag, srcType in pairs(finalTags) do
        if (srcType & DYNAMIC_ATK ~= 0) or (srcType & STATIC_ATK ~= 0) then
            -- self:LogError(tostring(tag))
            controller = attacker:GetAffixControllerByHitTag(tag)
            isAtkTriggered = controller and
                controller:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate,
                    hitCount)
        end

        if srcType & DYNAMIC_DEF ~= 0 then
            controller = defender:GetAffixControllerByHitTag(tag)
            isDefTriggered = controller and
                controller:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType, isActivate,
                    hitCount)
        end

        triggeredTags[tag] = isAtkTriggered or isDefTriggered
    end

    --触发对应效果
    local srcType
    local ATK = DYNAMIC_ATK | STATIC_ATK
    for tag, isTriggered in pairs(triggeredTags) do
        if not isTriggered then goto continue end
        srcType = finalTags[tag]

        if srcType & ATK ~= 0 then
            controller = attacker:GetAffixControllerByHitTag(tag)
            if controller then
                controller:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType, triggeredTags,
                    actionId, skillId, hitCount)
            end
        end

        if srcType & DYNAMIC_DEF ~= 0 then
            controller = defender:GetAffixControllerByHitTag(tag)
            if controller then
                controller:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate, srcType, triggeredTags,
                    actionId, skillId, hitCount)
            end
        end
        ::continue::
    end

    --广播特殊命中通知
    if isActivate then
        self:BroadCastSpecialHit(missileUUID, launcherNpcUUID, targetNpcUUID, triggeredTags, actionId, skillId, hitCount)
    end

    self:ClearTempHitTags()
end

--清空临时表
function XLevelScript1081:ClearTempHitTags()
    local tempTags = self._tempHitTags
    for tag, _ in pairs(tempTags) do
        tempTags[tag] = nil
    end
    tempTags = self._tempTriggerHitTags
    for tag, _ in pairs(tempTags) do
        tempTags[tag] = nil
    end
end

--广播特殊命中通知
-- function XLevelScript1081:BroadCastSpecialHit(contextId, missileUUID, launcherNpcUUID, targetNpcUUID, triggeredTags)
function XLevelScript1081:BroadCastSpecialHit(missileUUID, launcherNpcUUID, targetNpcUUID, triggeredTags, actionId,
                                              skillId, hitCount)
    local eventType = EFightLuaEvent.Theatre6SpecialHit
    local eventArgs = XEventManager.GetEventArgs(eventType) --[[@as Theatre6HitAffixArgs]]
    -- eventArgs._contextId = contextId
    eventArgs._missileUUID = missileUUID
    eventArgs._missileHitCount = hitCount
    eventArgs._launcherUUID = launcherNpcUUID
    eventArgs._targetUUID = targetNpcUUID
    eventArgs._isActivate = true
    eventArgs._srcType = HitTagSourceType.StaticAtk
    eventArgs._actionId = actionId
    eventArgs._skillId = skillId
    if triggeredTags then eventArgs._triggeredTags = triggeredTags end
    self:DispatchLuaEvent(eventType, eventArgs)
end

function XLevelScript1081:OnMissileDeadEvent(missileUUID)
    local misRecord = self._misHitCountRecord
    if not misRecord[missileUUID] then return end
    -- self:LogError("misRecord " .. missileUUID .. " is cleared, value is " .. misRecord[missileUUID])
    misRecord[missileUUID] = nil
end

--endregion

--region 方法

---状态超时后的兜底推进接口
function XLevelScript1081:ForceContinue()
    --跑到这里说明某个状态维持不变的时长超出预期, 必定是产生了什么问题
    local state = self._stateMachine._curState
    local DebugInfo = state and state.DebugInfo
    self:LogError("XLevelScript1081:ForceContinue is called. CurState is " ..
        tostring(state and state.Name) .. ", debugInfo: \n " .. tostring(DebugInfo and DebugInfo(state)))
    return self:OnControlCenter()
end

function XLevelScript1081:IsMonsterNpc(NpcUUID) --判断是否是怪物类型(3\4\5)的Npc
    local npcType = self._proxy:GetNpcKind(NpcUUID)
    local monsterTypeList = { 3, 4, 5 }         --以后如果要有其他类型的判定不加特效，在这个列表这里补充
    for i, mosnterType in pairs(monsterTypeList) do
        if npcType == mosnterType then
            return true
        end
    end
    return false
end

function XLevelScript1081:CheckNpcUUID(npcUUID)
    return npcUUID == self._fighter1UUID or npcUUID == self._fighter2UUID
end

function XLevelScript1081:GetAttacker()
    if self._fighter1UUID == self._currentActionNpcUUID then
        return self._fighter1
    elseif self._fighter2UUID == self._currentActionNpcUUID then
        return self._fighter2
    end
end

function XLevelScript1081:GetDefender()
    if self._fighter1UUID == self._currentActionNpcUUID then
        return self._fighter2
    elseif self._fighter2UUID == self._currentActionNpcUUID then
        return self._fighter1
    end
end

function XLevelScript1081:GetNpcByUUID(uuid)
    if uuid == self._fighter1UUID then
        return self._fighter1
    elseif uuid == self._fighter2UUID then
        return self._fighter2
    else
        self:LogError("GetNpcByUUID Error: Unknown uuid .. " .. tostring(uuid))
    end
end

function XLevelScript1081:GetTempDefender()
    if self._fighter1UUID == self._tempActionNpcUUID then
        return self._fighter2
    elseif self._fighter2UUID == self._tempActionNpcUUID then
        return self._fighter1
    end
end

--- 获取插入式技能队列
function XLevelScript1081:GetInsertSkillQueue(npcUUID)
    if npcUUID == self._fighter1UUID then
        return self._fighter1InsertSkillQueue
    elseif npcUUID == self._fighter2UUID then
        return self._fighter2InsertSkillQueue
    else
        self:LogError("错误的Npc获取Insert队列:" .. npcUUID)
        return nil
    end
end

--- 角色向关卡申请释放插入式技能
function XLevelScript1081:RequestInsertSkill(npcUUID, skillId)
    if not skillId or skillId == 0 then
        return false
    end

    local queue = self:GetInsertSkillQueue(npcUUID)
    if not queue then
        return false
    end

    queue[#queue + 1] = skillId
    return true
end

--- 设置出手方npc
function XLevelScript1081:SetTempActionNpc(npcUUID)
    if npcUUID == self._tempActionNpcUUID then return end
    self._tempActionNpcUUID = npcUUID

    --发送通知
    local eventType = EFightLuaEvent.Theatre6AttakerChange
    local eventArgs = XEventManager.GetEventArgs(eventType) --[[@as Theatre6AttackerChangeEventArgs]]
    eventArgs._isTemp = true
    eventArgs._newAttackerUUID = npcUUID
    eventArgs._newDefenderUUID = self:GetTempDefender():GetUUID()
    self:DispatchLuaEvent(eventType, eventArgs)
end

--- 设置出手权npc
function XLevelScript1081:SetActionNpc(npcUUID)
    if npcUUID == self._currentActionNpcUUID then return end
    self._currentActionNpcUUID = npcUUID
    local npc = self:GetNpcByUUID(npcUUID)
    -- local ux = npc:GetHandSideUx()
    -- self:LogError("updateHandSideUi: " .. tostring(ux))
    -- self._proxy:Theatre6UpdateHandSideUI(npcUUID, npc:GetHandSideUx())

    --发送通知
    local eventType = EFightLuaEvent.Theatre6AttakerChange
    local eventArgs = XEventManager.GetEventArgs(eventType) --[[@as Theatre6AttackerChangeEventArgs]]
    eventArgs._isTemp = false
    eventArgs._newAttackerUUID = npcUUID
    eventArgs._newDefenderUUID = self:GetDefender():GetUUID()
    self:DispatchLuaEvent(eventType, eventArgs)
end

-- --- 当单位的出手权UX发生更改时, 尝试更新出手权UX
-- ---@param npc XTheatre6CharBase
-- function XLevelScript1081:TryUdpateHandSideUx(npc)
--     if npc ~= self:GetAttacker() then return end
--     self._proxy:Theatre6UpdateHandSideUI(npc:GetUUID(), npc:GetHandSideUx())
-- end

--- 检查事实超算值是否已满
function XLevelScript1081:CheckNpcRuntimeOverClockIsMax(npcUUID)
    return self._proxy:Theatre6GetNpcRuntimeOverClock(npcUUID) >= self._castRuntimeOverClock
end

---发送lua事件通知并释放事件参数表
---@param eventType EFightLuaEvent lua事件类型
---@param eventArgs LuaEventArgs lua事件参数表, 需要通过 XEventManager.GetEventArgs() 获取
---@param targetType ELuaEventTarget|nil lua事件通知范围类型, 为空时全域广播
function XLevelScript1081:DispatchLuaEvent(eventType, eventArgs, targetType)
    -- ※※※ 注意这里立刻释放事件参数表的逻辑强依赖于_proxy:DispatchLuaEvent()的时效性,
    -- ※※※ 如果_proxy:DispatchLuaEvent()修改为异步逻辑, 则这里必炸.

    -- if not (eventArgs.IsLuaEventArgs and eventArgs:IsLuaEventArgs()) then
    --     self:LogError("XTheatre6FightBase:DispatchLuaEvent Error: Illegal EventArgs")
    -- end

    targetType = targetType or ELuaEventTarget.All
    self._proxy:DispatchLuaEvent(targetType, eventType, eventArgs)
    XEventManager.ReleaseEvenArgs(eventArgs)
end

--endregion

--region 初始化

---构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
---@param proxy XDlcCSharpFuncs
function XLevelScript1081:Ctor(proxy)
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self.isEndBattle = false
    self._spawnPoint = {}       --获取点位序号，初始化中获取
    self._levelTime = 0         --关卡时间
    self._isSomeoneDead = false --有角色死了，但是需要播UI退场动画，仍未结算，的阶段判断开关。
    self._deadToEndTime = 0.5   --有人死了到结算的延迟时间，目前是UI退场动画需要的时间

    -- self._currentPhase = 0         --当前阶段

    self._currentActionNpcUUID = 0 -- 出手权npc
    self._tempActionNpcUUID = 0    --出手方npc

    self._npcContinueSkillInterval = 0.5
    self._npcContinueSkillIntervalTimer = 0
    self._waitDice = false -- 等待拼点
    self._fighter1InsertSkillQueue = {}
    self._fighter2InsertSkillQueue = {}

    self._stateMachine = XLevelScript1081.StateMachine.New(self) ---@type XLevelScript1081.StateMachine
    self._states = self._stateMachine:GetStates()

    self._tempHitTags = {}
    self._tempTriggerHitTags = {}
    self._misHitCountRecord = {}

    ------------------配置变量------------------
    -- self._startCameraTime = 0        --展示镜头阶段开始时间
    --self._settleTime = 1             --倒计时阶段开始时间
    --self._settleCamera = 1              --倒计时阶段镜头序号
    -- self._battleTime = 5             --战斗阶段开始时间
    -- self._tiredTime = 90     --疲劳机制开启时间
    self._tiredTime = proxy:Theatre6GetConfig():GetInt("WeakenTime")     --疲劳机制开启时间
    self._tiredState = false --疲劳机制是否开启

    -- self._wrestleDiceTime = 2.5      --拼刀拼点等待时间
    -- self._castRuntimeOverClock = 100 --超算值消耗
    self._castRuntimeOverClock = proxy:Theatre6GetConfig():GetInt("CSCost") --超算值消耗
    -- self._overclockDiceTime = 2.5    --超算拼点等待时间

    ----------------------------调试用的逻辑--------------------------------------

    -- self._fighter1SkillComboCaster = nil
    -- self._fighter2SkillComboCaster = nil
end

function XLevelScript1081:Init()
    self._name = self.__cname .. "." .. self._proxy:GetCurrentLevelId()
    self:RegisterEvents()
    --初始化逻辑
    -- 玩家的初始化, 正式应该由Gameplay的程序初始化处理, 此处为临时方案
    --self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId() --玩家ID
    ----------------地图初始化----------------------------------------------------------------------
    self._levelId = self._proxy:GetCurrentLevelId()  -- 关卡ID,获取本关ID
    for i = 1, 5 do
        self._spawnPoint[i] = self._proxy:GetSpot(i) --获取关卡编辑器中配置好的点，1是战场中心点，2是玩家1(本机)，3是玩家2, 4是拼刀点1，5是拼刀点2
    end
    ----------------Npc基础配置-------------------------------------------------------------------------- -------------

    --Fighter1配置
    local fighter1NpcId = 1010
    local fighter1Camp = ENpcCampType.Camp1
    local fighter1BornRota = { x = 0, y = -180, z = 0 }
    --Fighter2配置
    local fighter2NpcId = 1010
    local fighter2Camp = ENpcCampType.Camp2
    local fighter2BornRota = { x = 0, y = -90, z = 0 }
    --空NPC配置
    local commonNpcId = 1050 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornRota = { x = 0, y = 90, z = 0 }
    --空NPC配置
    -- local robotNpcId = 1016
    -- local robotCamp = ENpcCampType.Camp1
    -- local robotBornRota = { x = 0, y = 0, z = 0 }

    local uuid1 = self._proxy:Theatre6GetNpc(true)
    local uuid2 = self._proxy:Theatre6GetNpc(false)
    self._fighter1 = self._proxy:GetActorScriptObject(EScriptType.Npc, uuid1, self._proxy:GetNpcTemplate(uuid1).ScriptId) --[[@as XTheatre6CharBase]]
    self._fighter2 = self._proxy:GetActorScriptObject(EScriptType.Npc, uuid2, self._proxy:GetNpcTemplate(uuid2).ScriptId) --[[@as XTheatre6CharBase]]

    self._fighter1:OnEnterLevel(self._levelId)
    self._fighter2:OnEnterLevel(self._levelId)
    -- self._fighter1:PostInit()
    -- self._fighter2:PostInit()
    --拼刀镜头注册
    -- self._Pindao_Start_camera = 10250110
    self._Pindao_Start_camera = 10250101
    -- self._Pindao_Start_2L_camera = 10250102
    -- self._Pindao_Start_2R_camera = 10250103
    self._Pindao_Start_3_camera = 10250104
    self._delPindao_Start_3_camera = 10250105
    self._OpenCamera = 1025011
    self._DeleteOpenCamera = 1025012
    self._isFirstWrestle = true


    -----------------创建Npc1--------------------------------------------------------------------------------------------
    self._fighter1UUID = uuid1

    if self._fighter1UUID == 0 then
        self._fighter1UUID = self._proxy:GenerateNpc(fighter1NpcId, fighter1Camp, self._spawnPoint[2], fighter1BornRota)
        self._proxy:SetAutoChessNpcUi(self._fighter1UUID, true)             -- Debug暂时给绑定角色血量
    else
        self._proxy:SetNpcPosition(self._fighter1UUID, self._spawnPoint[2]) --传送玩家1位置
    end
    -- self._proxy:SetNpcFaceToPosition(self._fighter1UUID, self._spawnPoint[3]) --设置看向2的位置
    -----------------创建Npc2--------------------------------------------------------------------------------------------
    self._fighter2UUID = uuid2

    if self._fighter2UUID == 0 then
        self._fighter2UUID = self._proxy:GenerateNpc(fighter2NpcId, fighter2Camp, self._spawnPoint[3], fighter2BornRota)
        self._proxy:SetAutoChessNpcUi(self._fighter2UUID, false)            -- Debug暂时给绑定角色血量
    else
        self._proxy:SetNpcPosition(self._fighter2UUID, self._spawnPoint[3]) --传送玩家2位置
    end
    -- self._proxy:SetNpcFaceToPosition(self._fighter2UUID, self._spawnPoint[2])      --设置看向1的位置

    if not self:IsMonsterNpc(self._fighter2UUID) then                              --判断是否非怪物类型,人形怪需要上一个红皮特效buff，怪物类型则不需要
        self._proxy:ApplyMagic(self._fighter2UUID, self._fighter2UUID, 1015990, 1) --敌人红皮特效buff，用于区分敌我角色
    end

    -- self._fighter1SkillComboCaster = XTheatre6SkillComboCaster.New(self, self._fighter1UUID, self._fighter2UUID)
    -- self._fighter2SkillComboCaster = XTheatre6SkillComboCaster.New(self, self._fighter2UUID, self._fighter1UUID)

    -----------------创建空NPC-------------------------------------------------------------------------------------------
    self._robotUUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, self._spawnPoint[1], commonNpcBornRota) --空NPCUUID赋值，生成机器人
    XLog.Warning("生成了空NPC" .. self._robotUUID)
    -- self._proxy:SetNpcActive(self._robotUUID, false)                                           --设置隐藏空NPC
    -- self._proxy:ApplyMagic(self._robotUUID, self._robotUUID, 1010028, 1)                                 --关闭AI

    ----------Level配置-------------------------------------------------------------------------------------------
    self._proxy:SetLevelMemoryInt(4001, 1) --设置游戏开始的局

    -----------------激活虚拟相机--------------------------------------------------------------------------------------------
    if self._levelId == 1081 then
        self._proxy:ActivateVCam(self._fighter1UUID, "DlcAutoChess", 0, 0.5, 0, 31.83, 0.829, 86.62, -5.43, 44.14, 0, 0,
            0,
            101, false) --1081关的镜头
    elseif self._levelId == 1082 then
        self._proxy:ActivateVCam(self._fighter1UUID, "DlcAutoChess", 0, 5, 0, 100.038, 27.1, 100.066, -6, 0, 0, 0, 0,
            101, false) --1082关的镜头
    elseif self._levelId == 1083 then
        self._proxy:ActivateVCam(self._fighter1UUID, "DlcAutoChess", 0, 5, 0, 75, 8.35, 65, -6, 0, 0, 0,
            0,
            101, false) --1083关的镜头
    elseif self._levelId == 1084 then
        self._proxy:ActivateVCam(self._fighter1UUID, "DlcAutoChess", 0, 5, 0, 57, 18.9, 58.50978, -6, 0,
            0, 0, 0,
            101, false)                        --1084关的镜头
    end
    self._proxy:ResetCamera(false, -80, false) --重置相机方向
    XLog.Debug("开场镜头被激活")
    self._proxy:SetCameraOpEnable(false)       --禁止移动镜头
    XLog.Debug("开局禁止滑动镜头")
    ------开局UI管理--------------------------------------------------------------------------------------------------

    ------BGM管理--------------------------------------------------------------------------------------------------
    self._proxy:PlayMusicInOut(6219, -1, -1, -1, -1, 0, 0) --战斗BGM 3首随机

    self:SetState(StateEnum.Start)
end

function XLevelScript1081:RegisterEvents()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)                 --事件注册：npc加buff
    self._proxy:RegisterEvent(EWorldEvent.Theatre6WrestleRollDiceEnd) -- 肉鸽6拼点结束
    self._proxy:RegisterEvent(EWorldEvent.Theatre6DodgeRollDiceEnd)   -- 肉鸽6超算拼点结束

    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)                  -- Npc伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)              -- Npc技能结束

    -- self._proxy:RegisterEvent(EWorldEvent.OnMissileColliderNpc)       -- 子弹碰撞npc
    self._proxy:RegisterEvent(EWorldEvent.MissileHit)  -- 子弹命中npc
    self._proxy:RegisterEvent(EWorldEvent.MissileDead) -- 子弹销毁
end

--endregion

---@param dt number @ delta time
function XLevelScript1081:Update(dt)
    --每帧更新逻辑
    self._levelTime = self._levelTime + dt --记录关卡已进行时间
    self._stateMachine:Update()
    if self._levelTime >= self._tiredTime and self._levelTime <= self._tiredTime + 1 and self._tiredState == false then
        if not self._stateMachine:CheckStateById(StateEnum.Die) and not self._stateMachine:CheckStateById(StateEnum.End) then
            XLog.Debug("疲劳时间到")
            self._tiredState = true                    --进入疲劳阶段
            self._proxy:ShowAutoChessTriedMessageTip() --疲劳播报
            self._proxy:ApplyMagic(self._fighter1UUID, self._fighter1UUID, 1025111, 0, 1)
            self._proxy:ApplyMagic(self._fighter2UUID, self._fighter2UUID, 1025111, 0, 1)
            XLog.Debug("给双方加上了疲劳BUFF")
            self._proxy:PlayStayScreenEffectById(1071001) --屏幕特效
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript1081:HandleEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)

    -- if eventType == EWorldEvent.OnMissileColliderNpc then
    --     self:OnMissileColliderNpc(eventArgs.ContextId, eventArgs.MissileUUID, eventArgs.LauncherNpcUUID,
    --         eventArgs.TargetNpcUUID, eventArgs.Result, eventArgs.Type)

    if eventType == EWorldEvent.MissileHit then
        self:OnMissileHitEvent(eventArgs.MissileUUID, eventArgs.TargetUUID, eventArgs.LauncherUUID)
    elseif eventType == EWorldEvent.MissileDead then
        self:OnMissileDeadEvent(eventArgs.MissileUUID)
    elseif eventType == EWorldEvent.Theatre6WrestleRollDiceEnd then
        self:OnCSWrestleRollDiceEndEvent(eventArgs.WinnerUUID, eventArgs.Diff)
    elseif eventType == EWorldEvent.Theatre6DodgeRollDiceEnd then
        self:OnCSDodgeRollDiceEndEvent(eventArgs.LauncherUUID, eventArgs.WinnerUUID)
    end
end

function XLevelScript1081:LogError(logStr)
    if type(logStr) ~= "string" then
        return XLog.Error("XLevelScript1081:LogError Error: Illegal Log Format")
    end
    return XLog.Error(self._name .. ": " .. logStr)
end

return XLevelScript1081

--region

-- --- Npc一个技能释放轮询事件
-- --- 如果技能没放完则继续连招，如果释放完毕则交给中控选择下一步行为
-- function XLevelScript1081:OnNpcContinueSkill(dt)
--     if self:HasNpcDie() or not self:CheckActionNpcIsValid() or self._waitDice then
--         return
--     end

--     if self._npcContinueSkillIntervalTimer > 0 then
--         self._npcContinueSkillIntervalTimer = self._npcContinueSkillIntervalTimer - dt
--         if self._npcContinueSkillIntervalTimer > 0 then
--             return
--         end

--         self._npcContinueSkillIntervalTimer = 0
--     end

--     if self._proxy:CheckNpcCurActionIsDone(self._currentActionNpcUUID) then
--         self:ResetTimerInterval()

--         if self:CheckIsActionNpc(self._fighter1UUID) then
--             if not self:NpcContinueSkillCombo(self._fighter1UUID) then
--                 self:OnControlCenter()
--             end
--         elseif self:CheckIsActionNpc(self._fighter2UUID) then
--             if not self:NpcContinueSkillCombo(self._fighter2UUID) then
--                 self:OnControlCenter()
--             end
--         else
--             self:OnControlCenter()
--         end
--     end
-- end


--- 重置战斗状态
-- function XLevelScript1081:ResetComboCaster()
--     if self._fighter1SkillComboCaster then
--         self._fighter1SkillComboCaster:Reset()
--     end

--     if self._fighter2SkillComboCaster then
--         self._fighter2SkillComboCaster:Reset()
--     end

--     self:SetActionNpc(0)
--     self._npcContinueSkillIntervalTimer = 0
--     self._fighter1InsertSkillQueue = {}
--     self._fighter2InsertSkillQueue = {}
-- end

-- --- 检查是否是出手权npc
-- function XLevelScript1081:CheckIsActionNpc(npcUUID)
--     return self._currentActionNpcUUID == npcUUID
-- end

-- --- 出手权npc为空或无效
-- function XLevelScript1081:CheckActionNpcIsValid()
--     return self._currentActionNpcUUID ~= nil and self._currentActionNpcUUID ~= 0
-- end

-- --- 释放主动技能
-- function XLevelScript1081:CastMainSkill(npcUUID)
--     local caster = self:GetComboCaster(npcUUID)
--     if not caster then
--         return
--     end

--     self:SetActionNpc(npcUUID)
--     if caster:Cast(ETheatre6SkillType.Main) then
--         self:ResetTimerInterval()
--     else
--         self:OnControlCenter()
--     end
-- end

-- --- 插入式技能 不会改变出手权
-- function XLevelScript1081:CastInsertSkill(npcUUID, skillId)
--     return self:RequestInsertSkill(npcUUID, skillId)
-- end

-- --- 发起超算拼刀
-- function XLevelScript1081:StartDodgeRollDice(launcherUUID)
--     self._proxy:Theatre6CastNpcRuntimeOverClock(launcherUUID, self._castRuntimeOverClock) -- 消耗超算值
--     self._proxy:Theatre6StartDodgeRollDice(launcherUUID, self._overclockDiceTime)
--     self._waitDice = true                                                                 -- 等待拼点
-- end

-- ---肉鸽6超算拼点结束事件
-- ---@param launcherUUID number @ 发生事件的NpcUUID
-- ---@param winnerUUID number
-- function XLevelScript1081:OnDodgeRollDiceEndEvent(launcherUUID, winnerUUID)
--     XLog.Warning("超算拼刀结果事件" .. winnerUUID .. "获得了超算胜利")
--     self._waitDice = false
--     if launcherUUID == self._fighter1UUID and winnerUUID == self._fighter1UUID then
--         self:CastDodgeSkill(self._fighter1UUID)
--     elseif launcherUUID == self._fighter2UUID and winnerUUID == self._fighter2UUID then
--         self:CastDodgeSkill(self._fighter2UUID)
--     else
--         self:OnControlCenter() -- 发起者没有获得胜利，无事发生
--     end
-- end

-- --- 释放超算技能
-- function XLevelScript1081:CastDodgeSkill(npcUUID)
--     local caster = self:GetComboCaster(npcUUID)
--     if not caster then
--         return
--     end

--     self:SetActionNpc(npcUUID)
--     if caster:Cast(ETheatre6SkillType.Dodge) then
--         self:ResetTimerInterval()
--     else
--         self:OnControlCenter()
--     end
-- end

-- --- 尝试释放插入式技能
-- function XLevelScript1081:TryCastQueuedInsertSkill(npcUUID)
--     local queue = self:GetInsertSkillQueue(npcUUID)
--     local caster = self:GetComboCaster(npcUUID)
--     if not queue or not caster or #queue <= 0 then
--         return false
--     end

--     local skillId = queue[1]
--     local skillConfig = caster:GetInsertSkillConfig(skillId)
--     if not skillConfig then
--         table.remove(queue, 1)
--         return false
--     end

--     local stamina = self._proxy:GetNpcGameplayAttribValue(npcUUID, ETheatre6AttribType.Stamina)
--     if skillConfig.CostTL > 0 and stamina > 0 then
--         if caster:CastInsert(skillId) then
--             table.remove(queue, 1)
--             self:ResetTimerInterval()
--             return true
--         end
--     end

--     return false
-- end

-- --- 申请继续连招
-- function XLevelScript1081:NpcContinueSkillCombo(npcUUID)
--     local caster = self:GetComboCaster(npcUUID)
--     if not caster then
--         return false
--     end

--     if not caster:CanContinue() then
--         return false
--     end

--     caster:Continue()
--     return true
-- end

-- --- 检查是否有角色死亡
-- function XLevelScript1081:HasNpcDie()
--     return self._fighter1UUID == 0 or self._fighter2UUID == 0
-- end


-- --- 重置技能释放轮询间隔
-- function XLevelScript1081:ResetTimerInterval()
--     self._npcContinueSkillIntervalTimer = self._npcContinueSkillInterval
-- end

--endregion
