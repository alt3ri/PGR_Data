local XLevelScript90005 = XDlcScriptManager.RegLevelLogicScript(90005, "XLevel90005") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90005:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90005:Init() --初始化逻辑
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                                       --事件注册：NPC死亡
    ----------------地图初始化----------------------------------------------------------------------
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID,获取本关ID
    
    
    --变量初始化
    self._localPlayerNpcUUID = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npcUUID
    self._localPlayerDeathTimes = 0                                                      -- 初始化本端玩家死亡次数
    self._levelTime = 0 
    self._levelBeginTime = 3
    self._isReadyToEnd = false                                                                 --关卡时间初始化
    self._isPlayerWin = false
    self._currentPhase = -1                                           --当前阶段
    self._lastPhase = 0                                              --上一阶段
    self._spawnPoint = {}                                            --获取点位序号，初始化中获取
    self._spawnRotation = { 0, 0, 0 }                                --获取点位面向
    self._playerRebornTimes = 3                                      --复活次数
    
    --拿到玩家列表
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    for i = 1, 5 do
        --默认1boss出生点，2场地中心点，345玩家出生点
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点
    end
    -- --创建怪物配置
    local monsterId = 8005   --白龙
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 86, y = 1.9, z = 65}
    local monsterBornRota = {x = 0, y = 180, z = 0}

        -- --创建公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = {x = 86, y = 1.9, z = 65}
    local commonNpcBornRota = {x = 0, y = 180, z = 0}
    
    self.isLeveEnd = false --关卡是否结束
    self._delayToEnd = 5                     --延迟退出时间
    self._levelEndTime = 99999               --临时记录游戏结束的时间
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, monsterBornPos, monsterBornRota)
    ---------------空NPC配置------------------------------------------------------------------------------------------
    local robotNpcId = 1016
    local robotCamp = ENpcCampType.Camp1
    local robotBornRota = { x = 0, y = 0, z = 0 }
    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRota)
    self._proxy:SetTeamWorkSkillActive(true,300,5)
    --XLog.Warning("开启团队协作系统")
    
    
end

--region 关卡阶段管理
local Phase = {
    --暂时分为【0，移动解锁】【1，攻击解锁】【2，闪避解锁】【3，技能解锁】【4，QTE解锁】【5，强力技解锁】【6，OD解锁】【7，狂暴技（支援入场）】【8，Break流程1】【9，必杀/连携必杀】【10，继续Break】【11，最后结束流程】
    Move = 0,
    Attack = 1,
    Dodge = 2,
    Skill = 3,
    QTEGuide = 4,
    SuperSkill = 5,
    ODSikll = 6,
    BerserkSkill = 7,
    Break_1 = 8,
    Hisastu = 9,
    Break_2 = 10,
    Final = 11
}

---@param dt number @ delta time
function XLevelScript90005:Update(dt) --每帧更新逻辑
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    if  self.isLeveEnd then                     --判断关卡是否已经结束
        return
    end
    self:LevelEnd(self._isPlayerWin)
    self:OnUpdatePhase(dt)
end

function XLevelScript90005:InitPhase()
    --初始化关卡各个阶段的相关变量
end
---@param phase number
function XLevelScript90005:SetPhase(phase)
    --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end
    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end
function XLevelScript90005:OnEnterPhase(phase)
    --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == Phase.Move then
        self._proxy:ShowGuide(9000502)                      --测试提示
    elseif phase == Phase.Attack then
       
    elseif phase == Phase.Dodge then
       
    elseif phase == Phase.Skill then
        
    elseif phase == Phase.QTEGuide then

    elseif phase == Phase.SuperSkill then

    elseif phase == Phase.ODSikll then

    elseif phase == Phase.BerserkSkill then

    elseif phase == Phase.Break_1 then

    elseif phase == Phase.Hisastu then

    elseif phase == Phase.Break_2 then

    elseif phase == Phase.Final then

    end
end

---@param dt number @ delta time
function XLevelScript90005:OnUpdatePhase(dt)
    --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == -1 then
        if self._levelTime >= self._levelBeginTime then
            self:SetPhase(Phase.Move)                       --开始移动教学
            
        end
    elseif self._currentPhase == Phase.Move then   

    elseif self._currentPhase == Phase.Attack then

    end
end
function XLevelScript90005:OnExitPhase(phase)
    --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段

end
function XLevelScript90005:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end
function XLevelScript90005:HandlePhaseEvent(eventType, eventArgs)
    --处理阶段相关的事件响应，一般在这里跳转关卡阶段

end
function XLevelScript90005:CheckFightEnd()
   
end
---@param eventType number
---@param eventArgs userdata
function XLevelScript90005:HandleEvent(eventType, eventArgs) --事件响应逻辑
    if eventType == EWorldEvent.NpcDie then 
        self:CheckLevelEnd()
        ----失败结算检测-----------------
        if self:CheckAllPlayerDead() then
            if self._isReadyToEnd ~= true then                      
                self._levelEndTime = self._levelTime                --死完了，确定游戏结算时间
                self._isReadyToEnd = true
            end
            self._isPlayerWin = false                               --玩家失败传参修改
        end    
    end
end

function XLevelScript90005:CheckAllPlayerDead() --检查是否所有玩家都死亡了
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    for i = 1,#self._playerNpcList do                                           --还没死完
        if not self._proxy:CheckBuffByKind(self._playerNpcList[i],1000480) then --不存在buff也不算死亡
            return false
        end
        if self._proxy:GetBuffStacks(self._playerNpcList[i],1000480)<=self._playerRebornTimes then
            return false
        end    
    end
    return true
end

function XLevelScript90005:CheckLevelEnd() --检查关卡结束
    ----胜利结算检测-----------------
    if self.monster_UUID ~= 0 then
        if self._proxy:CheckNpc(self.monster_UUID) == false or self._proxy:CheckActorExist(self.monster_UUID) == false then
            if self._isReadyToEnd ~= true then 
                self._levelEndTime = self._levelTime
                self._isReadyToEnd = true
            end
            self._isPlayerWin = true            --玩家胜利传参修改
            return
        end
    end
end

function XLevelScript90005:LevelEnd(isPlayerWin)
--延时结算流程
    if self._levelTime - self._delayToEnd >= self._levelEndTime then
        self.isLeveEnd = true
        self._proxy:FinishFight() --仅客户端完成战斗
        self._proxy:SettleFight(isPlayerWin)  --后端结算通知API
    end
end

function XLevelScript90005:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript90005