---relink 白龙普通关
local XLevelScript9001 = XDlcScriptManager.RegLevelPresentScript(9001, "XLevelPresentScript9001")
local Timer = require("Level/Common/XTaskScheduler")

-- 脚本构造函数
---@param proxy XDlcCSharpFuncs
function XLevelScript9001:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
    
end

-- 初始化du
function XLevelScript9001:Init()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._localPlayerNpc = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npc
    self._needDodgeTimes = 0    --教学需要完美闪避次数
    self._nowDodgeTimes  = 0    --当前闪避次数
    self._needCrushTimes = 0    --教学需要拼刀次数
    self._nowCrushTimes = 0     --当前拼刀次数
    
end

-- 事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript9001:HandleEvent(eventType, eventArgs)
    
end
local UIControl = {
    On = 100,                               --全开
    Off = 10                                --全关
}

function XLevelScript9001:ControlLevelUI(SwitchType)    --关卡内，控制UI的方法
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
        self._proxy:SetLevelUiState(EFightUiType.RelinkControl,self._localPlayerNpc,1)     --显示DLC额外面板
        self._proxy:SetLevelUiState(EFightUiType.RelinkChat,self._localPlayerNpc,1)    --显示聊天记录
        self._proxy:SetLevelUiState(EFightUiType.RelinkRoulette,self._localPlayerNpc,1)    --显示聊天轮盘
    end
end
-- 每帧执行
---@param dt number @ delta time
function XLevelScript9001:Update(dt)
    self._timer:Update(dt)
    if self._proxy:CheckLevelMemoryInt(40001) then 
        self.haruCore = self._proxy:GetLevelMemoryInt(40001)
        
        if self.haruCore == 1  then 
            
        elseif self.haruCore == 2 then                                                          --走到白龙附近           
            self.needt = self._proxy:GetLevelMemoryInt(40001)         
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务
            self._proxy:ShowStageInfo(90005201,90005200,1,false,{},{})
        elseif self.haruCore == 21 then                          
            self._proxy:ShowStageInfo(90005201,90005200,1,true,{},{})
            self._timer:Schedule(2, self, function()                --2秒关闭引导 
                    self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    --显示任务
            end)   
            self._proxy:SetLevelMemoryInt(40001,999) 
        elseif self.haruCore == 6 then 
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务  
            self._nowDodgeTimes = self._proxy:GetLevelMemoryInt(40002)    --教学需要完美闪避次数
            self._needDodgeTimes  = self._proxy:GetLevelMemoryInt(40003)    --当前闪避次数                        
            self._proxy:ShowStageInfo(90005202,90005203,1,false,{self._needDodgeTimes},{self._nowDodgeTimes,self._needDodgeTimes})
        elseif self.haruCore == 61 then 
            self._nowDodgeTimes = self._proxy:GetLevelMemoryInt(40002)    --教学需要完美闪避次数
            self._needDodgeTimes  = self._proxy:GetLevelMemoryInt(40003)    --当前闪避次数     
            self._proxy:ShowStageInfo(90005202,90005203,1,true,{self._needDodgeTimes},{self._nowDodgeTimes,self._needDodgeTimes})
            self._timer:Schedule(2, self, function()                --2秒关闭引导 
                self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    
            end)  
            self._proxy:SetLevelMemoryInt(40001,999) 
        elseif self.haruCore == 7  then        --OD 
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务         
            self._proxy:ShowStageInfo(90005207,90005200,1,false,{},{})
        elseif self.haruCore == 71  then        --OD打满 
            self._proxy:ShowStageInfo(90005207,90005200,1,true,{},{}) 
            self._timer:Schedule(2, self, function()                --2秒关闭引导 
                self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    --显示任务
            end) 
            self._proxy:SetLevelMemoryInt(40001,999)
        elseif self.haruCore == 8 then
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务
            self._proxy:ShowStageInfo(90005205,90005200,1,false,{},{})
        elseif self.haruCore == 81  then        --韧性打满 
            self._proxy:ShowStageInfo(90005205,90005200,1,true,{},{}) 
            self._timer:Schedule(2, self, function()                --2秒关闭引导 
                self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    --显示任务
            end) 
            self._proxy:SetLevelMemoryInt(40001,999)
        elseif self.haruCore == 9 then
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务
            self._nowCrushTimes = self._proxy:GetLevelMemoryInt(40004)    --当前拼刀次数
            self._needCrushTimes = self._proxy:GetLevelMemoryInt(40005)     --教学需要拼刀次数
            self._proxy:ShowStageInfo(90005204,90005203,1,false,{self._needCrushTimes},{self._nowCrushTimes,self._needCrushTimes})
        elseif self.haruCore == 91 then
            self._nowCrushTimes = self._proxy:GetLevelMemoryInt(40004)    --当前拼刀次数
            self._needCrushTimes = self._proxy:GetLevelMemoryInt(40005)     --教学需要拼刀次数
            self._proxy:ShowStageInfo(90005204,90005203,1,true,{self._needCrushTimes},{self._nowCrushTimes,self._needCrushTimes})
            self._timer:Schedule(2, self, function()                --2秒关闭引导 
                self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    
            end) 
            self._proxy:SetLevelMemoryInt(40001,999) 
        elseif self.haruCore == 10 then
            self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,1)    --显示任务
            self._proxy:ShowStageInfo(90005208,90005200,1,false,{},{})
        elseif self.haruCore == 100 then
            self._proxy:ShowStageInfo(90005208,90005200,1,true,{},{})
            self._timer:Schedule(2, self, function()                --2秒关闭引导 
                self._proxy:SetLevelUiState(EFightUiType.RelinkTips,self._localPlayerNpc,3)    
            end) 
            self._proxy:SetLevelMemoryInt(40001,999)
        end
    end
end


-- 脚本终止
function XLevelScript9001:Terminate()

end

return XLevelScript9001
