--relink 木桩关
local XLevelScript9012 = XDlcScriptManager.RegLevelPresentScript(9012, "XLevelPresentScript9012")
local Timer = require("Level/Common/XTaskScheduler")


-- 脚本构造函数
---@param proxy XDlcCSharpFuncs
function XLevelScript9012:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
end

-- 初始化
function XLevelScript9012:Init()
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
    self._limitTimeToEnd = false
    self.LimitTime = 1770
    self.levelId = self._proxy:GetCurrentLevelId()  --当前关卡ID
    self._localPlayerID = self._proxy:GetPlayerIdByNpc(self._localPlayerNpc)
end

-- 事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript9012:HandleEvent(eventType, eventArgs)
end

-- 每帧执行
---@param dt number @ delta time
function XLevelScript9012:Update(dt)
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt
    if self._proxy:CheckLevelMemoryInt(40001) then 
        self.haruCore = self._proxy:GetLevelMemoryInt(40001)
        if self.haruCore == 1 then  --伤害显示UI
            -- self.damage = self._proxy:GetLevelMemoryInt(40002)
            -- self.resetDamageTime = self._proxy:GetLevelMemoryInt(40003)
            --self._proxy:ShowStageInfo(9012001,90005200,1,false,{self.damage},{})
            --self._proxy:ShowStageInfo(9012002,90005200,2,false,{self.resetDamageTime},{}) 
        elseif self.haruCore == 200 and self._limitTimeToEnd == false then 
            self._limitTimeToEnd = true
        end
        if self._limitTimeToEnd == true then 
            if self._proxy:CheckLevelMemoryInt(60001) then
                self.mainLevelTime = self._proxy:GetLevelMemoryInt(60001)
                self.timeToEnd = self.LimitTime - self.mainLevelTime 
                if self.timeToEnd <= 1 then
                    self._proxy:CloseTip(90202)
                    XLog.Debug("关闭倒计时")
                elseif self.timeToEnd >= 2 then 
                    self._proxy:ShowTip(90202, math.floor(self.timeToEnd)-1 )
                end
            end
        end
    end
end


-- 脚本终止
function XLevelScript9012:Terminate()

end

return XLevelScript9012
