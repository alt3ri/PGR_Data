---V4.2 小辉辉战斗
local XLevelScript9007 = XDlcScriptManager.RegLevelLogicScript(9007, "XLevelLogicScript9007") --注册脚本类到管理器（逻辑脚本注册
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local XRelinkEventRecord = require("Level/Common/XRelinkEventRecord")
local Timer = require("Level/Common/XTaskScheduler")
local XRelinkLevelAudioPlayer = require("Tools/Audio/XRelinkLevelAudioPlayer")

---@param proxy XDlcCSharpFuncs
function XLevelScript9007:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._timer = Timer.New()
    self._playerNpcContainer = XPlayerNpcContainer.New(proxy)
    self._eventRecord = XRelinkEventRecord.New()
    self._dataRecord = require("Level/Common/XRelinkEventRecord")
    ---@type XRelinkLevelAudioPlayer
    self._audioPlayer = XRelinkLevelAudioPlayer.New(proxy)
end

function XLevelScript9007:Init() --初始化逻辑
    self._eventRecord:Init(self._proxy, "XLevelScript9007")
    --事件注册
    self._audioPlayer:Init(1200)--默认是塞利卡
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                                       --事件注册：NPC死亡
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
    self._proxy:RegisterEvent(EWorldEvent.MasterControllerChanged)              --事件注册：主控端切换 
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)                --事件注册：BUFF移除
    
    self._localPlayerDeathTimes = 0                                                      -- 初始化本端玩家死亡次数
    self._spawnPoint = {}                                                               --获取点位序号，初始化中获取
    self._isFinishFight = false                                                         --完成战斗的flag
    self._levelId = self._proxy:GetCurrentLevelId()                                     --当前关卡ID
    self._levelTime = 0 
    self._isReadyToEnd = false                                                                 --关卡时间初始化
    self._isPlayerWin = false                                                                   --结算结果
    self._hasSettleLevel = false                                                                --是否已经上传过服务器结果了
    self._currentPhase = 0                                                              --当前阶段
    self._lastPhase = 0                                                                  --上一阶段
    self._playerNpcList = {}                                                            --玩家列表
    self.LimitTime = 1170
    self._proxy:SetLevelMemoryInt(40001, 0)                                             --初始化关卡
    self.soloWinPlayerId = 0                                                --初始化一个人胜利条件的玩家id
    --拿到玩家列表和关卡编辑器中的所有点位
    XLog.Debug("玩家列表长度现在是"..#self._playerNpcList)
    for i = 1, 5 do
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点，1为BOSS出生点，2为场地中心，3~5是玩家出生点
    end
    
     --初始化怪物配置
    local monsterId = {
        Level01 = 8060,     --难度1
        Level02 = 8061,     --难度2
        Level03 = 8062,     --难度3
        Level04 = 8063,     --难度4
        Level05 = 8064,      --难度5
        default= 8060
    }   --白龙
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = self._spawnPoint[1]
    local monsterBornRota = {x = 0, y = 180, z = 0}

    -- 初始化公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = self._spawnPoint[1]
    local commonNpcBornRota = {x = 0, y = 180, z = 0}
    
    self._delayToWinTime = 7
    self._delayToLosedTime = 5
    self._levelEndTime = 99999               --临时记录游戏结束的时间(初始化一个超级大的时间)
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self._proxy:SetTeamWorkSkillActive(true,300,5)--团队极限技开启
    if self._levelId == 9007 then                                                              --难度2
        self.monster_UUID = self._proxy:GenerateNpc(monsterId.Level01, monsterCamp, monsterBornPos, monsterBornRota,false)
        self._proxy:SetTeamWorkSkillActive(false,300,5)
    elseif  self._levelId == 9008 then
        self.monster_UUID = self._proxy:GenerateNpc(monsterId.Level02, monsterCamp, monsterBornPos, monsterBornRota,false)
    elseif  self._levelId == 9009 then
        self.monster_UUID = self._proxy:GenerateNpc(monsterId.Level03, monsterCamp, monsterBornPos, monsterBornRota,false)
    elseif  self._levelId == 9010 then
        self.monster_UUID = self._proxy:GenerateNpc(monsterId.Level04, monsterCamp, monsterBornPos, monsterBornRota,false)
    elseif  self._levelId == 9011 then
        self.monster_UUID = self._proxy:GenerateNpc(monsterId.Level05, monsterCamp, monsterBornPos, monsterBornRota,false)
    else
        self.monster_UUID = self._proxy:GenerateNpc(monsterId.default, monsterCamp, monsterBornPos, monsterBornRota,false)
    end
    self._proxy:SetNpcFaceToPosition(self.monster_UUID,self._spawnPoint[3])                --BOSS看向玩家1的位置
    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRota)
    self.playerDeadCountList = {}
    XLog.Debug("开启团队协作系统")
   
    ------------初始化配置----------------------------------------------------------------------------------------
    self._proxy:SetObstacleGroupActive(1,false)--大圈
    self._proxy:SetObstacleGroupActive(2,false)--小圈

    for i=10,17 do
        self._proxy:SetObstacleActive(i,false)
    end
end

--region 关卡阶段管理
local Phase = {
    --关卡流程阶段提前声明
    Start = 0,--关卡开始:游戏内部分需要首先处理的事情，例如屏蔽UI和音乐调整之类的，接近初始化
    Show = 1,--怪物入场动画，
    Battle = 2,--战斗阶段，可以理解为主要游玩的阶段，不单单是战斗，包括一些演出转阶段。同时也是在这里进行判定战斗结算结果。
    LosedStart = 3,--失败流程开始
    LosedDelay = 4,--失败流程延迟时间段，用于做角色死亡表现
    LosedDialog = 5,--失败流程弹窗
    WinStart = 6,--胜利流程开始
    WinMissle = 7,--胜利流程战利品拾取
    WinDelay = 8,--胜利流程倒计时延时
    WinDialog =9,--胜利流程弹窗
    End = 10--完成关卡（可能交给弹窗点击确认完成
}

---@param dt number @ delta time
function XLevelScript9007:Update(dt) --每帧更新逻辑
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    self._audioPlayer:Update(dt)
    self:OnUpdatePhase(dt)
end



function XLevelScript9007:InitPhase()
    --初始化关卡各个阶段的相关变量
end
---@param phase number
function XLevelScript9007:SetPhase(phase)    --跳转关卡阶段
    
    if phase == self._currentPhase then
        return
    end
    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end
function XLevelScript9007:OnEnterPhase(phase)
    --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == Phase.Show then    
         --一开始默认在Start，所以只有Show阶段开始才会有Enter流程
        XLog.Debug("进入Show阶段")
        self.timeToBattle = false 
        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false}) 
        self._proxy:SetLevelMemoryInt(50001, self.monster_UUID)       --传给present               --通知BOSS开始播入场动画
        self._proxy:SetLevelMemoryInt(40001, 1)
    elseif phase == Phase.Battle then
        XLog.Debug("进入Battle阶段")
        self._proxy:SetLevelMemoryInt(40001, 2)
        self._timer:Schedule(1, self, function()
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true}) 
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
        for i = 1,#self._playerNpcList do           
            if self._proxy:IsNpcDead(self._playerNpcList[i]) then
                self._proxy:ApplyMagic(self._playerNpcList[i],self._playerNpcList[i],8060042,1)    --临时复活buff
            end 
        end
        self._timer:Schedule(1.8, self, function()
            self._WinStartFlag = true
        end)
    elseif phase == Phase.WinMissle then
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
function XLevelScript9007:OnUpdatePhase(dt)
    --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == Phase.Start then  

        self._playerNpcContainer:Init()         --从系统层获取playerNpcList
        self:InitialPlayerSet()                 -- 从playerNpcContainer获取:self._playerNpcList
        if #self._playerNpcList == 1 then                                                                --判断是否是单人进入，用完结列表长度进行判断
            if not self._proxy:CheckBuffByKind(self._playerNpcList[1],1000495) then
                XLog.Debug("一个人?给你上个buff")
                self._proxy:ApplyMagic(self._playerNpcList[1],self._playerNpcList[1],1000495)
                self._proxy:ApplyMagic(self._playerNpcList[1],self._playerNpcList[1],1000516)
            end
        end
 -----------------传送玩家位置--------------------------------------------------------------------------------------------
        for i, _ in ipairs(self._playerNpcList) do
            if self._proxy:CheckNpc(self._playerNpcList[i]) then
                self._proxy:SetNpcPosition(self._playerNpcList[i], self._spawnPoint[i+2])                 --传送玩家1位置
                self._proxy:SetNpcFaceToPosition(self._playerNpcList[i],self._spawnPoint[1])                  --设置看向BOSS的位置
            end
        end
        self:SetPhase(Phase.Show)  
    elseif self._currentPhase == Phase.Show then   
        if self.timeToBattle == false  then 
            self.timeToBattle = true
            self._timer:Schedule(6.7, self, function()                --6.65秒后切阶段打开小辉辉AI
                self:SetPhase(Phase.Battle)                        --跳转到战斗阶段
            end)
        end
    elseif self._currentPhase == Phase.Battle then
        ------超时判负---------------
        if self._levelTime >= (self.LimitTime) then        
            XLog.Debug("战斗超时，判负处理")
            self._isPlayerWin = false
            self._isFinishFight = true
            self:SetMonsterHasLostLife(self.monster_UUID) --怪物剩余血量获取传值
            self._proxy:SetLevelMemoryInt(133027,0)  --是否胜利黑板值传值
            self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,9001022)--BOSS锁血
            self._audioPlayer:PlayAudioFightLose()
            self._eventRecord:SetResultData(self._proxy)
            self._proxy:SettleFight(self._isPlayerWin)          --后端结算通知API
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
            self:SetPhase(Phase.LosedStart)                                     --失败流程
        elseif self._levelTime >= (self.LimitTime - 11) then 
            self._proxy:SetLevelMemoryInt(60001,math.floor(self._levelTime))
            self._proxy:SetLevelMemoryInt(40001,200)
        end
        ------正常胜负判断---------------
        self:CheckLevelEnd()                                                        --检测关卡结束
        if self._isFinishFight then                                                 --是否已经完成战斗的判断
            if self._isPlayerWin then
                XLog.Debug("战斗阶段准备进入胜利流程")
                self:SetPhase(Phase.WinStart)                                       --胜利流程
            elseif self._isPlayerWin == false then
                XLog.Debug("战斗阶段准备进入失败流程")
                self:SetPhase(Phase.LosedStart)                                     --失败流程
            end                                  
        end
    elseif self._currentPhase == Phase.LosedStart then
        if self._LosedStartFlag then 
            self:SetPhase(Phase.LosedDelay)
        end
    elseif self._currentPhase == Phase.LosedDelay then                                 --失败流程
        if (self._levelTime - self._levelEndTime) >= self._delayToLosedTime then
            self:SetPhase(Phase.End) 
        end
    elseif self._currentPhase == Phase.WinStart then
        if self._WinStartFlag then 
            self:SetPhase(Phase.WinMissle)
        end
    elseif self._currentPhase == Phase.WinMissle then
        self:SetPhase(Phase.WinDelay)
    elseif self._currentPhase == Phase.WinDelay then                                    --胜利流程
        if (self._levelTime - self._levelEndTime) >= self._delayToWinTime then
            self:SetPhase(Phase.End) 
        end
    elseif self._currentPhase == Phase.End then
        self:LevelEnd(self._isPlayerWin)                                                  --完成关卡流程退出关卡
    end
end
function XLevelScript9007:OnExitPhase(phase)
    --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段

end
function XLevelScript9007:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end
function XLevelScript9007:HandlePhaseEvent(eventType, eventArgs)
    --处理阶段相关的事件响应，一般在这里跳转关卡阶段

end

---@param eventType number
---@param eventArgs userdata 
function XLevelScript9007:HandleEvent(eventType, eventArgs) --事件响应逻辑
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    self._eventRecord:HandleEvent(eventType, eventArgs)
    self._audioPlayer:HandleEvent(eventType,eventArgs)
    if eventType == EWorldEvent.EnterLevel then 
        self._playerNpcContainer:Init(function(npc, index)
            self:InitialPlayerSet(npc, index)
        end)
    elseif eventType == EWorldEvent.MasterControllerChanged then 
        self._proxy:ShowTip(90201,5)
        self._timer:Schedule(4, self, function()        
            self._proxy:CloseTip(90201)
        end)
     end
end
function XLevelScript9007:CheckPlayerRebornChance(uuid) --检查NPC是否有复活甲，包括单人复活机会和局外装备复活次数
    if self._proxy:CheckBuffByKind(uuid,1000495) or self._proxy:CheckBuffByKind(uuid,1000516) or
    self._proxy:CheckBuffByKind(uuid,8060029) then --装备的和单人模式的
        return true
    end
    return false 
end
function XLevelScript9007:CheckAllPlayerDead() --检查是否所有玩家都死亡了
    for i = 1,#self._playerNpcList do      --全死且无复活甲且都不在复活中状态
        if not (self._proxy:CheckNpcFullActionState(self._playerNpcList[i],ENpcAction.Reboot,ENpcRebootSubState.WaitReboot) == true and 
            self._proxy:CheckNpcFullActionState(self._playerNpcList[i],ENpcAction.Reboot,ENpcRebootSubState.Rebooting) == false and 
            self:CheckPlayerRebornChance(self._playerNpcList[i]) == false)   then
            return false --如果任意不满足死亡条件就返回false
        end
    end
    return true--死光光
end
function XLevelScript9007:IsSoloWin() --检查是否只有一个玩家存活，其他玩家都倒下时获得胜利
    local alivePlayer = #self._playerNpcList --暂定全员存活
    if #self._playerNpcList == 1 then --单人模式恒为false
        return false 
    else
        for i = 1,#self._playerNpcList do   
            if self._proxy:IsNpcDead(self._playerNpcList[i]) == true and 
                self._proxy:CheckNpcFullActionState(self._playerNpcList[i],ENpcAction.Reboot,ENpcRebootSubState.Rebooting) == false and 
                self:CheckPlayerRebornChance(self._playerNpcList[i]) == false   then
                alivePlayer = alivePlayer - 1 --死了一个
            else
                self.soloWinPlayerId = self._proxy:GetPlayerIdByNpc(self._playerNpcList[i])--记录SOLO胜利玩家的玩家id
            end
        end
        if alivePlayer == 1 then
            return true
        else 
            return false 
        end
    end
end
function XLevelScript9007:CheckLevelEnd() --检查关卡结束
    ----胜利结算检测-----------------
    if not self._isFinishFight then
        if self.monster_UUID ~= 0 then
            if self._proxy:CheckNpc(self.monster_UUID) == true or self._proxy:CheckActorExist(self.monster_UUID) == true then
                if self._proxy:IsNpcDead(self.monster_UUID) then
                    if self:IsSoloWin() == true then
                        self._proxy:SetFightResultCustomData(self.soloWinPlayerId, 9002101,1)
                        XLog.Debug("队友全倒但一人胜利")
                    else
                        self._proxy:SetFightResultCustomData(self.soloWinPlayerId, 9002101,0)
                    end
                    for i = 1,#self._playerNpcList do 
                        self._proxy:ApplyMagic(self._playerNpcList[i],self._playerNpcList[i],9001021)--BOSS死了，全队上无敌BUFF
                    end
                    self._audioPlayer:PlayAudioFightWin()
                    self._isPlayerWin = true                             --玩家胜利传参修改
                    self._isFinishFight = true
                    self._proxy:SetLevelMemoryInt(133027,1)  --是否胜利黑板值传值
                    self._eventRecord:SetResultData(self._proxy)        --传值
                    self._proxy:SettleFight(self._isPlayerWin)          --后端结算通知API
                    XLog.Debug("检测到Monster死亡")
                    return
                end
            end
        end
        --失败结算检测
        if self:CheckAllPlayerDead() then
            self._isPlayerWin = false                               --玩家失败传参修改
            self._isFinishFight = true
            self:SetMonsterHasLostLife(self.monster_UUID)
            self._proxy:SetLevelMemoryInt(133027,0)  --是否胜利黑板值传值
            self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,9001022)--玩家死了BOSS锁血
            XLog.Debug("检测到所有玩家死亡")
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
            self._audioPlayer:PlayAudioFightLose()
            self._eventRecord:SetResultData(self._proxy)--传值
            self._proxy:SettleFight(self._isPlayerWin)          --后端结算通知API
            self._proxy:SetLevelMemoryInt(40001,100)                  --失败关闭所有UI
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
            return
        end
    end
end

function XLevelScript9007:LevelEnd(isPlayerWin)
    if not self._hasSettleLevel then
        self._hasSettleLevel = true
        self.isLeveEnd = true
        self._eventRecord:Destory()
        self._proxy:FinishFight() --仅客户端完成战斗
    end
    
end
function XLevelScript9007:SetMonsterHasLostLife(monsterId)--传值怪物损失百分比血量，用于失败结算给部分经验值
    local _monsterLostLifePersent = 1.0
    _monsterLostLifePersent = 1 - ( self._proxy:GetNpcAttribValue(monsterId,ENpcAttrib.Life)/self._proxy:GetNpcAttribMaxValue(monsterId,ENpcAttrib.Life) )
    _monsterLostLifePersent = math.floor(_monsterLostLifePersent * 100 )
    self._proxy:SetLevelMemoryInt(133026,_monsterLostLifePersent)
    return true
end
function XLevelScript9007:InitialPlayerSet(npc, index)
    -- 防止单机时，在self._playerNpcList未初始化情况下进行访问。
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    for i = 1,#self._playerNpcList do           
        local npcId = self._playerNpcList[i]    --uuid  
        local playerId = self._proxy:GetPlayerIdByNpc(npcId)                        
        self._proxy:SetTeamWorkSkillNpcRemainUseCount(npcId, 1)
        self._eventRecord:AddPlayerNpc(playerId, npcId)
        self.soloWinPlayerId = playerId  --初始化一下solo获胜的玩家
    end
end

function XLevelScript9007:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript9007