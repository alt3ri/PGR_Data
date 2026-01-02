---relink 白龙普通关
local XLevelScript9007 = XDlcScriptManager.RegLevelPresentScript(9007, "XLevelPresentScript9007")
local Timer = require("Level/Common/XTaskScheduler")

-- 脚本构造函数
---@param proxy XDlcCSharpFuncs
function XLevelScript9007:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
end

-- 初始化
function XLevelScript9007:Init()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._localPlayerNpc = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npc
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
    self.LimitTime = 1800   --限时1800秒
    
    self._localPlayerID = self._proxy:GetPlayerIdByNpc(self._localPlayerNpc)
end

-- 事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript9007:HandleEvent(eventType, eventArgs)
    
end
local UIControl = {
    On = 100,                               --全开
    Off = 10                                --全关
}

function XLevelScript9007:ControlLevelUI(SwitchType)    --关卡内，控制UI的方法
    if SwitchType == UIControl.Off then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localPlayerNpc,3)            --隐藏摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localPlayerNpc,3)         --隐藏右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localPlayerNpc,3)              --隐藏目标面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTip,self._localPlayerNpc,3)          --隐藏关卡面板
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localPlayerNpc,3)          --隐藏锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localPlayerNpc,3)                --隐藏从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localPlayerNpc,3)          --隐藏能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localPlayerNpc,3)            --隐藏队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localPlayerNpc,3)            --隐藏玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localPlayerNpc,3)     --隐藏DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localPlayerNpc,3)    --隐藏聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localPlayerNpc,3)    --隐藏聊天轮盘
        self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    --隐藏任务
    elseif SwitchType == UIControl.On then
        self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localPlayerNpc,1)            --显示摇杆
        self._proxy:SetLevelUiState(EFightUiType.CommonControl,self._localPlayerNpc,1)         --显示右侧面板
        self._proxy:SetLevelUiState(EFightUiType.CommonTargetInfo,self._localPlayerNpc,1)              --显示目标面板
        self._proxy:SetLevelUiState(EFightUiType.CommonLockTarget,self._localPlayerNpc,1)          --显示锁定面板
        self._proxy:SetLevelUiState(EFightUiType.CommonMenu,self._localPlayerNpc,1)                --显示从菜单面板
        self._proxy:SetLevelUiState(EFightUiType.CommonEnergy,self._localPlayerNpc,1)          --显示能量条面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkTeamInfo,self._localPlayerNpc,1)            --显示队伍信息面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkGameplay,self._localPlayerNpc,1)            --显示玩法面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localPlayerNpc,1)     --显示DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localPlayerNpc,1)    --显示聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localPlayerNpc,1)    --显示聊天轮盘
    end
end
-- 每帧执行
---@param dt number @ delta time
function XLevelScript9007:Update(dt)
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt
    if self._proxy:CheckLevelMemoryInt(40001) then 
        self.haruCore = self._proxy:GetLevelMemoryInt(40001)
        if self.haruCore == 1 and self._ShowPhaseUiOff == false then 
            self:ControlLevelUI(UIControl.Off)
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
            self._proxy:DispatchLuaEvent(2,EFightLuaEvent.RelinkAIBorn,{NpcUUid = self._proxy:GetLevelMemoryInt(50001)})    --通知BOSS播出场动画
            XLog.Debug("BOSS在出场动作过程中先关掉UI")
            self._ShowPhaseUiOff = true                                                               --防止重复执行
        elseif self.haruCore == 2 and self._ShowPhaseUiOn == false then                         --正式开打
            XLog.Debug("正式开打UI恢复")
            self:ControlLevelUI(UIControl.On)                                                       --UI全开
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Move,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localPlayerNpc,true)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localPlayerNpc,true)
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonJoystick,ENpcOperationKey.Move,self._localPlayerNpc,1)
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localPlayerNpc,1) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localPlayerNpc,1) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localPlayerNpc,1) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localPlayerNpc,1) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localPlayerNpc,1) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localPlayerNpc,1) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localPlayerNpc,1) 
            self._ShowPhaseUiOn = true   
        
        elseif self.haruCore == 7 and self._WinStartPhaseUiOff == false then                         --要掉落了
            self:ControlLevelUI(UIControl.Off)
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
            self._proxy:SetLevelUiState(EFightUiType.CommonJoystick,self._localPlayerNpc,1)            --只显示摇杆，屏蔽其他
            self._WinStartPhaseUiOff = true
        elseif self.haruCore == 100 and self._initLosedStartPhase == false then 
            XLog.Debug("检测到所有玩家死亡,关闭所有UI")
            self:ControlLevelUI(UIControl.Off)
            self._proxy:SetLevelUiState(EFightUiType.CommonReborn,self._localPlayerNpc,3)            --隐藏摇杆
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Attack,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Dodge,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball1,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball2,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Ball3,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Focus,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.Jump,self._localPlayerNpc,false)
            self._proxy:SetLevelButtonOpEnabled(ENpcOperationKey.ExSkill,self._localPlayerNpc,false)
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Dodge,self._localPlayerNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Focus,self._localPlayerNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.ExSkill,self._localPlayerNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball1,self._localPlayerNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball2,self._localPlayerNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Ball3,self._localPlayerNpc,3) 
            self._proxy:SetLevelOperationUiState(EFightUiType.CommonControl,ENpcOperationKey.Attack,self._localPlayerNpc,3)
            self._proxy:CloseTip(90203)
            self._initLosedStartPhase = true
        end
        if self._levelTime > (self.LimitTime-10) then 
            self.timeToEnd = self.LimitTime - self._levelTime
            if self.timeToEnd >=0 then 
                self._proxy:ShowTip(90202, math.floor(self.timeToEnd) )
            elseif self.timeToEnd <  0 then
                self._proxy:CloseTip(90202)
            end
        end
    end
end


-- 脚本终止
function XLevelScript9007:Terminate()

end

return XLevelScript9007
