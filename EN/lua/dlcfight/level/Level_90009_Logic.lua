--V4.x 千子
local XLevelScript90009 = XDlcScriptManager.RegLevelLogicScript(90009, "XLevelLogicScript90009") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90009:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90009:Init() --初始化逻辑
    --事件注册

    --XLog.Debug("开启挂起啊初始化逻辑")    
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                                       --事件注册：NPC死亡
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)                                   --事件注册：加buff   (eventArgs.NpcUUID,eventArgs.BuffTableId)

    self._localPlayerDeathTimes = 0                                                      -- 初始化本端玩家死亡次数
    self._spawnPoint = {}                                                               --获取点位序号，初始化中获取
    self._isFinishFight = false                                                         --完成战斗的flag
   
    self._levelTime = 0 
    self._isReadyToEnd = false                                                                 --关卡时间初始化
    self._isPlayerWin = false                                                                   --结算结果
    self._hasSettleLevel = false                                                                --是否已经上传过服务器结果了
    self._currentPhase = 0                                                              --当前阶段
    self._lastPhase = 0                                                                  --上一阶段
    self._playerNpcList = {}                                                            --玩家列表

    --拿到玩家列表和关卡编辑器中的所有点位

    for i = 1, 12 do
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点，1为BOSS出生点，2为场地中心，3~5是玩家出生点,67是左右触手，8~12是其余触手
    end
    self._delayToEnd = 5                --延迟退出时间
    self._levelEndTime = 99999               --临时记录游戏结束的时间(初始化一个超级大的时间)
     --初始化怪物配置
    local monsterId = 8053   --千子本体
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = self._spawnPoint[1]
    local monsterBornRota = {x = 0, y = 180, z = 0}

    local BossSummonLeftId = 8054   --左触手
    local BossSummonLeftIdBornPoint = self._spawnPoint[6]
    local BossSummonRightId = 8055   --右触手
    local BossSummonRightIdBornPoint = self._spawnPoint[7]

    -- 初始化公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = self._spawnPoint[1]
    local commonNpcBornRota = {x = 0, y = 180, z = 0}

    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, monsterBornPos, monsterBornRota)
    self._proxy:SetNpcFaceToPosition(self.monster_UUID,self._spawnPoint[3])                --BOSS看向玩家1的位置
    self.BossSummon01Id = self._proxy:GenerateNpc(BossSummonLeftId, monsterCamp, BossSummonLeftIdBornPoint, monsterBornRota)
    self._proxy:SetNpcFaceToPosition(self.BossSummon01Id,self._spawnPoint[3])                --触手看向玩家1的位置
    self.BossSummon02Id = self._proxy:GenerateNpc(BossSummonRightId, monsterCamp, BossSummonRightIdBornPoint, monsterBornRota)
    self._proxy:SetNpcFaceToPosition(self.BossSummon02Id,self._spawnPoint[3])                --触手看向玩家1的位置

    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRota)
    self._proxy:SetTeamWorkSkillActive(true,300,5)
    self.playerDeadCountList = {}
    XLog.Debug("开启团队协作系统")

    ------------初始化配置----------------------------------------------------------------------------------------
    --ID都是从DLC关卡编辑器里复制过来的，***不要轻易改动***

    self.ColliderGroup = {
        XZM = 1,                 --静态行走面没法控制的
        Floor1 = 2,              --区域1地板，下同
        Floor2 = 3,
        Floor3 = 4,
        Floor4 = 5,
        Floor5 = 6,
        AirWall = 7,            --静态空气墙，最外围那圈
        AirWall1 = 8,           --区域1塌陷后要激活的墙体，下同
        AirWall2 = 9,
        AirWall3 = 10,
        AirWall4 = 11,
        AirWall5 = 12,
        Floor6 = 13,
        AirWall6 = 14,
        AirWall7 = 15           --区域中间的隔板空气墙，激活的时候一个一个激活
    }                         
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall1,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall2,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall3,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall4,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall5,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall6,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.AirWall7,false)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.Floor1,true)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.Floor2,true)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.Floor3,true)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.Floor4,true)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.Floor5,true)
    self._proxy:SetObstacleGroupActive(self.ColliderGroup.Floor6,true)

    XLog.Debug("初始化完毕")
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
function XLevelScript90009:Update(dt) --每帧更新逻辑
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    self:OnUpdatePhase(dt)
end
function XLevelScript90009:InitPhase()
    --初始化关卡各个阶段的相关变量
end
---@param phase number
function XLevelScript90009:SetPhase(phase)    --跳转关卡阶段

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
    if phase == Phase.Show then                                                         --一开始默认在Start，所以只有Show阶段开始才会有Enter流程
        XLog.Debug("进入Show阶段")
        self:SetObstacleListActive(false)
       --self._proxy:CastAction(self.monster_UUID,10086)                                --释放BOSS入场动画 
        
    elseif phase == Phase.Battle then
        XLog.Debug("进入Battle阶段")
        --self._proxy:SetUiActive(UIObjectID,false)                                                                 --UI显示

    elseif phase == Phase.WinDelay then
        XLog.Debug("进入胜利过场阶段")
        self._levelEndTime = self._levelTime
    elseif phase == Phase.LosedDelay then
        XLog.Debug("进入失败过场阶段")
        self._levelEndTime = self._levelTime
    elseif phase == Phase.End then
        XLog.Debug("进入结束关卡阶段")

    end
end

---@param dt number @ delta time
function XLevelScript90009:OnUpdatePhase(dt)
    --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == Phase.Start then                                                               
    --     if #self._playerNpcList == 1 then                                                                --判断是否是单人进入，用完结列表长度进行判断
    --         if not self._proxy:CheckBuffByKind(self._playerNpcList[1],1000480) then
    --             self._proxy:ApplyMagic(self._playerNpcList[1],1000480)                             --给唯一的玩家上一个单人模式的复活buff
    --         end
    --    end
        self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表

        -----------------传送玩家位置--------------------------------------------------------------------------------------------
        for i=1, 3 do
            if self._proxy:CheckNpc(self._playerNpcList[i]) then
                self._proxy:SetNpcPosition(self._playerNpcList[i], self._spawnPoint[i+2])                 --传送玩家1位置
                self._proxy:SetNpcFaceToPosition(self._playerNpcList[i],self._spawnPoint[1])                  --设置看向BOSS的位置
                XLog.Debug("重置玩家位置")
            end
        end

        self:SetPhase(Phase.Show)
    elseif self._currentPhase == Phase.Show then   
         --if not self._proxy:CheckNpcCurrentAction(self.monster_UUID,skillactionID) then                              --判断BOSS的开局表演是否已经结束
             self:SetPhase(Phase.Battle)                                                                             --跳转到战斗阶段
         --end
    elseif self._currentPhase == Phase.Battle then
        self:CheckLevelEnd()                                                        --检测关卡结束
        if self._isFinishFight then                                                 --是否已经完成战斗的判断
            if self._isPlayerWin then
                XLog.Debug("战斗阶段准备进入胜利流程")
                self:SetPhase(Phase.WinDelay)                                       --胜利流程
            elseif self._isPlayerWin == false then
                XLog.Debug("战斗阶段准备进入失败流程")
                self:SetPhase(Phase.LosedDelay)                                     --失败流程
            end                                  
        end
    elseif self._currentPhase == Phase.LosedDelay then                                 --失败流程

        self:SetPhase(Phase.End) 

    elseif self._currentPhase == Phase.WinDelay then                                    --胜利流程
        self:SetPhase(Phase.End) 

    elseif self._currentPhase == Phase.End then
        if (self._levelTime - self._levelEndTime) >= self._delayToEnd then 
            self:LevelEnd(self._isPlayerWin)                                                  --完成关卡流程退出关卡
        end
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
    if (eventType == EWorldEvent.NpcAddBuff) then
        XLog.Debug("有BUFF被添加了, id="..eventArgs.BuffTableId)
        if (eventArgs.BuffTableId ==80560012)  then
            self:SetObstacleListActive(true)
        elseif (eventArgs.BuffTableId ==80560013)  then
            self:SetObstacleListActive(false)
        elseif (eventArgs.BuffTableId ==80560028)  then
            local npcUuidList = self._proxy:GetNpcList()
            for xIndex = 1, #npcUuidList, 1 do
                if self._proxy:CheckBuffByKind(npcUuidList[xIndex], 80560011) then
                    self.monster_UUID = npcUuidList[xIndex]
                    XLog.Warning("结算目标"..self.monster_UUID)
                end
            end
        end
    end
end

function XLevelScript90009:CheckAllPlayerDead() --检查是否所有玩家都死亡了
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    --XLog.Warning(self._playerNpcList)
    for i = 1,#self._playerNpcList do                                           --还没死完
        if not self._proxy:IsNpcDead(self._playerNpcList[i]) then
                 --任意一个没死，就返回False
            return false
        end
    end
    return true
end

function XLevelScript90009:CheckLevelEnd() --检查关卡结束
    ----胜利结算检测-----------------
    if not self._isFinishFight then
        if self.monster_UUID ~= 0 then
            if self._proxy:CheckNpc(self.monster_UUID) == true or self._proxy:CheckActorExist(self.monster_UUID) == true then
                if self._proxy:IsNpcDead(self.monster_UUID) then
                    self._isPlayerWin = true                             --玩家胜利传参修改
                    self._isFinishFight = true
                    self._proxy:SettleFight(self._isPlayerWin)          --后端结算通知API
                    XLog.Debug("检测到Monster死亡")
                end
            end
            return
        end
        --失败结算检测
        if self:CheckAllPlayerDead() then
            self._isPlayerWin = false                               --玩家失败传参修改
            self._isFinishFight = true
            XLog.Debug("检测到所有玩家死亡")
            self._proxy:SettleFight(self._isPlayerWin)          --后端结算通知API
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

function XLevelScript90009:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

function XLevelScript90009:SetObstacleListActive(value)
    for i = 140, 147 do
        self._proxy:SetObstacleActive(i, value)
    end
    if value then
        XLog.Debug("开启障碍")
    else
        XLog.Debug("关闭障碍")
    end
end

return XLevelScript90009