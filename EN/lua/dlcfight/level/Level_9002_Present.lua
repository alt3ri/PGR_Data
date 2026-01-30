---relink 白龙普通关
local XLevelScript9002 = XDlcScriptManager.RegLevelPresentScript(9002, "XLevelPresentScript9002")
local Timer = require("Level/Common/XTaskScheduler")
local EFightCVAction = require("Enum/XFightCVAction")            --CV播放插件

-- 脚本构造函数
---@param proxy XDlcCSharpFuncs
function XLevelScript9002:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
end

-- 初始化
function XLevelScript9002:Init()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)                 --事件注册：触发区碰撞
    self._localPlayerNpc = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npc
    self._spawnPoint = {} 
    self._ShowPhaseUiOff = false
    self._levelTime = 0
    self._ShowPhaseUiOn = false
    self._initLosedStartPhase = false
    self._initLosedDelayPhase = false
    self._initLosedDialogPhase = false
    self._WinStartPhaseUiOff = false
    self._initWinMisslePhase = false
    self._initWinDelayPhase = false
    self._initWinDialogPhase = false
    self._initEndPhase = false
    self._limitTimeToEnd = false
    self.LimitTime = 1170
    self._deathZoneId = 1        -- 1为死区的PlacedID
    self.levelId = self._proxy:GetCurrentLevelId()  --当前关卡ID
    self._localPlayerID = self._proxy:GetPlayerIdByNpc(self._localPlayerNpc)
    for i = 1, 5 do
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点，1为BOSS出生点，2为场地中心，3~5是玩家出生点
    end
end

-- 事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript9002:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.HostSceneObjectPlaceId == self._deathZoneId and eventArgs.TriggerState == 1 then 
            if eventArgs.EnteredActorUUID == self._proxy:GetLocalPlayerNpcId() then   ----是本端玩家就会重置并提示
                self._proxy:SetNpcPosition(eventArgs.EnteredActorUUID,self._spawnPoint[2],false)
                self._proxy:ShowTip(90204)
            end
        end
    elseif eventType == EWorldEvent.NpcAddBuff then 
        if eventArgs.BuffTableId == 1000512 then
            self._proxy:ShowStageInfo(90005211,90005212,1,false,{},{0, 1})
        elseif eventArgs.BuffTableId == 1000513 then
            self._proxy:ShowStageInfo(90005211,90005212,1,true,{},{1, 1})
        end
    end
    
end

local UIControl = {
    On = 100,                               --全开
    Off = 10                                --全关
}

function XLevelScript9002:ControlLevelUI(SwitchType)    --关卡内，控制UI的方法
    if SwitchType == UIControl.Off then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localPlayerNpc,3)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localPlayerNpc,3)         --隐藏右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localPlayerNpc,3)              --隐藏目标面板
        --self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localPlayerNpc,3)          --隐藏关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localPlayerNpc,3)          --隐藏锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localPlayerNpc,3)                --隐藏从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localPlayerNpc,3)          --隐藏能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localPlayerNpc,3)            --隐藏队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localPlayerNpc,3)            --隐藏玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localPlayerNpc,3)     --隐藏DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localPlayerNpc,3)    --隐藏聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localPlayerNpc,3)    --隐藏聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeammateIndicator,self._localPlayerNpc,3)    --隐藏队友信息
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    --隐藏任务
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localPlayerNpc,false)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localPlayerNpc,false)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localPlayerNpc,3)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localPlayerNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localPlayerNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localPlayerNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localPlayerNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localPlayerNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localPlayerNpc,3) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localPlayerNpc,3) 


    elseif SwitchType == UIControl.On then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localPlayerNpc,1)            --显示摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localPlayerNpc,1)         --显示右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localPlayerNpc,1)              --显示目标面板
        --self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localPlayerNpc,1)          --隐藏关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localPlayerNpc,1)          --显示锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localPlayerNpc,1)                --显示从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localPlayerNpc,1)          --显示能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localPlayerNpc,1)            --显示队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localPlayerNpc,1)            --显示玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localPlayerNpc,1)     --显示DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localPlayerNpc,1)    --显示聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localPlayerNpc,1)    --显示聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeammateIndicator,self._localPlayerNpc,1)    --显示队友信息
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localPlayerNpc,true)
        self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localPlayerNpc,true)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localPlayerNpc,1)
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localPlayerNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localPlayerNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localPlayerNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localPlayerNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localPlayerNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localPlayerNpc,1) 
        self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localPlayerNpc,1)
    end
end
-- 每帧执行
---@param dt number @ delta time
function XLevelScript9002:Update(dt)
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt
    if self._proxy:CheckLevelMemoryInt(40001) then 
        self.haruCore = self._proxy:GetLevelMemoryInt(40001)
        if self.haruCore == 1 and self._ShowPhaseUiOff == false then 
            self:ControlLevelUI(UIControl.Off)
            self._proxy:DispatchLuaEvent(2,EFightLuaEvent.RelinkAIBorn,{NpcUUid = self._proxy:GetLevelMemoryInt(50001)})    --通知BOSS播出场动画
            self._timer:Schedule(5.4, self, function()
                self._proxy:PlayStayScreenEffectById(902999)
            end)
            self._backGrounSoundUid = self._proxy:PlaySound(6515,ETargetActorType.Npc,self._localPlayerNpc)                 --环境音
            self._ShowPhaseUiOff = true                                                               --防止重复执行
        elseif self.haruCore == 2 and self._ShowPhaseUiOn == false then                         --正式开打
            XLog.Debug("正式开打UI恢复")
            self._proxy:KillStayScreenEffectById(902999)
            self._timer:Schedule(0.9, self, function()
                self:ControlLevelUI(UIControl.On)    --UI全开
            end)              
            self._ShowPhaseUiOn = true   
        elseif self.haruCore == 7 and self._WinStartPhaseUiOff == false then                         --要掉落了
            self:ControlLevelUI(UIControl.Off)
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务
            self._proxy:PlaySound(7115)--胜利结算
            self._timer:Schedule(1, self, function()
                self._proxy:PlayNpcCV(self._localPlayerNpc,0,EFightCVAction.NotifyEnemyDead,EAudioLuaFuncSyncType.NpcController)       --播放角色自己的胜利语音
            end)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localPlayerNpc,true)
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localPlayerNpc,1)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localPlayerNpc,true)
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Jump,self._localPlayerNpc,1)
            self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localPlayerNpc,1)  
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.RelinkLimitSkill,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localPlayerNpc,false)          --只显示摇杆和跳跃，屏蔽其他
            self._proxy:StopAudioByUid(self._backGrounSoundUid)--停止环境音
            self._WinStartPhaseUiOff = true
        elseif self.haruCore == 100 and self._initLosedStartPhase == false then 
            XLog.Debug("检测到所有玩家死亡,关闭所有UI")
            self:ControlLevelUI(UIControl.Off)
            self._proxy:SetLevelUiState(EFightUiType.CommonReborn,self._localPlayerNpc,3)
            self._proxy:CloseTip(90203)
            self._initLosedStartPhase = true
            self._proxy:StopAudioByUid(self._backGrounSoundUid)--停止环境音
        elseif self.haruCore == 200 and self._limitTimeToEnd == false then 
            self._limitTimeToEnd = true
        end
        if self._limitTimeToEnd == true then 
            if self._proxy:CheckLevelMemoryInt(60001) then
                self.mainLevelTime = self._proxy:GetLevelMemoryInt(60001)
                self.timeToEnd = self.LimitTime - self.mainLevelTime 
                if self.timeToEnd <= 1 then
                    self._proxy:CloseTip(90202)
                elseif self.timeToEnd >= 2 then 
                    self._proxy:ShowTip(90202, math.floor(self.timeToEnd)-1 )
                end
            end
        end
    end
end

-- 脚本终止
function XLevelScript9002:Terminate()

end

return XLevelScript9002
