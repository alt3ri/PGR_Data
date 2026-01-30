local XLevelScript9001 = XDlcScriptManager.RegLevelLogicScript(9001, "XLevel9001") --注册脚本类到管理器（逻辑脚本注册
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")
local XRelinkLevelAudioPlayer = require("Tools/Audio/XRelinkLevelAudioPlayer")
local EFightCVAction = require("Enum/XFightCVAction")            --CV播放插件

---@param proxy XDlcCSharpFuncs
function XLevelScript9001:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._timer = Timer.New()
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    ---@type XRelinkLevelAudioPlayer
    self._audioPlayer = XRelinkLevelAudioPlayer.New(proxy)
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID,获取本关ID
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    self._localNpc = self._proxy:GetLocalPlayerNpcId()
    
end

local UIControl = {
    On = 100,                               --全开
    Off = 10                                --全关
}

function XLevelScript9001:ControlLevelUI(SwitchType)    --关卡内，控制UI的方法
    if SwitchType == UIControl.Off then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,3)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,3)         --隐藏右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localNpc,3)              --隐藏目标面板
        --self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localNpc,3)          --隐藏关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localNpc,3)          --隐藏锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localNpc,3)                --隐藏从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localNpc,3)          --隐藏能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localNpc,3)            --隐藏队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localNpc,3)            --隐藏玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localNpc,3)     --隐藏DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localNpc,3)    --隐藏聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localNpc,3)    --隐藏聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localNpc,3)    --隐藏任务
    elseif SwitchType == UIControl.On then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,1)            --显示摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,1)         --显示右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localNpc,1)              --显示目标面板
        --self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localNpc,1)          --显示关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localNpc,1)          --显示锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localNpc,1)                --显示从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localNpc,1)          --显示能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localNpc,1)            --显示队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localNpc,1)            --显示玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localNpc,1)     --显示DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localNpc,1)    --显示聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localNpc,1)    --显示聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localNpc,1)    --显示任务
    end
end

function XLevelScript9001:ChangeNpcAttribute(uuid,attrib,value,persent)  --修改NPC对应属性
    local maxAttri = self._proxy:GetNpcAttribMaxValue(uuid,attrib)  --获取当前
    if maxAttri >= value then --如果原来的更大一点
        self._proxy:AddNpcAttribAdditive(uuid,attrib,-(maxAttri - value) ,persent)
    elseif maxAttri < value then
        self._proxy:AddNpcAttribAdditive(uuid,attrib,(maxAttri - value) ,persent)
    end
end

function XLevelScript9001:Init() --初始化逻辑
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                                       --事件注册：NPC死亡
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)                                       --事件注册：NPC上BUFF
    self._proxy:RegisterEvent(EWorldEvent.RelinkGuideFinish)                                   --事件注册：引导结束
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)                                          --事件注册：角色闪避
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkill)                                          --事件注册：角色释放技能
    self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)                                          --事件注册：角色退出技能
                          
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkCounterSuccess)                        --事件注册：弹刀成功
    ----------------地图初始化----------------------------------------------------------------------
    --变量初始化
    self._localPlayerNpcUUID = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npcUUID
    self._localPlayerDeathTimes = 0                                                      -- 初始化本端玩家死亡次数
    self._levelTime = 0 
    self._levelBeginTime = 0.1
    self._isReadyToEnd = false                                                                 --关卡时间初始化
    self._isPlayerWin = false
    self._currentPhase = -1                                          --当前阶段
    self._lastPhase = 0                                              --上一阶段
    self._spawnPoint = {}                                            --获取点位序号，初始化中获取
    self._spawnRotation = { 0, 0, 0 }                                --获取点位面向
    self._playerRebornTimes = 3                                      --复活次数
    self._needDodgeTimes = 3      --教学需要完美闪避次数                 
    self._nowDodgeTimes  = 0    --当前闪避次数
    self._needCrushTimes = 3      --教学需要拼刀次数                     
    self._nowCrushTimes = 0     --当前拼刀次数
    self._audioPlayer:Init(1200)
    self._proxy:SetLevelMemoryInt(40001, 0)                                             --初始化黑板值
    self._proxy:SetLevelMemoryInt(40002, self._nowDodgeTimes)
    self._proxy:SetLevelMemoryInt(40003, self._needDodgeTimes)
    self._proxy:SetLevelMemoryInt(40004, self._nowCrushTimes)
    self._proxy:SetLevelMemoryInt(40005, self._needCrushTimes)
    self.finishSkillGuide = false                           --完成了技能教学引导
    self.ODTriger = false                  --允许OD？
    self.BreakTriger = false                  --允许破韧？
    self.timetoDodgeVideo = false 
    self._guideFinishEventFlag = {                 --引导完成检测单次flag
        guide104 = true,        --极限闪避检测完成？
        guide105 = true,       --技能引导检测完成
        guide107 = true,        --破韧QTE
        guide109 = true,        --拼刀强制引导
        guide106 = true,         --韧性条引导
        guide116 = true
    }
    self.PdodgeCD = true
    self.CounterCD = true       --拼刀事件检测冷却
    self.hasShowGuide120 = false 

    
    for i = 1, 5 do
        --默认1boss出生点，2场地中心点，345玩家出生点
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点
    end
    -- --创建怪物配置
    local monsterId = 8006   --教学关特别版白龙
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 86, y = 1.9, z = 65}
    local monsterBornRota = {x = 0, y = 180, z = 0}

        -- --创建公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = {x = 86, y = 1.9, z = 65}
    local commonNpcBornRota = {x = 0, y = 180, z = 0}
    -----------------创建NPC队友--------------------------------------------------------------------------------------------
    self.NpcNanami = self._proxy:GenerateNpc(1602,ENpcCampType.Camp1,{x=999,y=0,z=999},{x=0,y=0,z=0})--偷偷召唤个70
    self.NpcLiv = self._proxy:GenerateNpc(1603,ENpcCampType.Camp1,{x=999,y=0,z=999},{x=0,y=0,z=0})--偷偷召唤个丽芙
    self._proxy:ApplyMagic(self.NpcNanami,self.NpcNanami,1000489,1) --锁血不死
    self._proxy:ApplyMagic(self.NpcLiv,self.NpcLiv,1000489,1) --锁血不死

    self.isLeveEnd = false --关卡是否结束
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, self._spawnPoint[1], monsterBornRota)
    self._proxy:SetNpcFaceToPosition(self.monster_UUID,self._spawnPoint[2])                  --设置看向BOSS的位置
    self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,1000446,1) --锁血不死
    ---------------空NPC配置------------------------------------------------------------------------------------------
    local robotNpcId = 1016
    local robotCamp = ENpcCampType.Camp1
    local robotBornRota = { x = 0, y = 0, z = 0 }
    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRota)
    self._proxy:SetTeamWorkSkillActive(true,300,5)
    self.playerDeadCountList = {}
    --XLog.Warning("开启团队协作系统")
    -----------------传送玩家位置--------------------------------------------------------------------------------------------
    for i=1, 3 do
        if self._proxy:CheckNpc(self._playerNpcList[i]) then
            self._proxy:SetNpcPosition(self._playerNpcList[i], self._spawnPoint[i+2])                 --传送玩家1位置
            self._proxy:SetNpcFaceToPosition(self._playerNpcList[i],self._spawnPoint[1])                  --设置看向BOSS的位置
        end
    end
    self._proxy:ApplyMagic(self._localNpc,self._localNpc,1000489,1) --锁血不死
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
    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false)
    -----------------------常规音频屏蔽--------------------
    self._audioPlayer:SetCvActionValidation(EFightCVAction.Broken,false)  --破韧语音屏蔽
    self._audioPlayer:SetCvActionValidation(EFightCVAction.OverDriveBreak,false)  --ODbreak提示
    self._audioPlayer:SetCvActionValidation(EFightCVAction.PraiseConterSuccess,false) --拼刀语音提示
    self._audioPlayer:SetCvActionValidation(EFightCVAction.EnterOverDriveWarning,false) --OD状态开启提示
end

--region 关卡阶段管理
local Phase = {
    Start = 0,
    Move = 1,
    Attack = 2,
    Attack_2 = 21,
    Skill = 3,
    Dodge = 4,
    Dodge_2 = 41,
    QTEGuide = 5,
    QTEGuide_2 = 51,
    SuperSkill = 6,
    ODSikll = 7,
    ODSikll_2 =71,
    ODSikll_3 =72,    --七实入场
    ODSikll_4 =73,    --丽芙入场
    BerserkSkill = 8,
    Break_1 = 9,
    Hisastu = 10,
    Break_2 = 11,
    Final = 12,
    End = 13,
    Test = 99
}


---@param dt number @ delta time
function XLevelScript9001:Update(dt) --每帧更新逻辑
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    self:LevelEnd(self._isPlayerWin)
    self._audioPlayer:Update(dt)
    if self.ODTriger == false then            --非OD阶段不让OD，无限归2000
        if self.monster_UUID ~= 0 then
            if self._proxy:CheckNpc(self.monster_UUID) == true and self._proxy:CheckActorExist(self.monster_UUID) == true then
                local tempAttribute = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.OverDrive)
                local tempAttributeRate = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.OverDriveStackP)
                if tempAttribute >= 2000 and tempAttributeRate >= 0 then 
                    self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveStackP,-tempAttributeRate,0)    --白龙OD值归零扣除
                end
            end
        end
    end
    self:OnUpdatePhase(dt)
end

function XLevelScript9001:InitPhase()
    --初始化关卡各个阶段的相关变量
end
---@param phase number
function XLevelScript9001:SetPhase(phase)
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
function XLevelScript9001:OnEnterPhase(phase)
    --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == Phase.Start then
        XLog.Debug("阶段进入!Phase.Start")
        self._proxy:SettleFight(true)  --胜利(无论如何都可以结算胜利)
        self._proxy:SetTeamWorkSkillActive(true,3,3)
        self._proxy:DispatchLuaEvent(2,EFightLuaEvent.RelinkAIBorn,{NpcUUid = self.monster_UUID})               --通知BOSS开始播入场动画
        self._proxy:ShowDlcGuide(90005101,EFightUiType.Commentary)                      --准备进行第一次熵流运算模拟，本次模拟的战斗对象危险程度很高，请务必小心！
        self._timer:Schedule(5.4, self, function()
                self._proxy:PlayStayScreenEffectById(902999)
        end)
        self:ControlLevelUI(UIControl.OnlyCommentary)
        self._timetoMoveGuide = self._levelTime   --记录时间
        self._monsterMaxHP = self._proxy:GetNpcAttribMaxValue(self.monster_UUID,ENpcAttrib.Life)    --获取boss当前血量
        self._proxy:SetLevelMemoryInt(40001, 1) 
        self._backGrounSoundUid = self._proxy:PlaySound(6515,ETargetActorType.Npc,self._localNpc)                 --环境音
    elseif phase == Phase.Move then  
        XLog.Debug("阶段进入!Phase.Move")
        self._timer:Schedule(2.6, self, function()
            self._proxy:KillStayScreenEffectById(902999)
        end)
        self._timer:Schedule(3.5, self, function()
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localNpc,1)    --显示任务
            self._proxy:ShowDlcGuide(90005102,EFightUiType.Commentary)                      --向前移动靠近模拟战斗目标.
            self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localNpc,1)                   --显示摇杆
            self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localNpc,1)                   --显示右侧面板
            self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localNpc,1)
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,3) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Pause,self._localNpc,true)                         --暂停键
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false) 
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,true) --允许跳跃
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,true) --允许摇杆
            self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.DodgeEnergyRegen,5000,0)    --闪避值无限
            self._proxy:SetLevelMemoryInt(40001, 2) 
        end)
        
    elseif phase == Phase.Attack then
        XLog.Debug("阶段进入!Phase.Attack")
        self._hasOpenAI = false
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,1) 
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,true)                           --解锁攻击手段
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,1)  
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,1)  
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,1)  
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,true) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,1)           --闪避
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,true)  
        self._proxy:ShowDlcGuide(90005103,EFightUiType.Commentary)                                                  --迎战准备
        self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001001)   --cv迎战准备                         
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localNpc,1)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._localNpc,true)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonLockTarget,ENpcOperationKey.Focus,self._localNpc,1)             --锁定
        self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,-90,0)    --降低白毛击破倍率
    elseif phase == Phase.Skill then
        self._hasbossScecondSkill = false
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localNpc,1)--提前开启QTE界面
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._localNpc,true)
        self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,-10,0)    --降低白毛击破倍率
        XLog.Debug("阶段进入!Phase.Skill")
    elseif phase == Phase.Dodge then
        XLog.Debug("阶段进入!Phase.Dodge")
        self._proxy:CastActionToTarget(self.monster_UUID,8005296,self._localNpc)          --左挥手
        self.hasDodgeVideo = false 
        self._hasbossfirstskill = false
    elseif phase == Phase.Dodge_2 then
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localNpc,1)
        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --打开白龙AI
        XLog.Debug("阶段进入!Phase.Dodge_2")
        self._proxy:SetLevelMemoryInt(40001, 6)
    elseif phase == Phase.QTEGuide then
        self.hasSetPhaseQTE = false
        self.hasSetPhaseSuperSkill = false
        self._hasbossscecondSkill = true
        self.finishBGGuide = false
        self.startBGguide = false        
        self._timer:Schedule(1, self, function() 
            --self._proxy:ShowDlcGuide(90005106,EFightUiType.Commentary)              --看韧性条
            self._proxy:ShowDlcGuide(90005116,EFightUiType.Commentary)              --注视
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --打开白龙AI
            self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,1000,0)    --增加白毛击破倍率
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,true)
        end)
        self.BreakTriger = true
        XLog.Debug("阶段进入!Phase.QTEGuide")
    elseif phase == Phase.QTEGuide_2 then
        self._proxy:SetLevelMemoryInt(40001, 81)
        self._proxy:ShowDlcGuide(90005107,EFightUiType.Commentary)     --敌人韧性条被击破
        self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001007)   --干得好，失去平衡 
        XLog.Debug("阶段进入!Phase.QTEGuide_2")
    elseif phase == Phase.SuperSkill then
        self.hasBossSuperSkill = false
        self.bossSuperSkilling = false
        self._hasFinishSuperSkillGuide = false
        self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,-600,0)    --还原一点白毛击破倍率
        XLog.Debug("阶段进入!Phase.SuperSkill")
        
    elseif phase == Phase.ODSikll then
        self.haspindaoSkill = false
        self.hasOD = false
        self._timer:Schedule(1, self, function()               
            self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveStackP,4000,0)  --OD倍率
            self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localNpc,1)              --显示怪物血量
            self._proxy:ShowDlcGuide(90005115,EFightUiType.Commentary)--这是OD
        end)
        XLog.Debug("阶段进入!Phase.ODSkill")

    elseif phase == Phase.ODSikll_2 then
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveStackP,-2000,0)  --OD倍率
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveDecreaseSpeed,-25,0)  --OD自然衰减速度归零
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveDecreaseP,-881,0)  --OD挨打倍率归零
        XLog.Debug("阶段进入!Phase.ODSkill_2")
    elseif phase == Phase.ODSikll_3 then
        self.ODfire = false 
        self.finishFire = false 
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveStackP,2000,0)  --OD倍率
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveDecreaseSpeed,75,0)  --OD自然衰减速度
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveDecreaseP,2000,0)  --OD挨打倍率
        self._timer:Schedule(15, self, function()  
            self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005974) --喷火技能
        end)
        XLog.Debug("阶段进入!Phase.ODSkill_3")
    elseif phase == Phase.ODSikll_4 then
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveDecreaseSpeed,25,0)  --OD自然衰减速度恢复
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveDecreaseP,881,0)  --OD挨打倍率恢复
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveStackP,500,0)  --OD倍率
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.DmgAmplification,3000,0)    --把boss易伤挂上
        self:ControlLevelUI(UIControl.On)
        self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localNpc,3)          
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localNpc,3)     
        self._proxy:SetLevelMemoryInt(40001,10)
        XLog.Debug("阶段进入!Phase.ODSkill_4")
    elseif phase == Phase.Break_1 then
        self.hasEnd = false
        self.hasODfire_PhaseBreak = false 
        self.hasTeamSkill = false 
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.DmgAmplification,5000,0)    --把boss易伤挂上
        self._timer:Schedule(2, self, function()  
            self._proxy:ApplyMagic(self._localNpc,self._localNpc,10519118)                  --白毛大招拉满
            self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.DodgeEnergyRegen,-4000,0)    --闪避值削弱
            self._proxy:ShowDlcGuide(90005316,EFightUiType.ImageVideo)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,true) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,1)
        end)
        XLog.Debug("阶段进入!Phase.Break_1")
    elseif phase == Phase.Break_2 then

    elseif phase == Phase.Final then
        self.hasODfire_PhaseFinal = false 
        
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.DmgAmplification,8000,0)    --把boss易伤挂上
        XLog.Debug("阶段进入!Phase.Final")
    elseif phase == Phase.End then
        XLog.Debug("阶段进入!Phase.End")
        self._audioPlayer:PlayAudioFightWin()
        self._proxy:StopAudioByUid(self._backGrounSoundUid)
        self._timer:Schedule(5, self, function()               
            self._proxy:FinishFight()
        end)
    elseif phase == Phase.Test then   --OD阶段对应的配置
        self.ODTriger = true                  --允许OD
        self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005963,1)           --白龙AI会放拼刀技能
        self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005964,1)          --白龙AI允许OD
        self._proxy:AddNpcAttribAdditive(self._localNpc,ENpcAttrib.BreakDmg,600,0)    --增加白毛击破倍率
        self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.OverDriveStackP,4000,0)  --OD倍率
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localNpc,1)              --显示怪物血量
        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --打开白龙AI
    end
end

---@param dt number @ delta time
function XLevelScript9001:OnUpdatePhase(dt)
    --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == -1 then       --绝对的初始化阶段
        if self._levelTime >= self._levelBeginTime then
            self:SetPhase(Phase.Start)                       --开始开局流程画外音引导
        end
    elseif self._currentPhase == Phase.Start then   
        if self._levelTime >= self._timetoMoveGuide + 5.4 then
            self:SetPhase(Phase.Move)
        end
    elseif self._currentPhase == Phase.Move then   
        self._npcToMonsterDis = self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true)
        if self._npcToMonsterDis <= 12 and not self._hasAttcked then --走的足够近的时候
            self:SetPhase(Phase.Attack)
            self._proxy:SetLevelMemoryInt(40001, 21)       --完成靠近引导
        end
    elseif self._currentPhase == Phase.Attack then
        if self.monster_UUID ~= 0 then
            if self._proxy:CheckNpc(self.monster_UUID) == true and self._proxy:CheckActorExist(self.monster_UUID) == true then
                self._monsterHP = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.Life)    --获取boss当前血量
            end
        end
        if self._monsterHP ~= self._monsterMaxHP and self._hasOpenAI == false then              --boss至少挨了一下打 
            self._timer:Schedule(1, self, function()                --1秒后打开白龙AI
                self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005962,1)                            --白龙AI只放小技能
            end)
            self._timer:Schedule(7, self, function()                --7秒后打开技能教学  
                self:SetPhase(Phase.Skill)
            end)
            self._hasOpenAI = true
        end
    elseif self._currentPhase == Phase.Skill then
        if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) and (self._hasbossscecondSkill ~= true) then
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,true) 
            self._proxy:ShowDlcGuide(90005105,EFightUiType.Commentary)                      --技能引导01
            self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001005)
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
            self._hasbossscecondSkill = true
        end
        if self.finishSkillGuide then 
            if self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) < 7 then
                self._proxy:CastActionToTarget(self.monster_UUID,8005015,self._localNpc)          --后跳一下
            end
            if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) then
                if not self._proxy:CheckNpcOnAir(self._localNpc) and self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) < 13 then
                    self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
                    self:SetPhase(Phase.Dodge)  
                end
            end
        end
    elseif self._currentPhase == Phase.Dodge then
        self._isSuccess , self._firstSkillTime = self._proxy:TryGetNpcCurrentActionElapsedTime(self.monster_UUID)
        if (self._isSuccess) and (self._firstSkillTime >= 0.8) and (self._hasbossfirstskill ~= true)  then
            self._proxy:ShowDlcGuide(90005104,EFightUiType.Commentary)                      --闪避引导
            self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001003)
            self._hasbossfirstskill = true
            self:SetPhase(Phase.Dodge_2)
        end
    elseif self._currentPhase == Phase.Dodge_2 then
        if self.timetoDodgeVideo == true and self.hasDodgeVideo == false then 
            self._proxy:ShowDlcGuide(90005310,EFightUiType.ImageVideo)  --闪避图文
            self.hasDodgeVideo = true 
        end
        if self._nowDodgeTimes == 2 and self.hasShowGuide120 == false  then
            self._proxy:ShowDlcGuide(90005120,EFightUiType.Commentary)  --“闪避成功有免伤”   
            self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001004)
            self.hasShowGuide120 = true 
        end
        if self._nowDodgeTimes >= self._needDodgeTimes then              --完成了三次以上?
            if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) then      --可以释放对应技能的情况下
                self._proxy:CastActionToTarget(self.monster_UUID,8005015,self._localNpc)          --后跳一下
                self._proxy:SetLevelMemoryInt(40001, 61)       --完成任务
                self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})     --关闭白龙AI
                self._timer:Schedule(1.2, self, function()       --1.2秒后开始韧性条教学          
                    self:SetPhase(Phase.QTEGuide)
                end)
            end
        end
    elseif self._currentPhase == Phase.QTEGuide then  
        if self.monster_UUID ~= 0 then
            if self._proxy:CheckNpc(self.monster_UUID) == true and self._proxy:CheckActorExist(self.monster_UUID) == true then
                self._monsterBG = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.BreakGauge)    --获取boss当前韧性
            end
        end
        if self.finishBGGuide == false and self.startBGguide == false then
            self.startBGguide = true
            self._proxy:SetLevelMemoryInt(40001, 8)
        end
        if self._monsterBG == 0 and self.hasSetPhaseQTE == false then
            self.hasSetPhaseQTE = true
            self._timer:Schedule(0.2, self, function()
                self:SetPhase(Phase.QTEGuide_2)
            end)
        end
    elseif self._currentPhase == Phase.QTEGuide_2 then
        if self.hasSetPhaseSuperSkill == false then
            self.hasSetPhaseSuperSkill = true
            self._timer:Schedule(10, self, function()
                self:SetPhase(Phase.SuperSkill)
            end)
        end
    elseif self._currentPhase == Phase.SuperSkill then
        if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) and self.hasBossSuperSkill ~= true then      --可以释放对应技能的情况下
            if self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) >= 8 and self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) <= 14 then     --距离(8,14]
                if not self._proxy:CheckNpcOnAir(self._localNpc) then 
                    self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=false})                  --关闭白龙AI
                    self._proxy:CastActionToTarget(self.monster_UUID,8005525,self._localNpc)          --特制版横扫弹刀技能
                    self._timer:Schedule(0.3, self, function() 
                        self._proxy:ShowDlcGuide(90005308,EFightUiType.ImageVideo)     --拼刀图文引导 
                    end)
                    self.hasBossSuperSkill = true
                    self._timer:Schedule(1.55, self, function()
                        self._proxy:ApplyMagic(self._localNpc,self._localNpc,10511207)--刷新1技能
                        self._proxy:ShowDlcGuide(90005109,EFightUiType.Commentary) --拼刀引导强制
                        self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001008)
                    end)
                end
            elseif self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) < 8 then
                self._proxy:CastActionToTarget(self.monster_UUID,8005015,self._localNpc)          --后跳一下
            end
        end
        if self._nowCrushTimes >= self._needCrushTimes then                --拼刀3次
            if self.ODTriger == false then 
                self._proxy:SetLevelMemoryInt(40001, 91)       --完成任务
                self.ODTriger = true                  --允许OD
                self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005964,1)          --白龙AI允许OD
                self._timer:Schedule(3, self, function()
                    self:SetPhase(Phase.ODSikll)   
                end)
            end
           
        end
    elseif self._currentPhase == Phase.ODSikll then 
        self._BOSSOD = self._proxy:GetNpcAttribValue(self.monster_UUID,ENpcAttrib.OverDrive)
        if self._BOSSOD >= 10000 and self.hasOD == false then  --boss狂暴了
            self._proxy:ShowDlcGuide(90005113,EFightUiType.Commentary)--"改变进攻模式"
            self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001010)
            self._proxy:SetLevelMemoryInt(40001, 71) 
            self.hasOD = true
            self._timer:Schedule(3, self, function()
                self:SetPhase(Phase.ODSikll_2)  
            end)  
        end

    elseif self._currentPhase == Phase.ODSikll_2 then   --角力技能准备把雷毛打飞
        if self._proxy:CheckNpcCurActionIsDone(self.monster_UUID) then
            if self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) <= 14 and 
                self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) >= 8 and 
                self.haspindaoSkill == false then
                if not self._proxy:CheckNpcOnAir(self._localNpc) then 
                    self.haspindaoSkill = true
                    --self._proxy:SetNpcFaceToNpc(self.monster_UUID,self._localNpc)   --这个转向功能容易让怪物转不过去，卡着一直转
                    self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005978) --带有转向帧事件的BUFF
                    self._proxy:CastActionToTarget(self.monster_UUID,8005505,self._localNpc)  --拼刀技能
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,3)
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,3)
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localNpc,3)
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,3)
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,3)
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,3)
                    self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,3)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,false) 
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,false) 
                    self._timer:Schedule(0.35, self, function()              --连携拼刀表演手K版
                        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcNanami,IsActivated=false})
                        self._proxy:ApplyMagic(self._localNpc,self._localNpc,10512106)
                    end)
                
                    self._timer:Schedule(0.85, self, function()                  --发生帧在0.8~0.9之间
                        self._proxy:AbortAction(self._localNpc,true)
                        self._proxy:TeleportResetNpcOnGround(self._localNpc)                  --贴地
                        self._proxy:CastSkillActionToNpcNotCheck(self._localNpc,1051011,self.monster_UUID,0,0)        --1技能
                    end)

                    self._timer:Schedule(1.62, self, function()                    --拼刀瞬间传送  1.58太早了 1.62还行
                        self.playerPDPos = self._proxy:GetNpcPosition(self._localNpc)
                        self.monsterPDPos = self._proxy:GetNpcPosition(self.monster_UUID)
                        self.PDMidPos = {x=(self.playerPDPos.x+self.monsterPDPos.x)/2,y=1.87,z=(self.playerPDPos.z+self.monsterPDPos.z)/2}   --拼刀中点
                        self.playerPDPos2 = {x = self._spawnPoint[2].x-self.PDMidPos.x+self.playerPDPos.x,y=1.87,z = self._spawnPoint[2].z-self.PDMidPos.z+self.playerPDPos.z }
                        self.monsterPDPos2 = {x = self._spawnPoint[2].x-self.PDMidPos.x+self.monsterPDPos.x,y=1.87,z = self._spawnPoint[2].z-self.PDMidPos.z+self.monsterPDPos.z }
                        self._proxy:SetNpcPosition(self._localNpc,{x=self.playerPDPos2.x,y=1.87,z=self.playerPDPos2.z},false) --传送玩家
                        self._proxy:TeleportResetNpcOnGround(self._localNpc)                  --贴地
                        self._proxy:SetNpcPosition(self.monster_UUID,{x=self.monsterPDPos2.x,y=1.87,z=self.monsterPDPos2.z},false) --传送白龙
                        self._proxy:AbortAction(self._localNpc,true)
                    end)
                    self._timer:Schedule(1.64, self, function()
                        self._proxy:AbortAction(self.monster_UUID,true)--打断白龙动作
                        self._proxy:CastMultiParry(self.monster_UUID, self._localNpc, 800501) --强制两人拼刀
                        self._proxy:RemoveBuff(self.monster_UUID,8005906)                   --移除怪物的霸体
                        self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005907)                   --移除怪物的霸体
                    end)
                    self._timer:Schedule(2.7, self, function()
                        self._proxy:SetNpcPosition(self.NpcNanami,{x=self._proxy:GetNpcPosition(self._localNpc).x,y=5,z=self._proxy:GetNpcPosition(self._localNpc).z}) --传送nanami
                        self._proxy:TeleportResetNpcOnGround(self.NpcNanami)
                        self._proxy:AddThreat(self.NpcNanami,self.monster_UUID,100,1000)
                        self._proxy:AbortAction(self.NpcNanami,true)
                        self._proxy:CastSkillActionToNpcNotCheck(self.NpcNanami,106219,self.monster_UUID)   --七实登龙
                        self._proxy:ShowDlcGuide(90005111,EFightUiType.Commentary)--七实登场
                        self._audioPlayer:PlayNpcCV(self.NpcNanami,1052,25,EAudioLuaFuncSyncType.All)
        
                    end)
                    self._timer:Schedule(5, self, function()
                        self._proxy:SetNpcPosition(self.NpcLiv,{x=(self._proxy:GetNpcPosition(self._localNpc).x+self._proxy:GetNpcPosition(self.NpcNanami).x)/2,y=5,z=(self._proxy:GetNpcPosition(self._localNpc).z+self._proxy:GetNpcPosition(self.NpcNanami).z)/2}) --传送lIV
                        self._proxy:TeleportResetNpcOnGround(self.NpcLiv)
                        self._proxy:AddThreat(self.NpcLiv,self.monster_UUID,100,1000)
                        self._proxy:AbortAction(self.NpcLiv,true)
                        self._proxy:ShowDlcGuide(90005112,EFightUiType.Commentary)--丽芙登场
                
                        self._audioPlayer:PlayNpcCV(self.NpcLiv,1053,25,EAudioLuaFuncSyncType.All)
                    end)
                    self._timer:Schedule(5.5, self, function()      --开启UI，开启NPCai
                        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcNanami,IsActivated=true})
                        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcLiv,IsActivated=true})
                        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localNpc,1) 
                        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localNpc,1) 
                        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localNpc,1) 
                        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localNpc,1) 
                        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localNpc,1) 
                        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localNpc,1) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,true) 
                        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,true) 
                        self._proxy:RemoveBuff(self._localNpc,10512106)
                    end)
                    self._timer:Schedule(10, self, function()
                        self._proxy:ShowDlcGuide(90005124,EFightUiType.Commentary)--"太好了是七实和丽芙"
                        self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001014)
                    end)
                    self._timer:Schedule(15, self, function()
                        self:SetPhase(Phase.ODSikll_3)
                    end)
                end
            elseif self._proxy:GetNpcDistance(self._localNpc,self.monster_UUID,true) < 8 then
                self._proxy:CastActionToTarget(self.monster_UUID,8005015,self._localNpc)          --后跳一下
            end
        end

    elseif self._currentPhase == Phase.ODSikll_3 then
        if self._proxy:CheckNpcCurrentAction(self.monster_UUID,8005301) and self.ODfire == false then
            self.ODfire = true
            self._proxy:ShowDlcGuide(90005123,EFightUiType.Commentary)--改变进攻模式！
            self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001011)
            self._timer:Schedule(4, self, function()
                    self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcLiv,IsActivated=false})
                    self._proxy:AbortAction(self.NpcLiv,true)
                    self._proxy:SetNpcFocusTarget(self._localNpc,self.NpcLiv)
                    self._proxy:CastSkillActionToNpcNotCheck(self.NpcLiv,106341,self.NpcLiv)  --丽芙罩子
                    self._proxy:ShowDlcGuide(90005114,EFightUiType.Commentary)--丽芙登场
                    self._audioPlayer:PlayNpcCV(self.NpcLiv,1053,18,EAudioLuaFuncSyncType.All)
            end)
            self._timer:Schedule(5.5, self, function()
                self._proxy:RemoveNpcFocusTarget(self._localNpc)
            end)
        end
        if not self._proxy:CheckNpcCurrentAction(self.monster_UUID,8005301) and self.ODfire == true and self.finishFire == false then 
            self:SetPhase(Phase.ODSikll_4)
            self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcLiv,IsActivated=true})
            self.finishFire = true
        end

    elseif self._currentPhase == Phase.ODSikll_4 then
        if self._proxy:CheckNpcCurrentAction(self.monster_UUID,8005331) then  --break了！
            
            self:SetPhase(Phase.Break_1)
        end

    elseif self._currentPhase == Phase.Break_1 then
        
        if self._proxy:CheckNpc(self.monster_UUID) == true or self._proxy:CheckActorExist(self.monster_UUID) == true then
            if self._proxy:CheckBuffByKind(self.monster_UUID,1000446) then
                self._proxy:RemoveBuff(self.monster_UUID,1000446) --锁血不死移除
            end
            if self._proxy:CheckNpcCurrentAction(self.monster_UUID,8005301) and self.hasODfire_PhaseBreak == false then
                self.hasODfire_PhaseBreak = true
                self._proxy:ShowDlcGuide(90005113,EFightUiType.Commentary)   --能量聚集
                self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001011)
                self._timer:Schedule(5, self, function()
                        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcLiv,IsActivated=false})
                        self._proxy:AbortAction(self.NpcLiv,true)
                        self._proxy:SetNpcFocusTarget(self._localNpc,self.NpcLiv)
                        self._proxy:CastSkillActionToNpcNotCheck(self.NpcLiv,106341,self.NpcLiv)  --丽芙罩子
                        self._proxy:ShowDlcGuide(90005114,EFightUiType.Commentary)
                        self._audioPlayer:PlayNpcCV(self.NpcLiv,1053,18,EAudioLuaFuncSyncType.All)
                end)
                self._timer:Schedule(5.5, self, function()
                    self._proxy:RemoveNpcFocusTarget(self._localNpc)
                end)
                self._timer:Schedule(20, self, function()
                    self.hasODfire_PhaseBreak = false 
                end)
            end
            if self._proxy:CheckNpcCurrentAction(self._localNpc,1051091) and self.hasTeamSkill == false then
                self.hasTeamSkill = true
                self._proxy:AddNpcAttribAdditive(self.monster_UUID,ENpcAttrib.DmgAmplification,5000,0)    --把boss易伤挂上
                self._timer:Schedule(1, self, function()        
                    self._proxy:AbortAction(self.NpcNanami,true)
                    self._proxy:CastSkillActionToNpcNotCheck(self.NpcNanami,106222,self.monster_UUID)       --70大招
                end)
                self._timer:Schedule(2, self, function()   
                    self._proxy:AbortAction(self.NpcLiv,true)            
                    self._proxy:CastSkillActionToNpcNotCheck(self.NpcLiv,106350,self.monster_UUID)          --丽芙大招
                end)
                self._timer:Schedule(5, self, function() 
                    self:SetPhase(Phase.Final)
                end)
                self._timer:Schedule(15, self, function() 
                    self.hasTeamSkill = false
                end)
            end
            if self._proxy:IsNpcDead(self.monster_UUID) and self.hasEnd == false then
                    self._proxy:SettleFight(true)          --后端结算通知API
                    XLog.Debug("检测到Monster死亡")
                    self._proxy:SetLevelMemoryInt(40001,100)
                    self:ControlLevelUI(UIControl.Off)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false)
                    self.hasEnd = true
                    --self._audioPlayer:PlayAudioFightWin()--胜利结算音频
                    self._timer:Schedule(5, self, function()
                        self:SetPhase(Phase.End)
                    end)   
            end
        end

    elseif self._currentPhase == Phase.Final then  --最后阶段时
        
        if self._proxy:CheckNpc(self.monster_UUID) == true or self._proxy:CheckActorExist(self.monster_UUID) == true then
            if self._proxy:CheckBuffByKind(self.monster_UUID,1000446) then
                self._proxy:RemoveBuff(self.monster_UUID,1000446) --锁血不死移除
            end
            if self._proxy:CheckNpcCurrentAction(self._localNpc,1051091) and self.hasTeamSkill == false then
                self.hasTeamSkill = true
                self._timer:Schedule(1, self, function()        
                    self._proxy:AbortAction(self.NpcNanami,true)
                    self._proxy:CastSkillActionToNpcNotCheck(self.NpcNanami,106222,self.monster_UUID)       --70大招
                end)
                self._timer:Schedule(2, self, function()   
                    self._proxy:AbortAction(self.NpcLiv,true)            
                    self._proxy:CastSkillActionToNpcNotCheck(self.NpcLiv,106350,self.monster_UUID)          --丽芙大招
                end)
                self._timer:Schedule(15, self, function() 
                    self.hasTeamSkill = false
                end)
            end
            if self._proxy:CheckNpcCurrentAction(self.monster_UUID,8005301) and self.hasODfire_PhaseFinal == false then
                self.hasODfire_PhaseFinal = true
                self._proxy:ShowDlcGuide(90005113,EFightUiType.Commentary)--丽芙罩子
                self._timer:Schedule(4, self, function()
                        self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.NpcLiv,IsActivated=false})
                        self._proxy:AbortAction(self.NpcLiv,true)
                        self._proxy:SetNpcFocusTarget(self._localNpc,self.NpcLiv)
                        self._proxy:CastSkillActionToNpcNotCheck(self.NpcLiv,106341,self.NpcLiv)  --丽芙罩子
                        self._proxy:ShowDlcGuide(90005114,EFightUiType.Commentary)--丽芙身后
                        self._audioPlayer:PlayNpcCV(self.NpcLiv,1053,18,EAudioLuaFuncSyncType.All)
                end)
                self._timer:Schedule(5.5, self, function()
                    self._proxy:RemoveNpcFocusTarget(self._localNpc)
                end)
                self._timer:Schedule(20, self, function()
                    self.hasODfire_PhaseFinal = false 
                end)
            end
            if self._proxy:IsNpcDead(self.monster_UUID) and self.hasEnd == false then
                    self._proxy:SettleFight(true)          --后端结算通知API
                    XLog.Debug("检测到Monster死亡")
                    self._proxy:SetLevelMemoryInt(40001,100)
                    self:ControlLevelUI(UIControl.Off)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localNpc,false)
                    self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.t,self._localNpc,1)
                    self._proxy:ShowDlcGuide(90005127,EFightUiType.Commentary)
                    self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001017)
                    self.hasEnd = true
                    self._backGrounSoundUid = self._proxy:PlaySound(7115)--胜利结算
                    self._timer:Schedule(7, self, function()
                        self:SetPhase(Phase.End)
                    end)   
            end
        end
    elseif self._currentPhase == Phase.Test then 
        self:SetPhase(Phase.ODSikll)
    end
end
function XLevelScript9001:OnExitPhase(phase)
    --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段

end
function XLevelScript9001:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end
function XLevelScript9001:HandlePhaseEvent(eventType, eventArgs)
    --处理阶段相关的事件响应，一般在这里跳转关卡阶段

end
function XLevelScript9001:CheckFightEnd()
   
end
---@param eventType number
---@param eventArgs userdata
function XLevelScript9001:HandleEvent(eventType, eventArgs) --事件响应逻辑
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    self._audioPlayer:HandleEvent(eventType,eventArgs)--音频播放事件监听
    if eventType == EWorldEvent.RelinkGuideFinish then           --引导完成事件
        if eventArgs.GuideId == 90005104 then                             --强制闪避
            if self._guideFinishEventFlag.guide104 then 
                self._proxy:AbortAction(self._localNpc,true)
                self._proxy:TeleportResetNpcOnGround(self._localNpc) 
                self._proxy:CastAction(self._localNpc,1051007)                        --闪避
                self._proxy:SetFightResultCustomData(self._localNpc,900051041,1)     
                self._guideFinishEventFlag.guide104 = false 
                self._timer:Schedule(1.5, self, function()  
                    self.timetoDodgeVideo = true                                                                                                                     --完成引导提示
                end)
            end    
        elseif eventArgs.GuideId == 90005105 then                        -- 技能
            if self._guideFinishEventFlag.guide105 then 
                self._proxy:AbortAction(self._localNpc,true)
                self._proxy:TeleportResetNpcOnGround(self._localNpc) 
                self._proxy:CastSkillActionToNpcNotCheck(self._localNpc,1051020,self.monster_UUID)        --2技能
                self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localNpc,true)
                self._timer:Schedule(0.2, self, function()
                    self._proxy:ShowDlcGuide(90005121,EFightUiType.Commentary)--"技能强大但是冷却"
                    self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001006)
                end)
                self._timer:Schedule(2, self, function()
                    self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true})                  --打开白龙AI
                end)
                self._timer:Schedule(10, self, function()  
                    self.finishSkillGuide = true                                                                                                                        --完成引导提示
                end) 
                self._guideFinishEventFlag.guide105 = false 
            end 
        elseif eventArgs.GuideId == 90005106 then -- 韧性条提示
            if self._guideFinishEventFlag.guide106 then 
                self._timer:Schedule(1, self, function()
                    self.finishBGGuide = true
                end)
                self._guideFinishEventFlag.guide106 = false 
            end
        elseif eventArgs.GuideId == 90005116 then -- 锁定键提示
            if self._guideFinishEventFlag.guide116 then 
                self._timer:Schedule(0.9, self, function()
                    self._proxy:ShowDlcGuide(90005106,EFightUiType.Commentary)              --看韧性条
                end)

                self._proxy:SetNpcFocusTarget(self._localNpc,self.monster_UUID)
                self._proxy:SetHardLock(self._localNpc,self.monster_UUID)
                self._guideFinishEventFlag.guide116 = false 
            end 
        elseif eventArgs.GuideId == 90005107 then -- 破韧QTE 
            if self._guideFinishEventFlag.guide107 then 
                self._proxy:AbortAction(self._localNpc,true)
                self._proxy:TeleportResetNpcOnGround(self._localNpc) 
                self._proxy:CastSkillActionToNpcNotCheck(self._localNpc,1051092,self.monster_UUID)        --破韧技能
                self._guideFinishEventFlag.guide107 = false 
            end
        elseif eventArgs.GuideId == 90005109 then -- 强制拼刀
            if self._guideFinishEventFlag.guide109 then 
                self._proxy:AbortAction(self._localNpc,true)  --打断技能
                self._proxy:TeleportResetNpcOnGround(self._localNpc) 
                self._proxy:SetSoftLockToPart(self._localNpc,self.monster_UUID,8005104)         --软锁一下右手
                self._proxy:CastSkillActionToNpcNotCheck(self._localNpc,1051011,self.monster_UUID,0,0)        --1技能
                self._proxy:ApplyMagic(self.monster_UUID,self.monster_UUID,8005963,1)           --白龙AI会放拼刀技能
                self._proxy:SetLevelMemoryInt(40001, 9)
                self._proxy:DispatchLuaEvent(ELuaEventTarget.Npc,EFightLuaEvent.RelinkSetAIActivate, {NpcUUid=self.monster_UUID,IsActivated=true}) --打开白龙AI
                self._guideFinishEventFlag.guide109 = false 
                self._timer:Schedule(0.2, self, function()
                    self._proxy:ShowDlcGuide(90005122,EFightUiType.Commentary)--"时机刚刚好"
                    self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001009)
                end)
            end                 
        elseif eventArgs.GuideId == 90005115 then -- 芝士OD
            self._proxy:SetLevelMemoryInt(40001, 7)
            self._timer:Schedule(1, self, function()    
                self._proxy:ShowDlcGuide(90005315,EFightUiType.ImageVideo)  --OD图文
            end)
        elseif eventArgs.GuideId == 90005316 then 
            self._timer:Schedule(0.2, self, function()    
                self._proxy:ShowDlcGuide(90005126,EFightUiType.Commentary)--"充能完毕！" 
                self._proxy:ApplyMagic(self._localNpc,self._localNpc,9001016)
            end)
        end
    elseif eventType == EWorldEvent.NpcDodge then
        if eventArgs.Type == 1 and self._currentPhase == Phase.Dodge_2 and self.PdodgeCD then               --极限闪避的时候
            self.PdodgeCD = false
            self._nowDodgeTimes = self._nowDodgeTimes + 1                               --闪避次数++                
            self._proxy:SetLevelMemoryInt(40002,self._nowDodgeTimes)
            self._timer:Schedule(0.6, self, function()
                    self.PdodgeCD = true 
            end)
        end
    end
end
function XLevelScript9001:HandleLuaEvent(eventType, eventArgs) --lua自定义事件响应逻辑 
    if eventType == EFightLuaEvent.RelinkCounterSuccess and self.CounterCD then --弹刀成功？
    XLog.Debug("弹刀成功")
        if self._currentPhase == Phase.SuperSkill   then
            self.CounterCD = false
            self._nowCrushTimes = self._nowCrushTimes + 1                               --弹刀次数++
            self._proxy:SetLevelMemoryInt(40004,self._nowCrushTimes)
            self._timer:Schedule(0.6, self, function()
                self.CounterCD = true 
            end)
        end
    end
end
function XLevelScript9001:CheckAllPlayerDead() --检查是否所有玩家都死亡了
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


function XLevelScript9001:LevelEnd(isPlayerWin)
--延时结算流程
    
end

function XLevelScript9001:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript9001