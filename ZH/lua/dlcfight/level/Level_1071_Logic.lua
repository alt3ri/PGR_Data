local XLevelScript1071 = XDlcScriptManager.RegLevelLogicScript(1071, "XLevel1071") --注册脚本类到管理器（逻辑脚本注册
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")

---@param proxy XDlcCSharpFuncs
function XLevelScript1071:Ctor(proxy)
    --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self.isEndBattle = false
    self._spawnPoint = {}                                            --获取点位序号，初始化中获取
    self._spawnRotation = { 0, 0, 0 }                                --获取点位面向
    self._levelTime = 0                                              --关卡时间
    self._timeMemory = 0                                             --临时计时用
    self._timePlayerTired = 0                                        --玩家疲劳时间点，默认总是比敌人疲劳时间点多1个dt
    self._timeEnemyTired = 0                                         --敌人疲劳时间点
    self._isSettleTime = false                                       --是否进入了倒计时阶段
    self._isTiredTime = false                                        --是否进入了疲劳阶段
    self._isBattleTime = false                                       --是否进入了战斗阶段
    self._isEnd = false                                              --是否已经结算
    self._isDiedByTired = false                                      --是否有npc因为疲劳伤害而死亡
    self._tiredDamageLevel = 3                                       --疲劳伤害等级（1秒提升1级）
    self._tiredDamageTarget = 2                                      --疲劳目标（1为自己，2为对手，每一轮疲劳优先对手扣血）
    self._settleCamera = 1                                           --倒计时阶段镜头序号
    self._isUiOpen = false                                           --UI是否已经打开
    self._isSomeoneDead = false                                      --有角色死了，但是需要播UI退场动画，仍未结算，的阶段判断开关。
    self._deadToEndTime = 0.5                                          --有人死了到结算的延迟时间，目前是UI退场动画需要的时间

    self._currentPhase = 0                                           --当前阶段
    self._lastPhase = 0                                              --上一阶段

    ------------------配置变量------------------
    self._startCameraTime = 0     --展示镜头阶段开始时间
    self._settleTime = 1    --倒计时阶段开始时间
    self._battleTime = 5    --战斗阶段开始时间
    self._tiredTime = 35     --疲劳阶段开始时间

    self._player1nextTiredDamageTime = self._tiredTime                             --NPC1疲劳扣血的时间
    self._player2nextTiredDamageTime = self._tiredTime                             --NPC1疲劳扣血的时间

    self._tiredArgA = 100      --疲劳攻击力递增参数A      疲劳递增公式为 攻击力=A*int（T/3)^B   其中AB是可调参数，T是疲劳时间
    self._tiredArgB = 2      --疲劳攻击力递增参数B
    self._robotNextAttack = 0    --用于计算机器人下一次攻击力的变量
    self._robotAttack = self._tiredArgA * ((self._tiredDamageLevel/3) ^ self._tiredArgB)    --空白机器人的疲劳攻击力
    ----------------------------调试用的逻辑--------------------------------------
    self.isFightAiOpen = false
    self.isFighter1AiOpen = false
    self.isFighter2AiOpen = false
end

function XLevelScript1071:Init()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)   --事件注册：npc加buff
    --初始化逻辑
    -- 玩家的初始化, 正式应该由Gameplay的程序初始化处理, 此处为临时方案
    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId() --玩家ID    
    ----------------地图初始化----------------------------------------------------------------------
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID,获取本关ID
    for i = 1, 3 do
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点，100001是战场中心点，100002是玩家1(本机)，100003是玩家2
    end
    ----------------Npc基础配置-------------------------------------------------------------------------- -------------

    local sceneCenterPos = { x = 41.46, y = 0.574, z = 48.57 }
    local playerBornPos = { x = 41.74606, y = 0.5454048, z = 56.12916 }

    --Fighter1配置
    local fighter1NpcId = 1010
    local fighter1Camp = ENpcCampType.Camp1
    local fighter1BornRota = { x = 0, y = -90, z = 0 }
    --Fighter2配置
    local fighter2NpcId = 1010
    local fighter2Camp = ENpcCampType.Camp2
    local fighter2BornRota = { x = 0, y = 90, z = 0 }
    --空NPC配置
    local robotNpcId = 1016
    local robotCamp = ENpcCampType.Camp1
    local robotBornRota = { x = 0, y = 0, z = 0 }

    -----------------激活虚拟相机--------------------------------------------------------------------------------------------
    if self._levelId == 1071 then
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 31.83, 0.829, 86.62, -5.43, 44.14, 0, 0, 0, 101, false)                 --1071关的镜头
    elseif self._levelId == 1072 then
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 86.96, 1.882, 76.85, 0.206, 230, 0, 0, 0, 101, false)                 --1072关的镜头
    elseif self._levelId == 1073 then
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 49.53, 1.59, 86, 1.856, 31.62, 0, 0, 0, 101, false)                 --1073关的镜头
    elseif self._levelId == 1074 then
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 219.15, 1.86, 211.8, 10.93, 47.44, 0, 0, 0, 101, false)                 --1074关的镜头
    elseif self._levelId == 1075 then
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 310.9, 29.46, 166.5, 8.18, 223, 0, 0, 0, 101, false)                 --1075关的镜头
    elseif self._levelId == 1076 then
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 60.28, 1.61, 49.40, 0, 216.7, 0, 0, 0, 101, false)                 --1076关的镜头
    else
        self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 41.725, 9.11, 60.74, 44.3, 180, 0, 0, 0, 101, false)                 --默认测试关的镜头
    end 
    self._proxy:ResetCamera(false,-80,false) --重置相机方向
    -----------------创建Npc1--------------------------------------------------------------------------------------------

    self.fighter1UUID = self._proxy:GetAutoChessNpc(true)

    if self.fighter1UUID == 0 then
        self.fighter1UUID = self._proxy:GenerateNpc(fighter1NpcId, fighter1Camp, self._spawnPoint[2], fighter1BornRota)
        self._proxy:SetAutoChessNpcUi(self.fighter1UUID, true) -- Debug暂时给绑定角色血量
    else
        self._proxy:SetNpcPosition(self.fighter1UUID, self._spawnPoint[2])                        --传送玩家1位置
    end
    self._proxy:SetNpcFaceToPosition(self.fighter1UUID, self._spawnPoint[3])                --设置看向2的位置
    -----------------创建Npc2--------------------------------------------------------------------------------------------

    self.fighter2UUID = self._proxy:GetAutoChessNpc(false)
    if self.fighter2UUID == 0 then
        self.fighter2UUID = self._proxy:GenerateNpc(fighter2NpcId, fighter2Camp, self._spawnPoint[3], fighter2BornRota)
        self._proxy:SetAutoChessNpcUi(self.fighter2UUID, false) -- Debug暂时给绑定角色血量
    else
        self._proxy:SetNpcPosition(self.fighter2UUID, self._spawnPoint[3])                         --传送玩家2位置
    end
    self._proxy:SetNpcFaceToPosition(self.fighter2UUID, self._spawnPoint[2])                      --设置看向1的位置

    if  not self:IsMonsterNpc(self.fighter2UUID) then                                                   --判断是否非怪物类型,人形怪需要上一个红皮特效buff，怪物类型则不需要
        self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1015990,1)                           --敌人红皮特效buff，用于区分敌我角色
    end    
    -----------------创建空NPC-------------------------------------------------------------------------------------------
    self._robotUUID = self._proxy:GenerateNpc(1016, robotCamp, self._spawnPoint[1], robotBornRota)           --空NPCUUID赋值，生成机器人
    self._proxy:SetNpcActive(self._robotUUID, false)                                                                   --设置隐藏空NPC
    self._proxy:ApplyMagic(self._robotUUID, self._robotUUID, 1010028, 1)                                              --关闭AI
    ----------Level配置-------------------------------------------------------------------------------------------
    self.FightBeginCountDown = 3      ------游戏开局倒计时
    self.isLevelBegin = false  --关卡开始了
    self.isLevelEnd = false --关卡结束
    self._proxy:SetLevelMemoryInt(4001, 1)  --设置游戏开始的局

    -------LevelState管理-------------------------------------------------------------------------------------------
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)   -- 监听Npc死亡
    ------角色Camera管理--------------------------------------------------------------------------------------------------
    self._proxy:ResetCamera(false,-80,false) --重置相机方向
    ------开局UI管理--------------------------------------------------------------------------------------------------
    self._proxy:SetAutoChessUiActive(false, "FightUiEnable")                             --开局清空UI
    ------BGM管理--------------------------------------------------------------------------------------------------
    self._proxy:PlayMusicInOut(6219,-1,-1,-1,-1,0,0)                                   --战斗BGM 3首随机

end

function XLevelScript1071:IsMonsterNpc(NpcUUID)                          --判断是否是怪物类型(3\4\5)的Npc
    local npcType=self._proxy:GetNpcKind(NpcUUID)
    local monsterTypeList= {3,4,5}                                       --以后如果要有其他类型的判定不加特效，在这个列表这里补充 
    for i , mosnterType in pairs(monsterTypeList)do
        if npcType == mosnterType then
            return true
        end 
    end   
    return false
end

---@param dt number @ delta time
function XLevelScript1071:Update(dt)
    --每帧更新逻辑
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    -----------------------------------调试Ai模块-------------------------------------
    -- if self._proxy:IsKeyDown(ENpcOperationKey.Dodge) then
    --     --同时战斗AI
    --     self.isFighter1AiOpen = true
    --     self.isFighter1AiOpen = true
    --     self.isFightAiOpen = not self.isFightAiOpen
    --     ---@type XLuaEventArgsAutoChessSetAIEnable
    --     local eventArgs = {
    --         Enable = self.isFightAiOpen
    --     }
    --     self._proxy:DispatchLuaEvent(ELuaEventTarget.All, EFightLuaEvent.AutoChessSetAIEnable, eventArgs)
    --     self.isFighter1AiOpen = true
    --     self.isFighter2AiOpen = true
    -- end

    -- if self._proxy:IsKeyDown(ENpcOperationKey.Ball1) then
    --     --设置阵营1的AI
    --     if self.isFighter1AiOpen then
    --         self._proxy:ApplyMagic(self.fighter1UUID, self.fighter1UUID, 1010028, 1)--关闭AI
    --         self.isFighter1AiOpen = false
    --     else
    --         self._proxy:ApplyMagic(self.fighter1UUID, self.fighter1UUID, 1010027, 1)--开启AI
    --         self.isFighter1AiOpen = true
    --     end
    -- end

    -- if self._proxy:IsKeyDown(ENpcOperationKey.Ball2) then
    --     --设置阵营2的AI
    --     if self.isFighter2AiOpen then
    --         self._proxy:ApplyMagic(self.fighter2UUID, self.fighter2UUID, 1010028, 1)--关闭AI
    --         self.isFighter2AiOpen = false
    --     else
    --         self._proxy:ApplyMagic(self.fighter2UUID, self.fighter2UUID, 1010027, 1)--开启AI
    --         self.isFighter2AiOpen = true
    --     end
    -- end
    
    self:CheckFightEnd()
    self:OnUpdatePhase(dt)
end
--region 关卡阶段管理
local Phase = {
    --暂时分为【0，开始瞬间】【1，展示阶段】【2，倒计时阶段】【3，战斗阶段】【4，疲劳阶段】【5，结算阶段（存疑是否写在关卡之中）】
    Start = 0,
    Show = 1,
    Settle = 2,
    Battle = 3,
    Tired = 4,
    End = 5
}
---@param eventType number
---@param eventArgs userdata
function XLevelScript1071:HandleEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcDie then
        self:OnNpcDieEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    elseif (eventType == EWorldEvent.NpcAddBuff) then
        local npc = eventArgs.NpcUUID
        if (eventArgs.BuffTableId == 1015949 and npc == self.fighter1UUID) and (self._currentPhase == Phase.Battle) then
            self._tiredTime = self._tiredTime  -  2
            XLog.Debug("加速疲劳")
        end
    end
        
end

function XLevelScript1071:Terminate()
    --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）
end



function XLevelScript1071:InitPhase()
    --初始化关卡各个阶段的相关变量
    self._player1nextTiredDamageTime = self._tiredTime
    self._player2nextTiredDamageTime = self._tiredTime
end
---@param phase number
function XLevelScript1071:SetPhase(phase)
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
function XLevelScript1071:OnEnterPhase(phase)
    --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == Phase.Start then
        
    elseif phase == Phase.Show then
        --展示阶段
        self._proxy:AbortAction(self.fighter1UUID, true)                                               --打断出场动作
        self._proxy:SetNpcPosition(self.fighter1UUID, self._spawnPoint[2])                            --传送玩家1位置
        self._proxy:SetNpcFaceToPosition(self.fighter1UUID, self._spawnPoint[3])                      --设置看向2的位置

        self._proxy:AbortAction(self.fighter2UUID, true)                                                    --打断出场动作
        self._proxy:SetNpcPosition(self.fighter2UUID, self._spawnPoint[3])                                --传送玩家2位置
        self._proxy:SetNpcFaceToPosition(self.fighter2UUID, self._spawnPoint[2])                          --设置看向1的位置

        --疲劳伤害npc攻击力重置
        self._robotAttackTmeple = self._proxy:GetNpcAttribMaxValue(self._robotUUID,ENpcAttrib.Attack)                                                     
        self._proxy:AddNpcAttribAdditive(self._robotUUID,ENpcAttrib.Attack,-self._robotAttackTmeple,0)                                  --归零攻击力
        self._proxy:AddNpcAttribAdditive(self._robotUUID,ENpcAttrib.Attack,self._robotAttack,0)                                        --重置NPC攻击力为初始值
        --宝珠技能加快疲劳时间，开始疲劳设置为20
        if self._proxy:CheckBuffByKind(self._playerNpcUUID,1015696) == true then           --判断玩家身上是否有这个宝珠效果buff
            self._tiredTime = 20 + self._battleTime     --疲劳阶段开始时间（预留出战斗前开始计时的时间）
        end
    elseif phase == Phase.Settle then
        --倒计时阶段，开始通知倒计时逻辑          
        self._proxy:ShowAutoChessCountDownMessageTip(3)                                                                    --倒计时3秒
    elseif phase == Phase.Battle then
        if not self.isFightAiOpen then
            self.isFighter1AiOpen = true
            self.isFighter2AiOpen = true
            self.isFightAiOpen = not self.isFightAiOpen
            local eventArgs = {
                Enable = self.isFightAiOpen
            }
            self._proxy:DispatchLuaEvent(ELuaEventTarget.All, EFightLuaEvent.AutoChessSetAIEnable, eventArgs)
            self.isFighter1AiOpen = true
            self.isFighter2AiOpen = true
            self._proxy:ApplyMagic(self.fighter1UUID,self.fighter1UUID,1015992,1)                                                --NPC1AI开启的BUFF标记
            self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1015992,1)                                                --NPC2AI开启的BUFF标记

            self._proxy:ApplyMagic(self.fighter1UUID,self.fighter1UUID,1015993,1)                                                --用来控制属性提升特效的buff
            self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1015993,1)                                                --用来控制属性提升特效的buff
        end
    elseif phase == Phase.Tired then
        --开始疲劳阶段
        self._isTiredTime = true
        self._proxy:ShowAutoChessTriedMessageTip()                                                                          --疲劳播报
        if self.fighter1UUID ~= 0 then
            self._proxy:ApplyMagic(self.fighter1UUID,self.fighter1UUID,1010029,1)                                                                --NPC1进入疲劳标记
        end
        if self.fighter2UUID ~= 0 then
            self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1010029,1)                                                                --NPC2进入疲劳标记
        end
        self._proxy:PlayStayScreenEffectById(1071001)                      --屏幕特效
    end
end

---@param dt number @ delta time
function XLevelScript1071:OnUpdatePhase(dt)
    --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self.isEndBattle ~= true then                                                      -----游戏结束，就不执行这段流程了
        if self._currentPhase == Phase.Start then
            --关卡开始
            if self._levelTime > self._startCameraTime then
                --够钟去展示阶段了
                self:SetPhase(Phase.Show)    --跳入展示阶段1
            end
            return
        elseif self._currentPhase == Phase.Show then
            --展示阶段
            if self._levelTime > self._settleTime then
                --够钟去倒计时阶段了
                self:SetPhase(Phase.Settle)    --跳入倒计时阶段2
                return
            end
        elseif self._currentPhase == Phase.Settle then
            --倒计时阶段的逻辑
            if self._levelTime > self._battleTime-1 and self._isUiOpen == false then
                self._isUiOpen = true                                       
            end
            if self._levelTime > self._battleTime then
                --够钟去战斗阶段了
                self:SetPhase(Phase.Battle)                              --跳入战斗阶段3
                self._proxy:SetAutoChessUiActive(true,"FightUiEnable")                                  --打开UI
                self._proxy:SetAutoChessTimerTipsActive(true,self._battleTime)                          --打开时间面板
                return
            end
            --1071关的镜头流程
            if self._levelId == 1071 then                                                                                                    
                if self._levelTime >= self._settleTime and self._settleCamera == 1 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 38.8, 2.4, 88, 10, -40, 0, 0, 0, 101, false)           --第一个镜头
                    self._settleCamera = 2
                elseif self._levelTime >= self._settleTime+1 and self._settleCamera == 2 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 38.8, 2.4, 88, 10, 40, 0, 0, 0, 101, false)           --第二个镜头  
                    self._settleCamera = 3
                elseif self._levelTime>= self._settleTime+2 and self._settleCamera == 3 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 1, 0, 38.8, 5, 82, 15, 0, 0, 0, 0, 101, false)           --第三个镜头
                    self._settleCamera = 4           
                elseif self._levelTime>= self._settleTime+3 and self._settleCamera == 4 then                               
                    self._proxy:DeactivateVCam(self._playerNpcUUID, "DlcAutoChess", false, 0)                           --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                    self._settleCamera = 0                                                                               --镜头计数归零
                end
            --1072关的镜头流程
            elseif self._levelId == 1072 then 
                if self._levelTime >= self._settleTime and self._settleCamera == 1 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 80, 3.2, 76, 10, 140, 0, 0, 0, 101, false)           --第一个镜头
                    self._settleCamera = 2
                elseif self._levelTime >= self._settleTime+1 and self._settleCamera == 2 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 80, 3.2, 76, 10, 220, 0, 0, 0, 101, false)           --第二个镜头  
                    self._settleCamera = 3
                elseif self._levelTime>= self._settleTime+2 and self._settleCamera == 3 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 1, 0, 80, 5.8, 82, 15, 180, 0, 0, 0, 101, false)           --第三个镜头
                    self._settleCamera = 4           
                elseif self._levelTime>= self._settleTime+3 and self._settleCamera == 4 then                          
                    self._proxy:DeactivateVCam(self._playerNpcUUID, "DlcAutoChess", false, 0)                           --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                    self._settleCamera = 0                                                                               --镜头计数归零
                end
            --1073关的镜头流程
            elseif self._levelId == 1073 then 
                if self._levelTime >= self._settleTime and self._settleCamera == 1 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 53.43, 2.7, 87, 10, -40, 0, 0, 0, 101, false)           --第一个镜头
                    self._settleCamera = 2
                elseif self._levelTime >= self._settleTime+1 and self._settleCamera == 2 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 53.43, 2.7, 87, 10, 40, 0, 0, 0, 101, false)           --第二个镜头  
                    self._settleCamera = 3
                elseif self._levelTime>= self._settleTime+2 and self._settleCamera == 3 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 53.43, 5.3, 81, 15, 0, 0, 0, 0, 101, false)           --第三个镜头
                    self._settleCamera = 4           
                elseif self._levelTime>= self._settleTime+3 and self._settleCamera == 4 then  
                    self._proxy:DeactivateVCam(self._playerNpcUUID, "DlcAutoChess", false, 0)                           --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                    self._settleCamera = 0                                                                               --镜头计数归零
                end
            --1074关的镜头流程
            elseif self._levelId == 1074 then 
                if self._levelTime >= self._settleTime and self._settleCamera == 1 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 225.13, 2.4, 212, 10, -40, 0, 0, 0, 101, false)           --第一个镜头
                    self._settleCamera = 2
                elseif self._levelTime >= self._settleTime+1 and self._settleCamera == 2 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 225.13, 2.4, 212, 10, 40, 0, 0, 0, 101, false)           --第二个镜头  
                    self._settleCamera = 3
                elseif self._levelTime>= self._settleTime+2 and self._settleCamera == 3 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 225.13, 5, 206, 15, 0, 0, 0, 0, 101, false)           --第三个镜头
                    self._settleCamera = 4           
                elseif self._levelTime>= self._settleTime+3 and self._settleCamera == 4 then  
                    self._proxy:DeactivateVCam(self._playerNpcUUID, "DlcAutoChess", false, 0)                           --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                    self._settleCamera = 0                                                                               --镜头计数归零
                end
            --1075关的镜头流程     
            elseif self._levelId == 1075 then 
                if self._levelTime >= self._settleTime and self._settleCamera == 1 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 305, 29.48, 164.6, 10, 140, 0, 0, 0, 101, false)           --第一个镜头
                    self._settleCamera = 2
                elseif self._levelTime >= self._settleTime+1 and self._settleCamera == 2 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 305, 29.48, 164.6, 10, 220, 0, 0, 0, 101, false)           --第二个镜头  
                    self._settleCamera = 3
                elseif self._levelTime>= self._settleTime+2 and self._settleCamera == 3 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 305, 32.08, 170.6, 15, 180, 0, 0, 0, 101, false)           --第三个镜头
                    self._settleCamera = 4           
                elseif self._levelTime>= self._settleTime+3 and self._settleCamera == 4 then  
                    self._proxy:DeactivateVCam(self._playerNpcUUID, "DlcAutoChess", false, 0)                           --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                    self._settleCamera = 0                                                                               --镜头计数归零
                end 
            --1076关的镜头流程     
            elseif self._levelId == 1076 then 
                if self._levelTime >= self._settleTime and self._settleCamera == 1 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 55, 2.4, 48, 10, 140, 0, 0, 0, 101, false)           --第一个镜头
                    self._settleCamera = 2
                elseif self._levelTime >= self._settleTime+1 and self._settleCamera == 2 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 55, 2.4, 48, 10, 220, 0, 0, 0, 101, false)           --第二个镜头  
                    self._settleCamera = 3
                elseif self._levelTime>= self._settleTime+2 and self._settleCamera == 3 then
                    self._proxy:ActivateVCam(self._playerNpcUUID, "DlcAutoChess", 0, 0.5, 0, 55, 5, 54, 15, 180, 0, 0, 0, 101, false)           --第三个镜头
                    self._settleCamera = 4           
                elseif self._levelTime>= self._settleTime+3 and self._settleCamera == 4 then  
                    self._proxy:DeactivateVCam(self._playerNpcUUID, "DlcAutoChess", false, 0)                           --取消玩家角色虚拟相机，自然过渡到自走棋观战相机
                    self._settleCamera = 0                                                                               --镜头计数归零
                end     
            end
        elseif self._currentPhase == Phase.Battle then
            --战斗阶段逻辑
            if self._levelTime > self._tiredTime then
                --够钟去疲劳阶段了
                self:SetPhase(Phase.Tired)       --跳入疲劳阶段4
            end     --战斗阶段的逻辑段
            return
        elseif self._currentPhase == Phase.Tired then
            if self._tiredDamageTarget == 2 then
                if self._levelTime >= self._player2nextTiredDamageTime and self.fighter2UUID ~= 0 then                       --保证自己还没死才会扣玩家血
                    --扣NPC2的血的时间了
                    self._proxy:DamageRelinkStandalone(self._robotUUID,self.fighter2UUID,0,1010050,1,10000,0,0,0,0)      --扣血的逻辑
                    self._player1nextTiredDamageTime = self._player2nextTiredDamageTime + dt         --下一帧再扣玩家的
                    self._tiredDamageTarget = 1                                                     --准备轮到玩家1扣血
                end
            elseif self._tiredDamageTarget == 1 then
                if self._levelTime >= self._player1nextTiredDamageTime and self.fighter1UUID ~= 0  then                         
                    --扣NPC1的血的时间了
                    self._proxy:DamageRelinkStandalone(self._robotUUID,self.fighter1UUID,0,1010050,1,10000,0,0,0,0)             --扣血的逻辑
                    self._player2nextTiredDamageTime = self._player1nextTiredDamageTime + 1          --NPC2的扣血时间改到1秒后
                    self._tiredDamageTarget = 2                                                      --准备轮到玩家2扣血
                    self._tiredDamageLevel = self._tiredDamageLevel + 1                              --疲劳伤害等级+1
                    self._robotNextAttack = self._tiredArgA * ((self._tiredDamageLevel/3) ^ self._tiredArgB)    -- 计算疲劳攻击力
                    self._robotAttackTmeple = self._proxy:GetNpcAttribMaxValue(self._robotUUID,ENpcAttrib.Attack)                                                     
                    self._proxy:AddNpcAttribAdditive(self._robotUUID,ENpcAttrib.Attack,(self._robotNextAttack - self._robotAttackTmeple) ,0)         --疲劳机器人攻击力改变
                end
            end
        end
    end
end
function XLevelScript1071:OnExitPhase(phase)
    --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段

end
function XLevelScript1071:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end
function XLevelScript1071:HandlePhaseEvent(eventType, eventArgs)
    --处理阶段相关的事件响应，一般在这里跳转关卡阶段

end
function XLevelScript1071:CheckFightEnd()
    if self.isEndBattle then
        return
    end
    if self.fighter1UUID == 0 then                 --玩家1死了
        if self._isSomeoneDead == false then                                                         --准备结束，给UI动画延迟一点时间
            self._fightUiDisableTime = self._levelTime
            self._proxy:SetAutoChessUiActive(true,"FightUiDisable")                                  --战斗UI退场
            self._isSomeoneDead = true
            if self._isTiredTime then                                                                 --删除疲劳特效
                self._proxy:KillStayScreenEffectById(1071001)
            end
            if self._proxy:CheckNpc(self.fighter2UUID) then
                self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1010051,0,1)                 --锁血
                self._proxy:RemoveBuff(self.fighter2UUID,1015992)                                       --移除AI启动标记
            end
        end
        if self._levelTime >= self._fightUiDisableTime + self._deadToEndTime then                       --手动延时0.5s,因为FightUiDisable的动画时长就是0.5s
            self.isEndBattle = true
            self._proxy:SettleFight(false)
            return                                                                                      --加上return，防止下方的判断条件继续判断导致双方一起死
        end
    end
    
    if self.fighter2UUID == 0 then                     --玩家2死了
        if self._isSomeoneDead == false then                                                         --准备结束，给UI动画延迟一点时间
            self._fightUiDisableTime = self._levelTime
            self._proxy:SetAutoChessUiActive(true,"FightUiDisable")                                  --战斗UI退场
            self._isSomeoneDead = true
            if self._isTiredTime then                                                                 --删除疲劳特效
                self._proxy:KillStayScreenEffectById(1071001)
            end
            if self._proxy:CheckNpc(self.fighter1UUID) then
                self._proxy:ApplyMagic(self.fighter1UUID,self.fighter1UUID,1010051,0,1)                --锁血
                self._proxy:RemoveBuff(self.fighter1UUID,1015992)                                      --移除AI启动标记
            end
        end
        if self._levelTime >= self._fightUiDisableTime + self._deadToEndTime   then                    --手动延时0.5s,因为FightUiDisable的动画时长就是0.5s
            self.isEndBattle = true
            self._proxy:SettleFight(true)
            return
        end
    end
end

--endregion

--region Event
---Npc死亡
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XLevelScript1071:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID == self.fighter1UUID then               --如果是玩家1发生了死亡
        self.fighter1UUID = 0
    elseif npcUUID == self.fighter2UUID then            --如果是玩家2发生了死亡
        self.fighter2UUID = 0
    end
end
--endregion

return XLevelScript1071