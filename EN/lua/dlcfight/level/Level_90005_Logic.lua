local XLevelScript90005 = XDlcScriptManager.RegLevelLogicScript(90005, "XLevel90005") --注册脚本类到管理器（逻辑脚本注册
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")
---@param proxy XDlcCSharpFuncs
function XLevelScript90005:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._timer = Timer.New()
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID,获取本关ID
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    self._localNpc = self._proxy:GetLocalPlayerNpcId()
end

local UIControl = {
    On = 100,                               --全开
    Off = 10                                --全关
}
local UIType = {
    Joystick = 1, --摇杆
    ControlPanel = 2, --右侧控制面板
    Target =3, --目标信息
    StagePanel = 4, --关卡面板
    LockTarget = 7,  --锁定
    Menu = 8, --菜单
    EnergyNode = 9, --能量条
    Dialog = 10, --弹框
    TeamInfo = 1001, --队伍信息
    DlcExtraControl = 1002, --DLC额外按钮
    StageInfo = 1003, --关卡信息
    Gameplay = 1007, --玩法
    BreakDamage = 1008, --break总伤害
    TeammateInfo = 1009, --队友关键行为信息
    MechanicInfo = 1010, --机制进度
    Commentary = 2001, -- Guide画外音
    Conversation = 2002, -- Guide画外音对话
    Tips = 2003, -- GuideTips
    ImageVideo = 2004 -- Guide图片/视频
    
}
function XLevelScript90005:ControlLevelUI(SwitchType)    --关卡内，控制UI的方法
    if SwitchType == UIControl.Off then
        self._proxy:SetLevelUiState(UIType.Joystick,self._localNpc,3)            --隐藏摇杆
        self._proxy:SetLevelUiState(UIType.ControlPanel,self._localNpc,3)         --隐藏右侧面板
        self._proxy:SetLevelUiState(UIType.Target,self._localNpc,3)              --隐藏目标面板
        self._proxy:SetLevelUiState(UIType.StagePanel,self._localNpc,3)          --隐藏关卡面板
        self._proxy:SetLevelUiState(UIType.LockTarget,self._localNpc,3)          --隐藏锁定面板
        self._proxy:SetLevelUiState(UIType.Menu,self._localNpc,3)                --隐藏从菜单面板
        self._proxy:SetLevelUiState(UIType.EnergyNode,self._localNpc,3)          --隐藏能量条面板
        self._proxy:SetLevelUiState(UIType.TeamInfo,self._localNpc,3)            --隐藏队伍信息面板
        self._proxy:SetLevelUiState(UIType.Gameplay,self._localNpc,3)            --隐藏玩法面板
        self._proxy:SetLevelUiState(UIType.DlcExtraControl,self._localNpc,3)     --隐藏DLC额外面板
        self._proxy:SetLevelUiState(UIType.StageInfo,self._localNpc,3)
        self._proxy:SetLevelUiState(UIType.Gameplay,self._localNpc,3)

    elseif SwitchType == UIControl.On then
        self._proxy:SetLevelUiState(UIType.Joystick,self._localNpc,1)            --显示摇杆
        self._proxy:SetLevelUiState(UIType.ControlPanel,self._localNpc,1)         --显示右侧面板
        self._proxy:SetLevelUiState(UIType.Target,self._localNpc,1)              --显示目标面板
        self._proxy:SetLevelUiState(UIType.StagePanel,self._localNpc,1)          --显示关卡面板
        self._proxy:SetLevelUiState(UIType.LockTarget,self._localNpc,1)          --显示锁定面板
        self._proxy:SetLevelUiState(UIType.Menu,self._localNpc,1)                --显示从菜单面板
        self._proxy:SetLevelUiState(UIType.EnergyNode,self._localNpc,1)          --显示能量条面板
        self._proxy:SetLevelUiState(UIType.TeamInfo,self._localNpc,1)            --显示队伍信息面板
        self._proxy:SetLevelUiState(UIType.Gameplay,self._localNpc,1)            --显示玩法面板
        self._proxy:SetLevelUiState(UIType.DlcExtraControl,self._localNpc,1)     --显示DLC额外面板
        self._proxy:SetLevelUiState(UIType.StageInfo,self._localNpc,1)
        self._proxy:SetLevelUiState(UIType.Gameplay,self._localNpc,1)
    end
end

function XLevelScript90005:Init() --初始化逻辑
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                                       --事件注册：NPC死亡
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)                                       --事件注册：NPC上BUFF
    self._proxy:RegisterEvent(EWorldEvent.RelinkGuideFinish)                                   --事件注册：引导结束
    ----------------地图初始化----------------------------------------------------------------------
    
    --变量初始化
    self._localPlayerNpcUUID = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npcUUID
    self._localPlayerDeathTimes = 0                                                      -- 初始化本端玩家死亡次数
    self._levelTime = 0 
    self._levelBeginTime = 3
    self._isReadyToEnd = false                                                                 --关卡时间初始化
    self._isPlayerWin = false
    self._currentPhase = -1                                          --当前阶段
    self._lastPhase = 0                                              --上一阶段
    self._spawnPoint = {}                                            --获取点位序号，初始化中获取
    self._spawnRotation = { 0, 0, 0 }                                --获取点位面向
    self._playerRebornTimes = 3                                      --复活次数
    
    --拿到玩家列表
    
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
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, self._spawnPoint[1], monsterBornRota)
    self._proxy:SetNpcFaceToPosition(self.monster_UUID,self._spawnPoint[2])                  --设置看向BOSS的位置
    ---------------空NPC配置------------------------------------------------------------------------------------------
    local robotNpcId = 1016
    local robotCamp = ENpcCampType.Camp1
    local robotBornRota = { x = 0, y = 0, z = 0 }
    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRota)
    self._proxy:SetTeamWorkSkillActive(true,300,5)
    --XLog.Warning("开启团队协作系统")
    -----------------传送玩家位置--------------------------------------------------------------------------------------------
    for i=1, 3 do
        if self._proxy:CheckNpc(self._playerNpcList[i]) then
            self._proxy:SetNpcPosition(self._playerNpcList[i], self._spawnPoint[i+2])                 --传送玩家1位置
            self._proxy:SetNpcFaceToPosition(self._playerNpcList[i],self._spawnPoint[1])                  --设置看向BOSS的位置
        end
    end
    self._proxy:ApplyMagic(self._localNpc,self._localNpc,1000489,1)
    --------------------开局UI全关----------------------------------------
    self:ControlLevelUI(UIControl.Off)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,false)
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,false)
    -----------------关闭白龙AI----------------------------------
    self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI

end

--region 关卡阶段管理
local Phase = {
    Start = 0,
    Move = 1,
    Attack = 2,
    Attack_2 = 21,
    Dodge = 3,
    Dodge_2 = 31,
    Skill = 4,
    QTEGuide = 5,
    SuperSkill = 6,
    ODSikll = 7,
    BerserkSkill = 8,
    Break_1 = 9,
    Hisastu = 10,
    Break_2 = 11,
    Final = 12
}


---@param dt number @ delta time
function XLevelScript90005:Update(dt) --每帧更新逻辑
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    if self.isLeveEnd then                     --判断关卡是否已经结束
        return
    end
    self:LevelEnd(self._isPlayerWin)
    if self.monster_UUID ~= 0 then
        if self._proxy:CheckNpc(self.monster_UUID) == true and self._proxy:CheckActorExist(self.monster_UUID) == true then
            self._monsterHP = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.Life)    --获取boss当前血量
        end
    end
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
    if phase == Phase.Start then
        XLog.Debug("阶段进入!Phase.Start")
        self._proxy:ShowDlcGuide(90005101,EGuideUiNodeType.GuideCommentary)                      --准备进行第一次熵流运算模拟，本次模拟的战斗对象危险程度很高，请务必小心！
        self:ControlLevelUI(UIControl.OnlyCommentary)
        self._timetoMoveGuide = self._levelTime   --记录时间
        self._monsterMaxHP = self._proxy:GetNpcAttribMaxValue(self.monster_UUID,ENpcAttrib.Life)    --获取boss当前血量
    elseif phase == Phase.Move then  
        XLog.Debug("阶段进入!Phase.Move")
        self._proxy:ShowDlcGuide(90005102,EGuideUiNodeType.GuideCommentary)                      --向前移动靠近模拟战斗目标.
        self._proxy:SetLevelUiState(UIType.Joystick,self._localNpc,1)                   --显示摇杆
        self._proxy:SetLevelUiState(UIType.ControlPanel,self._localNpc,1)                   --显示右侧面板
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Dodge,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Focus,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.ExSkill,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Ball1,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Ball2,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Ball3,self._localNpc,3) 
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Attack,self._localNpc,3) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,true) --允许跳跃
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,true) --允许摇杆
    elseif phase == Phase.Attack then
        XLog.Debug("阶段进入!Phase.Attack")
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Attack,self._localNpc,1) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,true)                           --只显示普攻按钮
        self._proxy:ShowDlcGuide(90005103,EGuideUiNodeType.GuideCommentary)                                              --向前移动靠近模拟战斗目标.
        self._proxy:SetLevelUiState(UIType.Target,self._localNpc,1)
        self._proxy:SetLevelUiState(UIType.LockTarget,self._localNpc,1)
        self._proxy:SetLevelOperationUiState(UIType.LockTarget,ENpcOperationKey.Focus,self._localNpc,1)          --锁定
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,true)
        self._proxy:SetLevelUiState(UIType.TeamInfo,self._localNpc,1)
        self._proxy:SetLevelUiState(UIType.Menu,self._localNpc,1)
    elseif phase == Phase.Dodge then
        XLog.Debug("阶段进入!Phase.Dodge")
        self._proxy:CastActionToTarget(self.monster_UUID,8005296,self._localNpc)          --左挥手
        self._hasbossfirstskill = false
    elseif phase == Phase.Dodge_2 then
        self._timeToSkill = self._levelTime
        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --打开白龙AI（一阶段AI只会普攻）
        XLog.Debug("阶段进入!Phase.Dodge_2")
    elseif phase == Phase.Skill then
        self._hasbossScecondSkill = false
        self.hasSetPhaseQTE = false
        self._proxy:SetLevelUiState(UIType.DlcExtraControl,self._localNpc,1)--提前开启QTE界面
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.RelinkBreakQte,self._localNpc,1)         --开启QTE
        self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Interact,self._localNpc,1)         --屏蔽互动键
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Interact,self._localNpc,true)
        XLog.Debug("阶段进入!Phase.Skill")
    elseif phase == Phase.QTEGuide then
        self.hasSetPhaseSuperSkill = false
        self._hasbossscecondSkill = true
        self._proxy:ShowDlcGuide(90005106,EGuideUiNodeType.GuideCommentary)                      --敌人韧性条被击破了，抓住机会进攻！
        XLog.Debug("阶段进入!Phase.QTEGuide")
    elseif phase == Phase.SuperSkill then
        self.hasBossSuperSkill = false
        self.bossSuperSkilling = false
        self._hasFinishSuperSkillGuide = false
        self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,-100,0)    --还原一点白毛击破倍率
        XLog.Debug("阶段进入!Phase.SuperSkill")
    elseif phase == Phase.ODSikll then
        self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.OverDriveStackP,0,0)
        XLog.Debug("阶段进入!Phase.ODSkill")
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
    if self._currentPhase == -1 then       --绝对的初始化阶段
        if self._levelTime >= self._levelBeginTime then
            self:SetPhase(Phase.Start)                       --开始开局流程画外音引导
        end
    elseif self._currentPhase == Phase.Start then   
        if self._levelTime >= self._timetoMoveGuide + 8 then
            self:SetPhase(Phase.Move)
        end
    elseif self._currentPhase == Phase.Move then   
        self._npcToMonsterDis = self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true)
        if self._npcToMonsterDis <= 12 and not self._hasAttcked then --走的足够近的时候
            self:SetPhase(Phase.Attack)
        end
    elseif self._currentPhase == Phase.Attack then
        if self._monsterHP ~= self._monsterMaxHP then              --boss至少挨了一下打
            self:SetPhase(Phase.Dodge)
        end
    elseif self._currentPhase == Phase.Dodge then
        self._isSuccess , self._firstSkillTime = self._proxy:TryGetNpcCurrentActionElapsedTime(self.monster_UUID)
        if (self._isSuccess) and (self._firstSkillTime >= 0.7) and (self._hasbossfirstskill ~= true) then
            self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Dodge,self._localNpc,1)  --按键显示打开
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,true) 
            self._proxy:ShowDlcGuide(90005104,EGuideUiNodeType.GuideCommentary)                      --闪避引导
            self._hasbossfirstskill = true
            self:SetPhase(Phase.Dodge_2)
        end
    elseif self._currentPhase == Phase.Dodge_2 then
        if ((self._monsterHP/self._monsterMaxHP) <= 0.98)                       --把BOSS打掉2%了
            or (self._levelTime - self._timeToSkill >= 15) then              --或者和BOSS打了有一会儿了 15秒
            if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) then      --可以释放对应技能的情况下
                self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
                self._proxy:CastActionToTarget(self.monster_UUID,8005015,self._localNpc)          --后跳一下
                self:SetPhase(Phase.Skill)
            end
        end
    elseif self._currentPhase == Phase.Skill then
        self._isSuccess , self._scecondSkillTime = self._proxy:TryGetNpcCurrentActionElapsedTime(self.monster_UUID)
        if (self._isSuccess) and (self._scecondSkillTime >= 1.2) and (self._hasbossscecondSkill ~= true) then
            self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Ball1,self._localNpc,1)  --引导打开
            self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Ball2,self._localNpc,1)  --引导打开
            self._proxy:SetLevelOperationUiState(UIType.ControlPanel,ENpcOperationKey.Ball3,self._localNpc,1)  --引导打开
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,true) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,true) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,true) 
            self._proxy:ShowDlcGuide(90005105,EGuideUiNodeType.GuideCommentary)                      --技能引导
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --关闭白龙AI
            self._hasbossscecondSkill = true
            self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,150,0)    --增加白毛击破倍率
        end
        if self.monster_UUID ~= 0 then
            if self._proxy:CheckNpc(self.monster_UUID) == true and self._proxy:CheckActorExist(self.monster_UUID) == true then
                self._monsterBG = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.BreakGauge)    --获取boss当前韧性
            end
        end
        if self._monsterBG == 0 and self.hasSetPhaseQTE == false then
            self.hasSetPhaseQTE = true
            self._timer:Schedule(0.6, self, function()
                self:SetPhase(Phase.QTEGuide)
            end)
        end
    elseif self._currentPhase == Phase.QTEGuide then
        if self.hasSetPhaseSuperSkill == false then
            self.hasSetPhaseSuperSkill = true
            self._timer:Schedule(10, self, function()
                self:SetPhase(Phase.SuperSkill)
            end)
        end
    elseif self._currentPhase == Phase.SuperSkill then

        if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) and self.hasBossSuperSkill ~= true then      --可以释放对应技能的情况下
            if self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) >= 13 then                     --距离够近的话
                self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
                self._proxy:CastActionToTarget(self.monster_UUID,8005032,self._localNpc)          --横扫弹刀技能
                self._timer:Schedule(0.5, self, function()
                    self._proxy:ShowDlcGuide(90005108,EGuideUiNodeType.GuideImageVideo)     --拼刀图文引导 
                end)
                self.hasBossSuperSkill = true
                self._timer:Schedule(1.6, self, function()
                    self._proxy:ShowDlcGuide(90005109,EGuideUiNodeType.GuideCommentary) --拼刀引导强制
                end)
            elseif self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) < 13 then
                self._proxy:CastActionToTarget(self.monster_UUID,8005015,self._localNpc)          --后跳一下
            end
        end
    elseif self._currentPhase == Phase.ODSikll then

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
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcDie then                         --NPC死亡事件监听
        self:CheckLevelEnd()
        ----失败结算检测-----------------
        if self:CheckAllPlayerDead() then
            if self._isReadyToEnd ~= true then                      
                self._levelEndTime = self._levelTime                --死完了，确定游戏结算时间
                self._isReadyToEnd = true
            end
            self._isPlayerWin = false                               --玩家失败传参修改
        end    
    elseif eventType == EWorldEvent.NpcAddBuff then                 --上BUFF事件监听
        local npc = eventArgs.NpcUUID
        if eventArgs.BuffTableId == 0 then
    
        end
    elseif eventType == EWorldEvent.RelinkGuideFinish then           --引导完成事件
        if eventArgs.GuideId == 90005103 then   --攻击
            self._proxy:AbortAction(self._localNpc,true)
            self._proxy:CastActionToTarget(self._localNpc,1051001,self.monster_UUID)        --1段普攻
        elseif eventArgs.GuideId == 90005104 then
            self._proxy:AbortAction(self._localNpc,true)
            self._proxy:CastAction(self._localNpc,1051007)        --闪避
        elseif eventArgs.GuideId == 90005105 then -- 技能
            self._proxy:AbortAction(self._localNpc,true)
            self._proxy:CastActionToTarget(self._localNpc,1051020,self.monster_UUID)        --蓄力追刀
        elseif eventArgs.GuideId == 90005107 then -- 破韧QTE 
            self._proxy:AbortAction(self._localNpc,true)
            self._proxy:CastActionToTarget(self._localNpc,1051092,self.monster_UUID)        --破韧技能
        elseif eventArgs.GuideId == 90005108 then -- 视频引导
            
        elseif eventArgs.GuideId == 90005109 then -- 强制拼刀
            if self._proxy:CheckNpcCurActionIsDone(self._localNpc) then 
                self._proxy:AbortAction(self._localNpc,true)  --打断技能
                self._proxy:CastActionToTarget(self._localNpc,1051001,self.monster_UUID)        --1段普攻
            end
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --打开白龙AI
            self:SetPhase(Phase.ODSikll)
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