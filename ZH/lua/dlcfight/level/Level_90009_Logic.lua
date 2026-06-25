--V4.x 千子
---@class XLevelScript90009_Logic
local XLevelScript90009 = XDlcScriptManager.RegLevelLogicScript(90009, "XLevelLogicScript90009") --注册脚本类到管理器（逻辑脚本注册
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local XRelinkEventRecord = require("Level/Common/XRelinkEventRecord")
local Timer = require("Level/Common/XTaskScheduler")
local XRelinkLevelAudioPlayer = require("Tools/Audio/XRelinkLevelAudioPlayer")


---@param proxy XDlcCSharpFuncs
function XLevelScript90009:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy                --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._timer = Timer.New()
    self._playerNpcContainer = XPlayerNpcContainer.New(proxy)
    self._eventRecord = XRelinkEventRecord.New()
    self._dataRecord = require("Level/Common/XRelinkEventRecord")
    ---@type XRelinkLevelAudioPlayer
    self._audioPlayer = XRelinkLevelAudioPlayer.New(proxy)
end

function XLevelScript90009:Init() --初始化逻辑
    self._eventRecord:Init(self._proxy, "XLevelScript9002")
    --事件注册
    self._audioPlayer:Init(1200)                                   --默认是塞利卡
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                  --事件注册：NPC死亡
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
    self._proxy:RegisterEvent(EWorldEvent.MasterControllerChanged) --事件注册：主控端切换
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)           --事件注册：BUFF移除
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)              --事件注册：BUFF添加

    self._localPlayerDeathTimes = 0                                -- 初始化本端玩家死亡次数
    self._spawnPoint = {}                                          --获取点位序号，初始化中获取
    self._isFinishFight = false                                    --完成战斗的flag
    self._levelId = self._proxy:GetCurrentLevelId()                --当前关卡ID
    self._levelTime = 0
    self._isReadyToEnd = false                                     --关卡时间初始化
    self._isPlayerWin = false                                      --结算结果
    self._hasSettleLevel = false                                   --是否已经上传过服务器结果了
    self._currentPhase = 0                                         --当前阶段
    self._lastPhase = 0                                            --上一阶段
    self._playerNpcList = {}                                       --玩家列表
    self.LimitTime = 1170
    self._proxy:SetLevelMemoryInt(40001, 0)                        --初始化关卡
    self.soloWinPlayerId = 0                                       --初始化一个人胜利条件的玩家id

    self._delayToWinTime = 7
    self._delayToLosedTime = 3
    self._levelEndTime = 99999 --临时记录游戏结束的时间(初始化一个超级大的时间)

    --拿到玩家列表和关卡编辑器中的所有点位

    for i = 1, 12 do
        self._spawnPoint[i] = self._proxy:GetSpot(i) --获取关卡编辑器中配置好的点，1为BOSS出生点，2为场地中心，3~5是玩家出生点,67是左右触手，8~12是其余触手
    end
    --BOSS相关ID
    local bossIdGroup = --全难度兽形千子ID
    {
        [1] = 8053,
        [2] = 8074,
        [3] = 8083,
        [4] = 8092,
        [5] = 8101,
        [6] = 8111 --木桩BOSS
    }
    local bossId = 0
    local monsterCamp = ENpcCampType.Camp2
    local monsterBornPos = self._spawnPoint[1]
    local monsterBornRot = { x = 0, y = 180, z = 0 }

    local BossSummonLeftId = 8054  --左触手
    local BossSummonLeftIdBornPoint = self._spawnPoint[6]
    local BossSummonRightId = 8055 --右触手
    local BossSummonRightIdBornPoint = self._spawnPoint[7]


    -- 初始化公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = self._spawnPoint[1]
    local commonNpcBornRot = { x = 0, y = 180, z = 0 }

    -- 获取玩家列表
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表

    -----------------创建怪物--------------------------------------------------------------------------------------------
    if self._levelId == 9013 or self._levelId == 90009 then --根据关卡ID判断生成不同难度的BOSS
        bossId = bossIdGroup[1]
    elseif self._levelId == 9014 then
        bossId = bossIdGroup[2]
    elseif self._levelId == 9015 then
        bossId = bossIdGroup[3]
    elseif self._levelId == 9016 then
        bossId = bossIdGroup[4]
    elseif self._levelId == 9017 then
        bossId = bossIdGroup[5]
    else --木桩BOSSID
        bossId = bossIdGroup[6]
    end
    self._monsterUUID = self._proxy:GenerateNpc(bossId, monsterCamp, monsterBornPos, monsterBornRot) --召唤BOSS
    self._proxy:SetNpcFaceToPosition(self._monsterUUID, self._spawnPoint[3])                         --BOSS看向玩家1的位置
    self.BossSummon01Id = self._proxy:GenerateNpc(BossSummonLeftId, monsterCamp, BossSummonLeftIdBornPoint,
        monsterBornRot)                                                                              --召唤触手1
    self._proxy:SetNpcFaceToPosition(self.BossSummon01Id, self._spawnPoint[3])                       --触手看向玩家1的位置
    self.BossSummon02Id = self._proxy:GenerateNpc(BossSummonRightId, monsterCamp, BossSummonRightIdBornPoint,
        monsterBornRot)                                                                              --召唤触手2
    self._proxy:SetNpcFaceToPosition(self.BossSummon02Id, self._spawnPoint[3])                       --触手看向玩家1的位置
    XLog.Debug("已召唤BOSS")

    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRot)
    self._proxy:SetTeamWorkSkillActive(true, 300, 5)
    self.playerDeadCountList = {}
    XLog.Debug("开启团队协作系统")

    ------------初始化配置----------------------------------------------------------------------------------------
    --ID都是从DLC关卡编辑器里复制过来的，***不要轻易改动***

    self.ColliderGroup = {
        AirWall = 1,   --外圈的静态空气墙，无法开关
        Ground = 2,    --行走面，无法开关
        WaterWall = 3, --BOSS的水墙
        PhaseWall = 4  --摄像机阻挡
    }
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.WaterWall, false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.PhaseWall, true)
    XLog.Debug("初始化完毕")
end

--#region 关卡阶段管理
local Phase = {
    --关卡流程阶段提前声明
    Start = 0,       --关卡开始:游戏内部分需要首先处理的事情，例如屏蔽UI和音乐调整之类的，接近初始化
    Show = 1,        --怪物入场动画，
    Battle = 2,      --战斗阶段，可以理解为主要游玩的阶段，不单单是战斗，包括一些演出转阶段。同时也是在这里进行判定战斗结算结果。
    LosedStart = 3,  --失败流程开始
    LosedDelay = 4,  --失败流程延迟时间段，用于做角色死亡表现
    LosedDialog = 5, --失败流程弹窗
    WinStart = 6,    --胜利流程开始
    WinLoot = 7,     --胜利流程战利品拾取
    WinDelay = 8,    --胜利流程倒计时延时
    WinDialog = 9,   --胜利流程弹窗
    End = 10         --完成关卡（可能交给弹窗点击确认完成
}

---@param dt number @ delta time
function XLevelScript90009:Update(dt)      --每帧更新逻辑
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt --记录关卡已进行时间
    self._audioPlayer:Update(dt)
    self:OnUpdatePhase(dt)
end

function XLevelScript90009:InitPhase()
    --初始化关卡各个阶段的相关变量
end

---@param phase number
function XLevelScript90009:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end
    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScript90009:OnEnterPhase(phase)
    --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == Phase.Show then
        --一开始默认在Start，所以只有Show阶段开始才会有Enter流程
        XLog.Debug("进入Show阶段" .. self._levelTime)
        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc, EFightLuaEvent.RelinkSetAIActivate,
            { NpcUUid = self._monsterUUID, IsActivated = false }) --关闭BOSSAI
        self._timeToBattle = false
        self._proxy:SetLevelMemoryInt(50001, self._monsterUUID)   --通知BOSS开始播入场动画
        self._proxy:SetLevelMemoryInt(40001, 1)                   --传给present，UI控制
    elseif phase == Phase.Battle then
        XLog.Debug("进入Battle阶段")
        self._proxy:SetLevelMemoryInt(40001, 2)
        self._timer:Schedule(1, self, function()
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc, EFightLuaEvent.RelinkSetAIActivate,
                { NpcUUid = self._monsterUUID, IsActivated = true })
        end)
    elseif phase == Phase.LosedStart then
        XLog.Debug("进入LosedStart阶段")
        self._LosedStartFlag = false
        self._timer:Schedule(3, self, function()
            self._LosedStartFlag = true
        end)
    elseif phase == Phase.LosedDelay then
        XLog.Debug("进入失败过场阶段")
        self._levelEndTime = self._levelTime
    elseif phase == Phase.LosedDialog then
        XLog.Debug("进入失败弹窗阶段")
    elseif phase == Phase.WinStart then
        XLog.Debug("进入WinStart阶段")
        self._WinStartFlag = false
        for i = 1, #self._playerNpcList do
            if self._proxy:IsNpcDead(self._playerNpcList[i]) and
                self._proxy:CheckNpcFullActionState(self._playerNpcList[i], ENpcAction.Reboot, ENpcRebootSubState.Rebooting) == false then
                self._proxy:ApplyMagic(self._playerNpcList[i], self._playerNpcList[i], 8060042, 1) --复活buff
            end
        end
        self._timer:Schedule(4.16, self, function() --怪物死亡到掉落物品的延时
            self._WinStartFlag = true
        end)
    elseif phase == Phase.WinLoot then
        XLog.Debug("进入WinMissle阶段")
        self._proxy:PlayDropEffect()
        XLog.Debug("开始掉落物品")
        self._proxy:SetLevelMemoryInt(40001, 7)
    elseif phase == Phase.WinDelay then
        XLog.Debug("进入胜利过场阶段")
        self._levelEndTime = self._levelTime
    elseif phase == Phase.WinDialog then
        XLog.Debug("进入胜利弹窗阶段")
    elseif phase == Phase.End then
        XLog.Debug("进入结束关卡阶段")
    end
end

---@param dt number @ delta time
function XLevelScript90009:OnUpdatePhase(dt)
    --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == Phase.Start then
        XLog.Debug("Start阶段更新" .. self._levelTime)
        self._playerNpcContainer:Init()   --从系统层获取playerNpcList
        self:InitialPlayerSet()           -- 从playerNpcContainer获取:self._playerNpcList
        if #self._playerNpcList == 1 then --判断是否是单人进入，用完结列表长度进行判断
            if not self._proxy:CheckBuffByKind(self._playerNpcList[1], 1000495) then
                XLog.Debug("一个人?给你上个buff")
                self._proxy:ApplyMagic(self._playerNpcList[1], self._playerNpcList[1], 1000495)
                self._proxy:ApplyMagic(self._playerNpcList[1], self._playerNpcList[1], 1000516)
            end
        end
        -----------------传送玩家位置--------------------------------------------------------------------------------------------
        for i, _ in ipairs(self._playerNpcList) do
            if self._proxy:CheckNpc(self._playerNpcList[i]) then
                self._proxy:SetNpcPosition(self._playerNpcList[i], self._spawnPoint[i + 2]) --传送玩家1位置
                XLog.Debug("设置玩家出生位置")
            end
        end
        self:SetPhase(Phase.Show)
    elseif self._currentPhase == Phase.Show then
        if self._timeToBattle == true then
            self._timeToBattle = false
            self:SetPhase(Phase.Battle) --跳转到战斗阶段
        end
    elseif self._currentPhase == Phase.Battle then
        ------超时判负---------------
        if self._levelTime >= (self.LimitTime) then
            XLog.Debug("战斗超时，判负处理")
            self._isPlayerWin = false
            self._isFinishFight = true
            self:SetMonsterHasLostLife(self._monsterUUID)                         --怪物剩余血量获取传值
            self._proxy:SetLevelMemoryInt(133027, 0)                              --是否胜利黑板值传值
            self._proxy:ApplyMagic(self._monsterUUID, self._monsterUUID, 9001022) --BOSS锁血
            self._audioPlayer:PlayAudioFightLose()                                --播放失败音效
            self._eventRecord:SetResultData(self._proxy)                          --记录结果数据
            self._proxy:SettleFight(self._isPlayerWin)                            --后端结算通知API
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc, EFightLuaEvent.RelinkSetAIActivate,
                { NpcUUid = self._monsterUUID, IsActivated = false })             --关闭BossAI
            self:SetPhase(Phase.LosedStart)                                       --失败流程
        elseif self._levelTime >= (self.LimitTime - 11) then
            self._proxy:SetLevelMemoryInt(60001, math.floor(self._levelTime))
            self._proxy:SetLevelMemoryInt(40001, 200)
        end
        ------正常胜负判断---------------
        self:CheckLevelEnd()        --检测关卡结束
        if self._isFinishFight then --是否已经完成战斗的判断
            if self._isPlayerWin then
                XLog.Debug("战斗阶段准备进入胜利流程")
                self:SetPhase(Phase.WinDelay) --胜利流程
            elseif self._isPlayerWin == false then
                XLog.Debug("战斗阶段准备进入失败流程")
                self:SetPhase(Phase.LosedDelay) --失败流程
            end
        end
    elseif self._currentPhase == Phase.LosedStart then
        if self._LosedStartFlag then
            self:SetPhase(Phase.LosedDelay)
        end
    elseif self._currentPhase == Phase.LosedDelay then --失败流程
        if (self._levelTime - self._levelEndTime) >= self._delayToLosedTime then
            self:SetPhase(Phase.End)
        end
    elseif self._currentPhase == Phase.WinStart then
        if self._WinStartFlag then
            self:SetPhase(Phase.WinLoot)
        end
    elseif self._currentPhase == Phase.WinLoot then
        self:SetPhase(Phase.WinDelay)
    elseif self._currentPhase == Phase.WinDelay then --胜利流程
        if (self._levelTime - self._levelEndTime) >= self._delayToWinTime then
            self:SetPhase(Phase.End)
        end
    elseif self._currentPhase == Phase.End then
        self:LevelEnd(self._isPlayerWin) --完成关卡流程退出关卡
    end
end

function XLevelScript90009:OnExitPhase(phase)
    --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end

function XLevelScript90009:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScript90009:HandlePhaseEvent(eventType, eventArgs)
    --处理阶段相关的事件响应，一般在这里跳转关卡阶段
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90009:HandleEvent(eventType, eventArgs) --事件响应逻辑
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    self._eventRecord:HandleEvent(eventType, eventArgs)
    self._audioPlayer:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then
        self._playerNpcContainer:Init(function(npc, index)
            self:InitialPlayerSet(npc, index)
        end)
    elseif eventType == EWorldEvent.MasterControllerChanged then
        self._proxy:ShowTip(90201, 5)
        self._timer:Schedule(4, self, function()
            self._proxy:CloseTip(90201)
        end)
    elseif eventType == EWorldEvent.NpcAddBuff then
        if eventArgs.BuffTableId == 80560012 then     --开启水墙magic
            self:SetWaterWallActive(true)
        elseif eventArgs.BuffTableId == 80560013 then --关闭水墙magic
            self:SetWaterWallActive(false)
        elseif eventArgs.BuffTableId == 8053060 then  --BOSS登场结束magic
            self._timeToBattle = true
            XLog.Debug("BOSS登场特写结束")
        elseif eventArgs.BuffTableId == 80560028 then --替换结算BOSS+关闭摄像机空气墙
            self._proxy:SetObstacleGroupActive(self.ColliderGroup.PhaseWall, false)
            local npcUuidList = self._proxy:GetNpcList()
            for i = 1, #npcUuidList, 1 do
                if self._proxy:CheckBuffByKind(npcUuidList[i], 80560011) then
                    self._monsterUUID = npcUuidList[i]
                    XLog.Debug("结算目标" .. self._monsterUUID)
                end
            end
        end
    end
end

function XLevelScript90009:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）
    self._eventRecord:Destory()
end

------自定义函数-------
function XLevelScript90009:CheckPlayerRebornChance(uuid) --检查NPC是否有复活甲，包括单人复活机会和局外装备复活次数
    if self._proxy:CheckBuffByKind(uuid, 1000495) or self._proxy:CheckBuffByKind(uuid, 1000516) or
        self._proxy:CheckBuffByKind(uuid, 8060029) then  --装备的和单人模式的
        return true
    end
    return false
end

function XLevelScript90009:CheckAllPlayerDead() --检查是否所有玩家都在等待复活中了
    for i = 1, #self._playerNpcList do          --全死且无复活甲且都不在复活中状态
        if not (self._proxy:CheckNpcFullActionState(self._playerNpcList[i], ENpcAction.Reboot, ENpcRebootSubState.WaitReboot) == true and
                self._proxy:CheckNpcFullActionState(self._playerNpcList[i], ENpcAction.Reboot, ENpcRebootSubState.Rebooting) == false and
                self:CheckPlayerRebornChance(self._playerNpcList[i]) == false) then
            return false --如果任意不满足死亡条件就返回false
        end
    end
    return true --死光光
end

function XLevelScript90009:IsSoloWin()       --检查是否只有一个玩家存活，其他玩家都倒下时获得胜利
    local alivePlayer = #self._playerNpcList --暂定全员存活
    if #self._playerNpcList == 1 then        --单人模式恒为false
        return false
    else
        for i = 1, #self._playerNpcList do
            if self._proxy:IsNpcDead(self._playerNpcList[i]) == true and
                self._proxy:CheckNpcFullActionState(self._playerNpcList[i], ENpcAction.Reboot, ENpcRebootSubState.Rebooting) == false and
                self:CheckPlayerRebornChance(self._playerNpcList[i]) == false then
                alivePlayer = alivePlayer - 1                                               --死了一个
            else
                self.soloWinPlayerId = self._proxy:GetPlayerIdByNpc(self._playerNpcList[i]) --记录SOLO胜利玩家的玩家id
            end
        end
        if alivePlayer == 1 then
            return true
        else
            return false
        end
    end
end

function XLevelScript90009:CheckLevelEnd() --检查关卡结束
    if not self._isFinishFight then
        ----胜利结算检测-----------------
        if self._monsterUUID ~= 0 then
            if self._proxy:CheckNpc(self._monsterUUID) == true or self._proxy:CheckActorExist(self._monsterUUID) == true then --判断BOSS存在
                if self._proxy:IsNpcDead(self._monsterUUID) then
                    if self:IsSoloWin() == true then
                        self._proxy:SetFightResultCustomData(self.soloWinPlayerId, 9002101, 1)
                        XLog.Debug("队友全倒但一人胜利")
                    else
                        self._proxy:SetFightResultCustomData(self.soloWinPlayerId, 9002101, 0)
                    end
                    for i = 1, #self._playerNpcList do
                        self._proxy:ApplyMagic(self._playerNpcList[i], self._playerNpcList[i], 9001021) --BOSS死了，全队上无敌BUFF
                    end
                    self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc, EFightLuaEvent.RelinkSetAIActivate,
                        { NpcUUid = self._monsterUUID, IsActivated = false }) --关闭白龙AI
                    self._audioPlayer:PlayAudioFightWin()
                    self._isPlayerWin = true                                  --玩家胜利传参修改
                    self._isFinishFight = true
                    self._proxy:SetLevelMemoryInt(133027, 1)                  --是否胜利黑板值传值
                    self._eventRecord:SetResultData(self._proxy)              --传值
                    self._proxy:SettleFight(self._isPlayerWin)                --后端结算通知API
                    XLog.Debug("检测到Monster死亡")
                    return
                end
            end
        end
        -----失败结算检测----------
        if self:CheckAllPlayerDead() then
            self._isPlayerWin = false                --玩家失败传参修改
            self._isFinishFight = true
            self._proxy:SetLevelMemoryInt(133027, 0) --是否胜利黑板值传值
            if self._proxy:CheckNpc(self._monsterUUID) == true then
                self:SetMonsterHasLostLife(self._monsterUUID)
                self._proxy:ApplyMagic(self._monsterUUID, self._monsterUUID, 9001022) --玩家死了BOSS锁血
            end
            XLog.Debug("检测到所有玩家死亡")
            self._audioPlayer:PlayAudioFightLose()
            self._eventRecord:SetResultData(self._proxy)              --传值
            self._proxy:SettleFight(self._isPlayerWin)                --后端结算通知API
            self._proxy:SetLevelMemoryInt(40001, 100)                 --失败关闭所有UI
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc, EFightLuaEvent.RelinkSetAIActivate,
                { NpcUUid = self._monsterUUID, IsActivated = false }) --关闭白龙AI
            return
        end
    end
end

function XLevelScript90009:LevelEnd(isPlayerWin)
    if not self._hasSettleLevel then
        self._hasSettleLevel = true
        self.isLeveEnd = true
        self._proxy:FinishFight() --仅客户端完成战斗
    end
end

function XLevelScript90009:SetMonsterHasLostLife(monsterId) --传值怪物损失百分比血量，用于失败结算给部分经验值
    local _monsterLostLifeDeci = 1.0 -
        (self._proxy:GetNpcAttribValue(monsterId, ENpcAttrib.Life) / self._proxy:GetNpcAttribMaxValue(monsterId, ENpcAttrib.Life))
    local _monsterLostLifePersent = math.floor(_monsterLostLifeDeci * 100)
    self._proxy:SetLevelMemoryInt(133026, _monsterLostLifePersent)
    return true
end

function XLevelScript90009:InitialPlayerSet(npc, index)
    -- 防止单机时，在self._playerNpcList未初始化情况下进行访问。
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    for i = 1, #self._playerNpcList do
        local npcId = self._playerNpcList[i] --uuid
        local playerId = self._proxy:GetPlayerIdByNpc(npcId)
        self._proxy:SetTeamWorkSkillNpcRemainUseCount(npcId, 1)
        self._eventRecord:AddPlayerNpc(playerId, npcId)
        self.soloWinPlayerId = playerId --初始化一下solo获胜的玩家
    end
end

function XLevelScript90009:SetWaterWallActive(value)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.WaterWall, value)
    if value then
        XLog.Debug("开启障碍")
    else
        XLog.Debug("关闭障碍")
    end
end

return XLevelScript90009
